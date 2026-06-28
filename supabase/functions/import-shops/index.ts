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

// 用地址的地區名判斷香港大區（比經緯度準）；沒對到才用經緯度粗估
const REGION_KEYWORDS: Record<string, string[]> = {
  '離島': ['大嶼山', '東涌', '愉景灣', '長洲', '坪洲', '南丫', '梅窩', '大澳', '赤鱲角', '離島'],
  '新界': ['元朗', '屯門', '天水圍', '荃灣', '葵涌', '葵芳', '青衣', '沙田', '火炭', '大圍',
    '馬鞍山', '大埔', '粉嶺', '上水', '西貢', '將軍澳', '調景嶺', '錦上路', '流浮山', '新界'],
  '九龍': ['旺角', '油麻地', '佐敦', '尖沙咀', '深水埗', '長沙灣', '荔枝角', '美孚', '紅磡',
    '土瓜灣', '何文田', '九龍城', '九龍塘', '黃大仙', '鑽石山', '新蒲崗', '樂富', '觀塘',
    '牛頭角', '藍田', '九龍灣', '油塘', '九龍'],
  '香港島': ['中環', '金鐘', '灣仔', '銅鑼灣', '天后', '炮台山', '北角', '鰂魚涌', '太古',
    '西灣河', '筲箕灣', '柴灣', '上環', '西環', '西營盤', '堅尼地城', '跑馬地', '薄扶林',
    '香港仔', '鴨脷洲', '赤柱', '香港島'],
}

function classify(address: string | null, lat: number, lng: number): { region: string; district: string | null } {
  const a = address ?? ''
  for (const region of ['離島', '新界', '九龍', '香港島']) {
    // 先找具體地區名（細區）
    for (const k of REGION_KEYWORDS[region]) {
      if (k !== region && a.includes(k)) return { region, district: k }
    }
    // 只對到大區名本身
    if (a.includes(region)) return { region, district: null }
  }
  // 地址沒對到地區名 → 用緯度粗估大區（不用經度判離島，避免誤判西部新界）
  let region = '新界'
  if (lat < 22.29) region = '香港島'
  else if (lat < 22.34) region = '九龍'
  return { region, district: null }
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
        const { region, district } = classify(p.formattedAddress ?? null, lat, lng)
        return {
          google_place_id: p.id,
          name: p.displayName?.text ?? '',
          address: p.formattedAddress ?? null,
          region,
          district,
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
