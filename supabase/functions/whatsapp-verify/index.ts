// WhatsApp 電話認證（Twilio Messaging API + 預先批准範本，支援 Sandbox）
// 自管 OTP：產生驗證碼 → 用 WhatsApp 範本發送 → 存 phone_otps → check 時比對。
// 需 JWT：只有登入者能認證自己。
// POST { action:"send",  phone:"+852..." }
// POST { action:"check", phone:"+852...", code:"123456" }
//
// 需設定 secrets：
//   TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN
//   WHATSAPP_FROM        例：whatsapp:+14155238886（Sandbox 號碼）
//   TWILIO_TEMPLATE_SID  驗證碼範本 ContentSid，例：HX229f5a04fd0510ce1b071852155d3e75
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
const WA_FROM = Deno.env.get("WHATSAPP_FROM") ?? "";
const TEMPLATE = Deno.env.get("TWILIO_TEMPLATE_SID") ?? "";

function json(o: unknown, s = 200) {
  return new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    // 驗證呼叫者
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(SB, ANON, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "未登入" }, 401);

    if (!TW_SID || !WA_FROM || !TEMPLATE) {
      return json({ error: "驗證服務尚未設定完整（缺 Twilio/WHATSAPP_FROM/TEMPLATE）" }, 503);
    }

    const body = await req.json().catch(() => ({}));
    const action = body.action as string;
    const phone = (body.phone as string ?? "").trim();
    if (!phone.startsWith("+")) return json({ error: "電話格式需含國碼，如 +852" }, 400);

    const admin = createClient(SB, SVC);
    const twAuth = "Basic " + btoa(`${TW_SID}:${TW_TOKEN}`);

    if (action === "send") {
      const code = String(Math.floor(100000 + Math.random() * 900000));
      const expires = new Date(Date.now() + 10 * 60 * 1000).toISOString();
      await admin.from("phone_otps").upsert({
        user_id: user.id, phone, code, expires_at: expires, created_at: new Date().toISOString(),
      });

      const r = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${TW_SID}/Messages.json`, {
        method: "POST",
        headers: { "Authorization": twAuth, "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          To: `whatsapp:${phone}`,
          From: WA_FROM,
          ContentSid: TEMPLATE,
          ContentVariables: JSON.stringify({ "1": code }),
        }),
      });
      if (!r.ok) {
        const t = await r.text();
        return json({ error: `Twilio ${r.status}: ${t.slice(0, 300)}` }, 400);
      }
      return json({ ok: true });
    }

    if (action === "check") {
      const code = (body.code as string ?? "").trim();
      const { data: row } = await admin.from("phone_otps").select().eq("user_id", user.id).maybeSingle();
      if (!row) return json({ ok: false, error: "請先發送驗證碼" });
      if (new Date(row.expires_at).getTime() < Date.now()) return json({ ok: false, error: "驗證碼已過期" });
      if (row.code !== code || row.phone !== phone) return json({ ok: false, error: "驗證碼錯誤" });

      await admin.from("profiles").update({
        phone, phone_verified: true, updated_at: new Date().toISOString(),
      }).eq("id", user.id);
      await admin.from("phone_otps").delete().eq("user_id", user.id);
      return json({ ok: true, verified: true });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
