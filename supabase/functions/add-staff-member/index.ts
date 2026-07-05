// Supabase Edge Function: add-staff-member
// Adds a staff member (maker) to an existing business.
// Called by a checker (manager/owner) from the Setup tab.
// Uses PIN + username — no email ever needed or shown to user.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return new Response(
      JSON.stringify({ error: "Missing authorization" }),
      { status: 401, headers: { ...cors, "Content-Type": "application/json" } }
    );

    const {
      businessId,
      staffUsername, staffDisplayName, staffPin,
      securityQuestion, securityAnswer,
      staffRole
    } = await req.json();

    if (!businessId || !staffUsername || !staffDisplayName || !staffPin || !securityQuestion || !securityAnswer) {
      return new Response(JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }
    if (!/^\d{4}$/.test(staffPin)) {
      return new Response(JSON.stringify({ error: "PIN must be exactly 4 digits" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    // Verify the calling user is a checker for this business
    const anonClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );
    const { data: { user: caller } } = await anonClient.auth.getUser();
    if (!caller) return new Response(JSON.stringify({ error: "Invalid session" }),
      { status: 401, headers: { ...cors, "Content-Type": "application/json" } });

    const { data: callerProfile } = await anonClient
      .from("profiles")
      .select("role")
      .eq("user_id", caller.id)
      .eq("business_id", businessId)
      .maybeSingle();

    if (!callerProfile || callerProfile.role !== "checker") {
      return new Response(JSON.stringify({ error: "Only a manager can add staff" }),
        { status: 403, headers: { ...cors, "Content-Type": "application/json" } });
    }

    // Check username is unique within this business
    const { data: existing } = await anonClient
      .from("profiles")
      .select("username")
      .eq("business_id", businessId)
      .eq("username", staffUsername.trim().toLowerCase())
      .maybeSingle();

    if (existing) return new Response(
      JSON.stringify({ error: `Username "${staffUsername}" is already taken in this business` }),
      { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
    );

    // Use service role to create Auth user
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    const maskedEmail = usernameToEmail(staffUsername);
    const stretchedPassword = stretchPin(staffPin, staffUsername);
    const answerHash = await hashAnswer(securityAnswer);

    const { data: newUser, error: createError } = await serviceClient.auth.admin.createUser({
      email: maskedEmail,
      password: stretchedPassword,
      email_confirm: true,
    });
    if (createError) return new Response(
      JSON.stringify({ error: createError.message }),
      { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
    );

    const { error: profileError } = await serviceClient.from("profiles").insert({
      user_id: newUser.user.id,
      business_id: businessId,
      username: staffUsername.trim().toLowerCase(),
      display_name: staffDisplayName,
      role: staffRole || "maker",
      security_question: securityQuestion,
      security_answer_hash: answerHash,
    });
    if (profileError) {
      await serviceClient.auth.admin.deleteUser(newUser.user.id);
      return new Response(JSON.stringify({ error: "Profile creation failed: " + profileError.message }),
        { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({
      success: true,
      staffUsername: staffUsername.trim().toLowerCase(),
      displayName: staffDisplayName,
      role: staffRole || "maker",
      message: `${staffDisplayName} added as ${staffRole || "maker"}. They can now log in with username "${staffUsername}" and their PIN.`,
    }), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });

  } catch (err) {
    return new Response(JSON.stringify({ error: "Unexpected error: " + err.message }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
