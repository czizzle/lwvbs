// Supabase Edge Function: send-sms
// Sends one SMS through Twilio from the VBS number. The app calls this on
// check-out ("pickup text") so the parent gets an official confirmation from
// the church's number instead of a volunteer's personal phone.
//
// Auth: the function requires a signed-in Supabase user (verify_jwt is on by
// default), so only logged-in volunteers can trigger a text. The Twilio secret
// never leaves the server.
//
// Deploy + secrets: see supabase/functions/send-sms/README.md
//
// Request body:  { "to": "+12625550100", "message": "…" }
// Response:      { "ok": true, "sid": "SM…" }  or  { "ok": false, "error": "…" }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

// keep only sendable US numbers, normalize to E.164 (+1XXXXXXXXXX)
function toE164(raw: string): string {
  let d = String(raw || "").replace(/\D/g, "");
  if (d.length === 11 && d[0] === "1") d = d.slice(1);
  return d.length === 10 ? "+1" + d : "";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ ok: false, error: "POST only" }, 405);

  // Require a signed-in volunteer.
  try {
    const authHeader = req.headers.get("Authorization") || "";
    const supa = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supa.auth.getUser();
    if (!user) return json({ ok: false, error: "Not signed in" }, 401);
  } catch (_e) {
    return json({ ok: false, error: "Auth check failed" }, 401);
  }

  let to = "", message = "";
  try {
    const body = await req.json();
    to = toE164(body.to);
    message = String(body.message || "").slice(0, 320);
  } catch (_e) {
    return json({ ok: false, error: "Bad JSON" }, 400);
  }
  if (!to) return json({ ok: false, error: "No valid US mobile number" }, 400);
  if (!message) return json({ ok: false, error: "Empty message" }, 400);

  const sid = Deno.env.get("TWILIO_ACCOUNT_SID") || "";
  const token = Deno.env.get("TWILIO_AUTH_TOKEN") || "";
  const from = Deno.env.get("TWILIO_FROM") || ""; // a Twilio number (+1…) or a Messaging Service SID (MG…)
  if (!sid || !token || !from) {
    return json({ ok: false, error: "Twilio not configured" }, 500);
  }

  const form = new URLSearchParams({ To: to, Body: message });
  if (from.startsWith("MG")) form.set("MessagingServiceSid", from);
  else form.set("From", from);

  const resp = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: "Basic " + btoa(`${sid}:${token}`),
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form.toString(),
    },
  );
  const data = await resp.json();
  if (!resp.ok) {
    return json({ ok: false, error: data?.message || "Twilio error" }, 502);
  }
  return json({ ok: true, sid: data.sid });
});
