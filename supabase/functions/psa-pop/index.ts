import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const PSA_BASE = 'https://api.psacard.com/publicapi';

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const body = await req.json();
    const { spec_id, cert_number, card_id, set_id, card_number, cached_card_id } = body;

    const psaToken = Deno.env.get('PSA_TOKEN');
    if (!psaToken) return new Response(JSON.stringify({ error: 'PSA_TOKEN not set' }), { status: 500 });

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    let finalSpecId = spec_id;

    // 若只有 cert number，先查出 SpecID
    if (!finalSpecId && cert_number) {
      const certRes = await fetch(
        `${PSA_BASE}/cert/GetByCertNumber/${cert_number}`,
        { headers: { Authorization: `bearer ${psaToken}` } }
      );
      if (!certRes.ok) {
        return new Response(JSON.stringify({ error: `PSA cert lookup failed: ${certRes.status}` }), {
          status: certRes.status, headers: corsHeaders });
      }
      const certData = await certRes.json();
      finalSpecId = certData?.PSACert?.SpecID
          ?? certData?.PSACert?.specID
          ?? certData?.SpecID;

      if (!finalSpecId) {
        return new Response(JSON.stringify({ error: 'SpecID not found for this cert' }), {
          status: 404, headers: corsHeaders });
      }

      // 如果傳了 card_id，順便把 spec_id 寫入 cached_cards
      if (card_id) {
        await supabase.from('cached_cards')
          .update({ psa_spec_id: String(finalSpecId) })
          .eq('id', card_id);
      }
    }

    if (!finalSpecId) {
      return new Response(JSON.stringify({ error: 'spec_id or cert_number required' }), { status: 400 });
    }

    // 已有緩存 → 直接返回，不重複呼叫 PSA API
    const { data: cached } = await supabase
      .from('psa_pop_cache')
      .select('*')
      .eq('spec_id', String(finalSpecId))
      .maybeSingle();

    if (cached && (cached.total ?? 0) > 0) {
      return new Response(JSON.stringify({ ok: true, spec_id: finalSpecId, data: cached }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // 用 SpecID 查 Pop
    const popRes = await fetch(
      `${PSA_BASE}/pop/GetPSASpecPopulation/${finalSpecId}`,
      { headers: { Authorization: `bearer ${psaToken}` } }
    );

    if (!popRes.ok) {
      return new Response(JSON.stringify({ error: `PSA pop lookup failed: ${popRes.status}` }), {
        status: popRes.status, headers: corsHeaders });
    }

    const data = await popRes.json();
    // PSA API returns flat structure: { SpecID, Description, PSAPop: { Total, Grade10, Grade9, ... } }
    const psaPop = data?.PSAPop ?? {};
    const description = data?.Description ?? null;

    const row = {
      spec_id:  String(finalSpecId),
      card_name: description,
      set_name:  null,
      pop_10:   Number(psaPop.Grade10  ?? 0),
      pop_9:    Number(psaPop.Grade9   ?? 0),
      pop_8:    Number(psaPop.Grade8   ?? 0),
      pop_7:    Number(psaPop.Grade7   ?? 0),
      pop_6:    Number(psaPop.Grade6   ?? 0),
      pop_5:    Number(psaPop.Grade5   ?? 0),
      pop_auth: Number(psaPop.Auth     ?? 0),
      total:    Number(psaPop.Total    ?? 0),
      fetched_at: new Date().toISOString(),
    };

    await supabase.from('psa_pop_cache')
      .upsert(row, { onConflict: 'spec_id' });

    // 回寫 psa_spec_id 到 cached_cards（讓圖鑑也能顯示 Pop）
    if (cached_card_id) {
      // 用戶從圖鑑選卡 → 精確 card id，直接更新
      await supabase.from('cached_cards')
        .update({ psa_spec_id: String(finalSpecId) })
        .eq('id', cached_card_id)
        .is('psa_spec_id', null);
    } else if (set_id && card_number) {
      // fallback：靠 set_id + card_number 匹配
      await supabase.from('cached_cards')
        .update({ psa_spec_id: String(finalSpecId) })
        .eq('set_id', set_id)
        .eq('number', card_number)
        .is('psa_spec_id', null);
    }

    return new Response(JSON.stringify({ ok: true, spec_id: finalSpecId, data: row }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: corsHeaders });
  }
});
