// SNKRDUNK 日本市場成交價代理（PSA10 / PSA9 / 生卡）+ 7日/30日價格走勢
// 用法：GET /functions/v1/snkrdunk-price?name=Umbreon ex&number=217/187
// 伺服器端呼叫 SNKRDUNK 公開 API（避開瀏覽器 CORS）

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const DAY = 86400000;

async function snkr(url: string) {
  const res = await fetch(url, { headers: { "User-Agent": UA, "Accept": "application/json" } });
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  return res;
}

// 把 SNKRDUNK 的相對/絕對日期字串轉成 epoch ms
function parseJpDate(s: string, now: number): number | null {
  s = (s ?? "").trim();
  let m;
  if ((m = s.match(/^(\d+)\s*分前/))) return now - Number(m[1]) * 60000;
  if ((m = s.match(/^(\d+)\s*時間前/))) return now - Number(m[1]) * 3600000;
  if ((m = s.match(/^(\d+)\s*日前/))) return now - Number(m[1]) * DAY;
  if ((m = s.match(/^(\d+)\s*(?:ヶ月|か月|カ月)前/))) return now - Number(m[1]) * 30 * DAY;
  if ((m = s.match(/^(\d+)\s*年前/))) return now - Number(m[1]) * 365 * DAY;
  if ((m = s.match(/^(\d{4})\/(\d{1,2})\/(\d{1,2})/))) {
    return Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  }
  return null;
}

function dayKey(ms: number): string {
  const d = new Date(ms);
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  return `${d.getUTCFullYear()}-${mm}-${dd}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const u = new URL(req.url);
    const name = u.searchParams.get("name") ?? "";
    const number = u.searchParams.get("number") ?? "";
    if (!name && !number) return json({ error: "missing name/number" }, 400);

    // 1) 搜尋 → 候選 apparel id
    const kw = encodeURIComponent(`${name} ${number}`.trim());
    const html = await (await snkr(`https://snkrdunk.com/search?keywords=${kw}`)).text();
    const ids: string[] = [];
    const re = /\/apparels\/(\d+)/g;
    let m;
    while ((m = re.exec(html)) !== null) {
      if (!ids.includes(m[1])) ids.push(m[1]);
      if (ids.length >= 8) break;
    }
    if (ids.length === 0) return json({ matched: false });

    // 2) 配對：nameEN 含編號
    let matchedId: string | null = null;
    let matchedName = "";
    for (const id of ids) {
      try {
        const p = await (await snkr(`https://snkrdunk.com/v2/products/${id}?type=apparel`)).json();
        const en: string = p.nameEN ?? "";
        if (number) {
          if (en.includes(number)) { matchedId = id; matchedName = en; break; }
        } else if (/\[[^\]]+\]/.test(en)) {
          matchedId = id; matchedName = en; break;
        }
      } catch (_) { /* skip */ }
    }
    if (!matchedId) return json({ matched: false });

    // 3) 抓成交履歷（多頁，覆蓋 ~30 天）
    const now = Date.now();
    const cutoff = now - 31 * DAY;
    const trades: any[] = [];
    for (let page = 1; page <= 4; page++) {
      const hist = await (await snkr(
        `https://snkrdunk.com/v1/apparels/${matchedId}/sales-history?size_id=0&page=${page}&per_page=100`
      )).json();
      const h: any[] = hist.history ?? [];
      if (h.length === 0) break;
      for (const t of h) t.ts = parseJpDate(t.date, now);
      trades.push(...h);
      const oldest = h[h.length - 1]?.ts ?? now;
      if (h.length < 100 || oldest < cutoff) break;
    }

    // 4) 依分級彙整 + 每日均價序列
    const group = (pred: (c: string) => boolean) => {
      const items = trades.filter((t) => pred((t.condition ?? "").toUpperCase()));
      const prices = items.map((t) => Number(t.price)).filter((n) => n > 0);
      if (prices.length === 0) return null;

      // 每日均價（最近 30 天，升冪）
      const buckets = new Map<string, { sum: number; n: number; min: number; max: number; ts: number }>();
      for (const t of items) {
        if (!t.ts || t.ts < cutoff) continue;
        const p = Number(t.price); if (!(p > 0)) continue;
        const k = dayKey(t.ts);
        const b = buckets.get(k) ?? { sum: 0, n: 0, min: p, max: p, ts: t.ts };
        b.sum += p; b.n++; b.min = Math.min(b.min, p); b.max = Math.max(b.max, p); b.ts = Math.max(b.ts, t.ts);
        buckets.set(k, b);
      }
      const daily = [...buckets.entries()]
        .map(([d, b]) => ({ d, avg: Math.round(b.sum / b.n), min: b.min, max: b.max, count: b.n, ts: b.ts }))
        .sort((a, b) => a.ts - b.ts);

      // 漲跌幅：最近 N 天均價 vs 前 N 天均價
      const winAvg = (fromDaysAgo: number, toDaysAgo: number) => {
        const lo = now - fromDaysAgo * DAY, hi = now - toDaysAgo * DAY;
        const ps = items.filter((t) => t.ts && t.ts >= lo && t.ts < hi).map((t) => Number(t.price)).filter((n) => n > 0);
        return ps.length ? ps.reduce((a, b) => a + b, 0) / ps.length : null;
      };
      const pct = (cur: number | null, prev: number | null) =>
        (cur != null && prev != null && prev > 0) ? Math.round(((cur - prev) / prev) * 1000) / 10 : null;
      const chg7 = pct(winAvg(7, 0), winAvg(14, 7));
      const chg30 = pct(winAvg(30, 0), winAvg(60, 30));

      return {
        latest: prices[0],
        avg: Math.round(prices.reduce((a, b) => a + b, 0) / prices.length),
        min: Math.min(...prices),
        max: Math.max(...prices),
        count: prices.length,
        chg7, chg30,
        daily,
        recent: items.slice(0, 8).map((t) => ({ price: Number(t.price), date: t.date, condition: t.condition })),
      };
    };

    return json({
      matched: true,
      productId: matchedId,
      productName: matchedName,
      snkrUrl: `https://snkrdunk.com/apparels/${matchedId}`,
      currency: "JPY",
      psa10: group((c) => c === "PSA10"),
      psa9: group((c) => c === "PSA9"),
      raw: group((c) => ["A", "B", "C", "D", ""].includes(c)),
      total: trades.length,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
