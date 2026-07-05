// Supabase Edge Function: onboard-business
// Creates a new SME business with server-generated ID and registers
// the owner's account with PIN + security question.
// The service_role key is only used here — never in browser code.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Must match the client-side stretchPin() function exactly
function stretchPin(pin: string, username: string): string {
  return `${pin}_${username.trim().toLowerCase()}_mulika_secure_2025`;
}
function usernameToEmail(username: string): string {
  return username.trim().toLowerCase().replace(/\s+/g, '.') + '@mulika.internal';
}
async function hashAnswer(answer: string): Promise<string> {
  const normalized = answer.trim().toLowerCase();
  const encoded = new TextEncoder().encode(normalized);
  const buf = await crypto.subtle.digest('SHA-256', encoded);
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2,'0')).join('');
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const {
      businessName, vertical,
      ownerUsername, ownerDisplayName, ownerPin,
      securityQuestion, securityAnswer
    } = await req.json();

    // Validate
    if (!businessName || !ownerUsername || !ownerPin || !ownerDisplayName || !securityQuestion || !securityAnswer) {
      return new Response(JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }
    if (!/^\d{4}$/.test(ownerPin)) {
      return new Response(JSON.stringify({ error: "PIN must be exactly 4 digits" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    const maskedEmail = usernameToEmail(ownerUsername);
    const stretchedPassword = stretchPin(ownerPin, ownerUsername);
    const answerHash = await hashAnswer(securityAnswer);

    // 1. Create Supabase Auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: maskedEmail,
      password: stretchedPassword,
      email_confirm: true,
    });
    if (authError) return new Response(JSON.stringify({ error: authError.message }),
      { status: 400, headers: { ...cors, "Content-Type": "application/json" } });

    // 2. Generate server-issued business UUID
    const businessId = crypto.randomUUID();

    // 3. Insert business record
    const { error: bizError } = await supabase.from("businesses").insert({
      id: businessId, name: businessName,
      vertical: vertical || "🚗", name_color: "#c1543a", currency: "KES",
    });
    if (bizError) {
      await supabase.auth.admin.deleteUser(authData.user.id);
      return new Response(JSON.stringify({ error: "Business creation failed: " + bizError.message }),
        { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
    }

    // 4. Insert profiles row (single source of truth for username, role, security question)
    const { error: profileError } = await supabase.from("profiles").insert({
      user_id: authData.user.id,
      business_id: businessId,
      username: ownerUsername.trim().toLowerCase(),
      display_name: ownerDisplayName,
      role: "checker", // first owner is always checker (can approve, view all)
      security_question: securityQuestion,
      security_answer_hash: answerHash,
    });
    if (profileError) {
      await supabase.from("businesses").delete().eq("id", businessId);
      await supabase.auth.admin.deleteUser(authData.user.id);
      return new Response(JSON.stringify({ error: "Profile creation failed: " + profileError.message }),
        { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({
      success: true, businessId,
      message: `Business "${businessName}" created. Username: ${ownerUsername}`,
    }), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });

  } catch (err) {
    return new Response(JSON.stringify({ error: "Unexpected error: " + err.message }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
