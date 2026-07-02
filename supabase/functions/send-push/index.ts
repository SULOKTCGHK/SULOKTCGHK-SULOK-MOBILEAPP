import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { user_id, title, body, data } = await req.json()
    if (!user_id || !title) {
      return new Response(JSON.stringify({ error: 'missing user_id or title' }), { status: 400, headers: CORS })
    }

    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 取得用戶 FCM token
    const { data: profile } = await adminClient
      .from('profiles')
      .select('fcm_token')
      .eq('id', user_id)
      .maybeSingle()

    const token = profile?.fcm_token
    if (!token) {
      console.log('[send-push] no fcm_token for user', user_id)
      return new Response(JSON.stringify({ skipped: 'no fcm_token' }), { headers: CORS })
    }
    console.log('[send-push] sending to token', String(token).slice(0, 24), '…')

    // 取得 Firebase service account 憑證（存在 Supabase Secrets）
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      return new Response(JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT not set' }), { status: 500, headers: CORS })
    }
    const serviceAccount = JSON.parse(serviceAccountJson)

    // 取得 FCM OAuth token（使用 JWT + Google Auth）
    const fcmToken = await getGoogleAccessToken(serviceAccount)
    const projectId = serviceAccount.project_id

    // 發送 FCM v1 訊息
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${fcmToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body: body ?? '' },
            data: data ?? {},
            android: {
              priority: 'high',
              notification: { channel_id: 'tcgspot_high' },
            },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          },
        }),
      }
    )

    const fcmJson = await fcmRes.json()
    console.log('[send-push] FCM status', fcmRes.status, JSON.stringify(fcmJson))
    if (!fcmRes.ok) {
      // token 已失效（app 移除/重裝）→ 清掉，避免之後持續對死 token 發送
      const errCode = fcmJson?.error?.details?.find((d: Record<string, unknown>) =>
        String(d['@type']).includes('FcmError'))?.errorCode ?? fcmJson?.error?.status
      if (errCode === 'UNREGISTERED' || errCode === 'NOT_FOUND') {
        await adminClient.from('profiles')
          .update({ fcm_token: null, fcm_updated_at: null })
          .eq('id', user_id)
        console.log('[send-push] cleared dead token for', user_id)
        return new Response(JSON.stringify({ skipped: 'token_unregistered' }), { headers: CORS })
      }
      throw new Error(JSON.stringify(fcmJson))
    }

    return new Response(JSON.stringify({ success: true, fcm: fcmJson }), { headers: CORS })
  } catch (e) {
    console.error('[send-push] error', String(e))
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: CORS })
  }
})

// Google Service Account → OAuth2 access token（RS256 JWT）
async function getGoogleAccessToken(sa: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  )
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claim}`))
  const jwt = `${header}.${claim}.${b64url(String.fromCharCode(...new Uint8Array(sig)))}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const json = await res.json()
  if (!json.access_token) {
    console.error('[send-push] google token exchange failed', JSON.stringify(json))
    throw new Error('google_token_exchange_failed: ' + JSON.stringify(json))
  }
  return json.access_token
}

// JWT 要用 base64URL（btoa 是標準 base64，會讓簽章驗證失敗）
function b64url(input: string): string {
  return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, '')
  const bin = atob(b64)
  const buf = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i)
  return buf.buffer
}
