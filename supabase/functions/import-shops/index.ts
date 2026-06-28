import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

// 要搜尋的關鍵字（盡量涵蓋不同叫法）
const QUERIES = [
  '寶可夢卡店 香港',
  'Pokemon card shop Hong Kong',
  'trading card shop Hong Kong',
  '卡牌專門店 香港',
  'TCG card shop Hong Kong',
  '遊戲王卡店 香港',
]

// 由經緯度粗略判斷香港大區（admin 可事後微調）
function regionOf(lat: number, lng: number): string {
  if (lng < 114.05) return '離島'        // 大嶼山/長洲等（偏西）
  if (lat < 22.29) return '香港島'        // 維港以南
  if (lat < 22.34) return '九龍'          // 維港以北、界限街以南
  return '新界'                           // 其餘
}

interface Place {
  id: string
  displayName?: { text?: string }
  formattedAddress?: string
  location?: { latitude?: number; longitude?: number }
  internationalPhoneNumber?: string
  regularOpeningHours?: { weekdayDescriptions?: string[] }
}

async function searchText(key: string, query: string): Promise<Place[]> {
  const out: Place[] = []
  let pageToken: string | undefined
  for (let page = 0; page < 2; page++) {
    const body: Record<string, unknown> = {
      textQuery: query,
      languageCode: 'zh-HK',
      regionCode: 'HK',
    }
    if (pageToken) body.pageToken = pageToken
    const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location,places.internationalPhoneNumber,places.regularOpeningHours,nextPageToken',
      },
      body: JSON.stringify(body),
    })
    const json = await res.json()
    if (!res.ok) throw new Error(JSON.stringify(json))
    for (const p of (json.places ?? [])) out.push(p as Place)
    pageToken = json.nextPageToken
    if (!pageToken) break
    await new Promise((r) => setTimeout(r, 1500)) // nextPageToken 需稍等才生效
  }
  return out
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  try {
    const key = Deno.env.get('GOOGLE_PLACES_KEY')
    if (!key) {
      return new Response(JSON.stringify({ error: 'GOOGLE_PLACES_KEY not set' }), { status: 500, headers: CORS })
    }

    // 收集 + 去重（依 place id）
    const byId = new Map<string, Place>()
    for (const q of QUERIES) {
      try {
        const places = await searchText(key, q)
        for (const p of places) if (p.id) byId.set(p.id, p)
      } catch (e) {
        console.error('[import-shops] query failed', q, String(e))
      }
    }

    // 轉成 card_shops 列
    const rows = [...byId.values()]
      .filter((p) => p.location?.latitude != null && p.location?.longitude != null)
      .map((p) => {
        const lat = p.location!.latitude as number
        const lng = p.location!.longitude as number
        return {
          google_place_id: p.id,
          name: p.displayName?.text ?? '',
          address: p.formattedAddress ?? null,
          region: regionOf(lat, lng),
          lat,
          lng,
          phone: p.internationalPhoneNumber ?? null,
          hours: p.regularOpeningHours?.weekdayDescriptions?.join('\n') ?? null,
          is_active: true,
        }
      })
      .filter((r) => r.name)

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
    if (rows.length > 0) {
      const { error } = await admin.from('card_shops').upsert(rows, { onConflict: 'google_place_id' })
      if (error) throw new Error(error.message)
    }

    return new Response(JSON.stringify({ success: true, imported: rows.length }), { headers: CORS })
  } catch (e) {
    console.error('[import-shops] error', String(e))
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: CORS })
  }
})
