import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' } })
  }

  try {
    // 從 JWT 取得呼叫者身份
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return new Response('Unauthorized', { status: 401 })

    // 用 service_role 建立 admin client
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 驗證 JWT，取得 user_id
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) return new Response('Unauthorized', { status: 401 })

    const userId = user.id

    // 刪除用戶所有資料
    await adminClient.from('listings').delete().eq('seller_id', userId)
    await adminClient.from('offers').delete().eq('buyer_id', userId)
    await adminClient.from('offers').delete().eq('seller_id', userId)
    await adminClient.from('notifications').delete().eq('user_id', userId)
    await adminClient.from('reviews').delete().eq('reviewer_id', userId)
    await adminClient.from('wishlists').delete().eq('user_id', userId)
    await adminClient.from('follows').delete().eq('follower_id', userId)
    await adminClient.from('profiles').delete().eq('id', userId)

    // 刪除 Auth 帳號（需要 service_role）
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})
