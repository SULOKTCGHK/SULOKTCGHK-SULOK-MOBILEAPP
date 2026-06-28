// 電話認證（Twilio Verify API）
// Twilio 自管驗證碼：send 觸發發送、check 由 Twilio 驗證；本端不存碼。
// 需 JWT：只有登入者能認證自己。
// POST { action:"send",  phone:"+852..." }
// POST { action:"check", phone:"+852...", code:"123456" }
//
// 需設定 secrets：
//   TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN
//   TWILIO_VERIFY_SID  Verify Service SID，例：VA03b836876616f4291183b90b425934d9
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const SB = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SVC = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TW_SID = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
const TW_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
const VERIFY_SID = Deno.env.get("TWILIO_VERIFY_SID") ?? "";

function json(o: unknown, s = 200) {
  return new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    if (!TW_SID || !TW_TOKEN || !VERIFY_SID) {
      return json({ error: "驗證服務尚未設定完整（缺 Twilio / TWILIO_VERIFY_SID）" }, 503);
    }

    const body = await req.json().catch(() => ({}));
    const action = body.action as string;
    const mode = body.mode as string | undefined; // "register" = 註冊時，免登入、不更新 profile
    const phone = (body.phone as string ?? "").trim();
    if (!phone.startsWith("+")) return json({ error: "電話格式需含國碼，如 +852" }, 400);

    // 認證：註冊模式不需登入；其他（已登入改/驗電話）需登入
    let userId: string | null = null;
    if (mode !== "register") {
      const authHeader = req.headers.get("Authorization") ?? "";
      const userClient = createClient(SB, ANON, { global: { headers: { Authorization: authHeader } } });
      const { data: { user } } = await userClient.auth.getUser();
      if (!user) return json({ error: "未登入" }, 401);
      userId = user.id;
    }

    const twAuth = "Basic " + btoa(`${TW_SID}:${TW_TOKEN}`);
    const base = `https://verify.twilio.com/v2/Services/${VERIFY_SID}`;

    if (action === "send") {
      const r = await fetch(`${base}/Verifications`, {
        method: "POST",
        headers: { "Authorization": twAuth, "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ To: phone, Channel: "sms" }),
      });
      const data = await r.json().catch(() => ({}));
      if (!r.ok) {
        return json({ error: `Twilio ${r.status}: ${data?.message ?? ""}` }, 400);
      }
      return json({ ok: true });
    }

    if (action === "check") {
      const code = (body.code as string ?? "").trim();
      const r = await fetch(`${base}/VerificationCheck`, {
        method: "POST",
        headers: { "Authorization": twAuth, "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ To: phone, Code: code }),
      });
      const data = await r.json().catch(() => ({}));
      if (r.ok && data?.status === "approved") {
        // 已登入：更新自己的 profile；註冊模式：只回驗證通過（建帳號後再寫 phone）
        if (userId) {
          const admin = createClient(SB, SVC);
          await admin.from("profiles").update({
            phone, phone_verified: true, updated_at: new Date().toISOString(),
          }).eq("id", userId);
        }
        return json({ ok: true, verified: true });
      }
      return json({ ok: false, error: "驗證碼錯誤或已過期" });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
