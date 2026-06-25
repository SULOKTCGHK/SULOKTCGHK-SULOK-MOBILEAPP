/**
 * 將 cached_sets 的系列 logo 從外部圖床搬到 Supabase Storage。
 *
 * 特性：
 *  - 可重複執行（idempotent）：已搬到 Storage 的會自動跳過，
 *    所以之後在 DB 新增系列後，再跑一次就只會搬新的。
 *  - 不改動圖檔內容，只下載 → 上傳 → 更新 cached_sets.logo_image 網址。
 *  - 按系列分資料夾：set-logos/<系列>/<set_id>.png（系列由 set id 推導，與 App 一致）。
 *  - 會把先前誤放到 other/ 的檔案自動重新歸位到正確系列資料夾。
 *
 * 執行方式（在專案根目錄）：
 *   npm install @supabase/supabase-js
 *   set SUPABASE_URL=https://你的專案.supabase.co
 *   set SUPABASE_SERVICE_ROLE_KEY=你的_service_role_key
 *   node supabase/scripts/migrate_set_logos.js
 *
 * （PowerShell 設環境變數：$env:SUPABASE_URL="..."; $env:SUPABASE_SERVICE_ROLE_KEY="..."）
 *
 * ⚠️ 需要 service_role key（有完整寫入權限），請勿外洩、勿 commit 進 git。
 */
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET = 'set-logos';

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('請先設定環境變數 SUPABASE_URL 與 SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const sb = createClient(SUPABASE_URL, SERVICE_KEY);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function ensureBucket() {
  const { data } = await sb.storage.getBucket(BUCKET);
  if (!data) {
    const { error } = await sb.storage.createBucket(BUCKET, { public: true });
    if (error && !String(error.message).includes('exists')) throw error;
    console.log(`已建立公開 bucket：${BUCKET}`);
  }
}

const publicPrefix = () =>
  `${SUPABASE_URL.replace(/\/$/, '')}/storage/v1/object/public/${BUCKET}/`;

async function run() {
  await ensureBucket();

  const { data: rows, error } = await sb
    .from('cached_sets')
    .select('id, logo_image, release_date');
  if (error) throw error;

  const safe = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9_-]/g, '') || 'misc';

  let migrated = 0, skipped = 0, failed = 0;
  const prefix = publicPrefix();

  for (const row of rows) {
    const id = row.id;
    const url = row.logo_image;
    if (!url) { skipped++; continue; }

    // 目標路徑：set-logos/<系列>/<set_id>.png（系列由 set id 推導，與 App 一致）
    const series = seriesKey(id, row.release_date);
    const path = `${series}/${safe(id)}.png`;
    const correctUrl = prefix + path;

    if (url === correctUrl) { skipped++; continue; } // 已在正確位置

    try {
      // 來源可能是外部圖床，或已在 Storage 的舊位置（如 other/）
      const fetchUrl = /\.(png|jpg|jpeg|webp)$/i.test(url) ? url : `${url}.png`;
      const res = await fetch(fetchUrl);
      if (!res.ok) throw new Error(`下載失敗 HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());

      const up = await sb.storage.from(BUCKET).upload(path, buf, {
        contentType: 'image/png', upsert: true,
      });
      if (up.error) throw up.error;

      const upd = await sb.from('cached_sets').update({ logo_image: correctUrl }).eq('id', id);
      if (upd.error) throw upd.error;

      // 若舊檔在本 bucket 且位置不同（例如 other/），清掉避免殘留
      if (url.startsWith(prefix)) {
        const oldPath = url.substring(prefix.length);
        if (oldPath !== path) await sb.storage.from(BUCKET).remove([oldPath]);
      }

      migrated++;
      console.log(`✓ ${series}/${id}`);
      await sleep(120);
    } catch (e) {
      failed++;
      console.warn(`✗ ${id}: ${e.message}`);
    }
  }

  console.log(`\n完成：搬移/歸位 ${migrated}、跳過 ${skipped}、失敗 ${failed}`);
}

// 由 set id 推導系列 key（移植自 App 的 dex_screen 邏輯）
const _alias = { ptm: 'pt', pts: 'pt', ptr: 'pt', ll: 'l', xyc: 'cp', smp: 'sm', sml: 'sm', snp: 'sm', sh: 's' };
const _known = new Set(['m', 'sv', 's', 'sp', 'sm', 'xy', 'cp', 'bw', 'dp', 'pt', 'l', 'adv']);
function eraKeyFromDate(date) {
  if (!date || String(date).length < 7) return 'misc';
  const d = String(date).substring(0, 7);
  if (d < '1999-07') return 'classic1';
  if (d < '2001-11') return 'neo';
  if (d < '2003-07') return 'ecard';
  if (d < '2007-01') return 'pcg';
  return 'misc';
}
function seriesKey(setId, releaseDate) {
  const id = String(setId).toLowerCase().replace('-pokemon-japan', '');
  const first = id.split('-')[0];
  const m = first.match(/^[a-z]+/);
  const pre = m ? m[0] : 'misc';
  const aliased = _alias[pre] || pre;
  if (_known.has(aliased)) return aliased;
  return eraKeyFromDate(releaseDate);
}

run().catch((e) => { console.error(e); process.exit(1); });
