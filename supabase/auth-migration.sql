-- ============================================================
-- MULIKA BIASHARA — AUTH MIGRATION
-- Run in Supabase SQL Editor AFTER mulika_biashara_schema.sql
-- ============================================================
-- DESIGN: Users log in with a plain username + 4-digit PIN.
-- No email address is ever shown to or required from the user.
-- Internally, Supabase Auth needs an email format, so we mask
-- usernames silently as username@mulika.internal — this detail
-- is hidden entirely inside the app and Edge Functions.
-- ============================================================

-- Required for password hashing in reset_user_pin
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ── 1. PROFILES TABLE ────────────────────────────────────────
-- The single source of truth for username, role, business
-- membership, and security question recovery.
create table if not exists profiles (
  id                   uuid        primary key default uuid_generate_v4(),
  user_id              uuid        not null references auth.users(id) on delete cascade,
  business_id          text        not null references businesses(id) on delete cascade,
  username             text        not null,          -- plain login name e.g. "james.k"
  display_name         text        not null,          -- shown in app e.g. "James Kariuki"
  role                 text        not null default 'maker'
                         check (role in ('maker','checker')),
  security_question    text        not null,
  security_answer_hash text        not null,          -- SHA-256, never plain text
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (business_id, username)                      -- unique per business, not globally
);

create index if not exists idx_profiles_user_id   on profiles(user_id);
create index if not exists idx_profiles_business  on profiles(business_id);
create index if not exists idx_profiles_username  on profiles(business_id, username);

-- ── 2. RLS ON PROFILES ───────────────────────────────────────
alter table profiles enable row level security;

-- Each user can read their own profile (session restore on page refresh)
create policy "User reads own profile"
  on profiles for select
  using (user_id = auth.uid());

-- Checkers can see all staff profiles in their business (for Setup tab)
create policy "Checker reads business profiles"
  on profiles for select
  using (business_id in (select user_business_ids()) and is_checker(business_id));

-- Checkers can update staff profiles (role changes, name corrections)
create policy "Checker updates profiles in own business"
  on profiles for update
  using (business_id in (select user_business_ids()) and is_checker(business_id));

-- No client-side INSERT policy — only Edge Functions (service role) can
-- create profiles, preventing self-registration with arbitrary business IDs.

-- ── 3. reset_user_pin RPC ────────────────────────────────────
-- Allows a user to reset their own PIN after passing the security
-- question check. Runs with elevated privileges (SECURITY DEFINER)
-- so it can write to auth.users without the service_role key ever
-- reaching the browser. The answer hash is re-verified server-side
-- as a second layer of defence.
create or replace function reset_user_pin(
  p_user_id                uuid,
  p_new_stretched_password text,
  p_answer_hash            text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stored_hash text;
begin
  -- Re-verify the security answer server-side
  select security_answer_hash into v_stored_hash
  from profiles
  where user_id = p_user_id
  limit 1;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Profile not found');
  end if;

  if v_stored_hash != p_answer_hash then
    return jsonb_build_object('success', false, 'error', 'Security answer does not match');
  end if;

  if length(p_new_stretched_password) < 12 then
    return jsonb_build_object('success', false, 'error', 'Password too short');
  end if;

  -- Update the password in Supabase Auth
  update auth.users
  set
    encrypted_password = crypt(p_new_stretched_password, gen_salt('bf')),
    updated_at = now()
  where id = p_user_id;

  -- Touch the profile timestamp
  update profiles set updated_at = now() where user_id = p_user_id;

  return jsonb_build_object('success', true);
end;
$$;

-- Only authenticated users can call this (not anonymous visitors)
revoke all on function reset_user_pin(uuid, text, text) from public;
grant execute on function reset_user_pin(uuid, text, text) to authenticated;

-- ── 4. UPDATE HELPER FUNCTIONS ───────────────────────────────
-- These are read by every RLS policy. Updated to check profiles
-- table (new auth) with a fallback to user_roles (old schema).
create or replace function user_business_ids()
returns setof text language sql security definer stable as $$
  select business_id from profiles where user_id = auth.uid()
  union
  select business_id from user_roles where user_id = auth.uid()
$$;

create or replace function is_checker(bid text)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from profiles
    where user_id = auth.uid() and business_id = bid and role = 'checker'
  ) or exists (
    select 1 from user_roles
    where user_id = auth.uid() and business_id = bid and role = 'checker'
  )
$$;

-- ── 5. LOOKUP FUNCTION FOR RECOVERY FLOW ────────────────────
-- The recovery flow needs to find a profile by username + business_id
-- to display the correct security question. Because profiles has RLS
-- (users can only read their own row), we need a SECURITY DEFINER
-- function that can do the lookup without requiring the user to be
-- authenticated first (they are not — that is the point of recovery).
--
-- This function is intentionally read-only and returns only the
-- fields needed for recovery: nothing sensitive is exposed.
create or replace function get_profile_for_recovery(
  p_username    text,
  p_business_id text
)
returns table (
  user_id              uuid,
  display_name         text,
  role                 text,
  security_question    text,
  security_answer_hash text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    user_id, display_name, role,
    security_question, security_answer_hash
  from profiles
  where username = lower(trim(p_username))
    and business_id = p_business_id
  limit 1;
$$;

-- Allow anonymous users to call this — they are on the login screen
-- and not yet authenticated. The function only returns the security
-- question, display name and hashed answer — no PINs, no raw data.
grant execute on function get_profile_for_recovery(text, text) to anon, authenticated;

-- ── 6. ALERT: SUPABASE DASHBOARD STEPS ──────────────────────
-- These cannot be done via SQL. Do them manually after running this:
--
-- A) Authentication → Providers → Email
--    Enable Email provider:  ON
--    Confirm email:          OFF  (Edge Functions set email_confirm:true directly)
--    Minimum password length: 8
--    Save
--
-- B) Authentication → URL Configuration
--    Site URL:      https://your-site.netlify.app
--    Redirect URLs: https://your-site.netlify.app
--    Save
--
-- C) Authentication → SMTP Settings
--    Leave blank — no SMTP configured means no emails are ever sent.
--    This is intentional: our users have no email addresses.
