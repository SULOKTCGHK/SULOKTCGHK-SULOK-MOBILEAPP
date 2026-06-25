import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    // 用 service_role 建立 admin client
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 用呼叫者的 JWT 驗證身份
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)

    const userId = user.id

    // 刪除用戶所有資料（個別 try，避免某張表不存在就整個失敗）
    const del = async (table: string, col: string) => {
      try { await adminClient.from(table).delete().eq(col, userId) } catch (_) {}
    }
    await del('listings', 'seller_id')
    await del('offers', 'buyer_id')
    await del('offers', 'seller_id')
    await del('notifications', 'user_id')
    await del('reviews', 'reviewer_id')
    await del('wishlists', 'user_id')
    await del('follows', 'follower_id')
    await del('blocks', 'blocker_id')
    await del('reports', 'reporter_id')
    await del('profiles', 'id')

    // 刪除 Auth 帳號（需要 service_role）
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId)
    if (deleteError) throw deleteError

    return json({ success: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
