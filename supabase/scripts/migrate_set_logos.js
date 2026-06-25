/**
 * 將 cached_sets 的系列 logo 從外部圖床搬到 Supabase Storage。
 *
 * 特性：
 *  - 可重複執行（idempotent）：已搬到 Storage 的會自動跳過，
 *    所以之後在 DB 新增系列後，再跑一次就只會搬新的。
 *  - 不改動圖檔內容，只下載 → 上傳 → 更新 cached_sets.logo_image 網址。
 *  - 按系列分資料夾儲存：set-logos/<series_id>/<set_id>.png（資料整齊）。
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
    .select('id, logo_image, series_id');
  if (error) throw error;

  // 清理資料夾/檔名用（去掉非法字元）
  const safe = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9_-]/g, '') || 'other';

  let migrated = 0, skipped = 0, failed = 0;
  const prefix = publicPrefix();

  for (const row of rows) {
    const id = row.id;
    const url = row.logo_image;
    if (!url) { skipped++; continue; }
    if (url.startsWith(prefix)) { skipped++; continue; } // 已搬過

    try {
      // 有些 TCGdex 網址沒有副檔名，補 .png
      const fetchUrl = /\.(png|jpg|jpeg|webp)$/i.test(url) ? url : `${url}.png`;
      const res = await fetch(fetchUrl);
      if (!res.ok) throw new Error(`下載失敗 HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());

      // 按系列分資料夾：set-logos/<series_id>/<set_id>.png
      const series = safe(row.series_id);
      const path = `${series}/${safe(id)}.png`;
      const up = await sb.storage.from(BUCKET).upload(path, buf, {
        contentType: 'image/png', upsert: true,
      });
      if (up.error) throw up.error;

      const newUrl = prefix + path;
      const upd = await sb.from('cached_sets').update({ logo_image: newUrl }).eq('id', id);
      if (upd.error) throw upd.error;

      migrated++;
      console.log(`✓ ${id}`);
      await sleep(150); // 友善延遲，避免被圖床擋
    } catch (e) {
      failed++;
      console.warn(`✗ ${id}: ${e.message}`);
    }
  }

  console.log(`\n完成：搬移 ${migrated}、跳過 ${skipped}、失敗 ${failed}`);
}

run().catch((e) => { console.error(e); process.exit(1); });
