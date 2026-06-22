#!/usr/bin/env bash
# PokeBid - JustTCG "Pokemon Japan" full catalog harvester (bash version)
# For servers / cron. Keys come from environment variables (no secrets in file).
# Requires: curl, jq
#
# Usage:
#   export JUSTTCG_KEY=tcg_xxx
#   export SUPABASE_URL=https://xxxx.supabase.co
#   export SUPABASE_ANON_KEY=eyJ...
#   ./harvest_jp.sh
#
# Optional:
#   ONLY_SETS="m5-abyss-eye-pokemon-japan m4-..."  # space-separated; empty = all
#   SLEEP_MS=1300                                   # spacing between API calls

set -euo pipefail

: "${JUSTTCG_KEY:?set JUSTTCG_KEY}"
: "${SUPABASE_URL:?set SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY}"
GAME="pokemon-japan"
SLEEP_MS="${SLEEP_MS:-1300}"
ONLY_SETS="${ONLY_SETS:-}"
SLEEP_S=$(awk "BEGIN{print $SLEEP_MS/1000}")

jt() { curl -s -H "x-api-key: $JUSTTCG_KEY" "$1"; }
sb_headers=(-H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY")

# fetch JustTCG with retry on rate limit / error
jt_retry() {
  local url="$1" i out
  for i in 1 2 3 4 5; do
    out=$(jt "$url" || true)
    if echo "$out" | jq -e '.data or (type=="array")' >/dev/null 2>&1; then
      echo "$out"; return 0
    fi
    echo "  rate/err, wait 10s (retry $i)" >&2
    sleep 10
  done
  return 1
}

NOW_MS=$(( $(date +%s) * 1000 ))

echo "START $(date -u +%FT%TZ)"

# 1) Sets -> cached_sets
SETS_JSON=$(jt_retry "https://api.justtcg.com/v1/sets?game=$GAME")
SETS=$(echo "$SETS_JSON" | jq -c 'if .data then .data else . end')
COUNT=$(echo "$SETS" | jq 'length')
echo "Sets: $COUNT"

echo "$SETS" | jq -c --argjson now "$NOW_MS" '[ .[] | {
  id, name, series:null, series_id:null,
  release_date:(.release_date // null), symbol_image:null, logo_image:null,
  total:(.cards_count // 0), language:"ja", cached_at:$now } ]' \
  | curl -s "${sb_headers[@]}" -H "Content-Type: application/json" \
      -H "Prefer: resolution=merge-duplicates,return=minimal" \
      -X POST "$SUPABASE_URL/rest/v1/cached_sets?on_conflict=id" --data-binary @- >/dev/null || \
  echo "cached_sets upsert failed (non-fatal)"
echo "cached_sets attempted: $COUNT"

# 2) Cards per set -> cached_cards (resumable)
IDX=0
echo "$SETS" | jq -c '.[] | {id, cards_count}' | while read -r setrow; do
  IDX=$((IDX+1))
  SID=$(echo "$setrow" | jq -r '.id')
  EXPECTED=$(echo "$setrow" | jq -r '.cards_count // 0')
  [ "$EXPECTED" -le 0 ] && continue
  if [ -n "$ONLY_SETS" ] && ! echo " $ONLY_SETS " | grep -q " $SID "; then continue; fi

  # resume: skip if already have >= expected
  EXISTING=$(curl -s -D - -o /dev/null "${sb_headers[@]}" -H "Prefer: count=exact" \
    "$SUPABASE_URL/rest/v1/cached_cards?set_id=eq.$SID&select=id&limit=1" \
    | grep -i '^content-range:' | sed 's/.*\///' | tr -d '\r\n ')
  EXISTING=${EXISTING:-0}
  if [ "$EXISTING" -ge "$EXPECTED" ]; then
    echo "[$IDX/$COUNT] $SID : already $EXISTING/$EXPECTED, skip"; continue
  fi

  OFFSET=0
  WROTE=0
  while true; do
    PAGE=$(jt_retry "https://api.justtcg.com/v1/cards?game=$GAME&set=$SID&limit=20&offset=$OFFSET") || break
    N=$(echo "$PAGE" | jq '(.data // []) | length')
    [ "$N" -eq 0 ] && break

    ROWS=$(echo "$PAGE" | jq -c --arg sid "$SID" --argjson now "$NOW_MS" '
      [ .data[]
        | select(.number != null and .number != "N/A")
        | { id, name, number, set_id:$sid, set_name:.set_name, rarity:.rarity,
            image_small:(if .tcgplayerId then "https://tcgplayer-cdn.tcgplayer.com/product/\(.tcgplayerId)_in_1000x1000.jpg" else null end),
            image_large:(if .tcgplayerId then "https://tcgplayer-cdn.tcgplayer.com/product/\(.tcgplayerId)_in_1000x1000.jpg" else null end),
            supertype:null, types:"",
            variant:((.name | capture("\\((?<v>[^)]+)\\)").v) // null),
            language:"ja", estimated_price_ntd:0, cached_at:$now }
      ] | unique_by(.id)')

    RC=$(echo "$ROWS" | jq 'length')
    if [ "$RC" -gt 0 ]; then
      echo "$ROWS" | curl -s "${sb_headers[@]}" -H "Content-Type: application/json" \
        -H "Prefer: resolution=merge-duplicates,return=minimal" \
        -X POST "$SUPABASE_URL/rest/v1/cached_cards?on_conflict=id" --data-binary @- >/dev/null
      WROTE=$((WROTE+RC))
    fi

    [ "$N" -lt 20 ] && break
    OFFSET=$((OFFSET+20))
    sleep "$SLEEP_S"
  done
  echo "[$IDX/$COUNT] $SID : wrote $WROTE cards"
  sleep "$SLEEP_S"
done

echo "DONE $(date -u +%FT%TZ)"
