-- ============================================================
-- MULIKA BIASHARA — InverBrass POS Platform
-- Supabase PostgreSQL Schema
-- Multi-tenant: every table partitioned by business_id
-- ============================================================
-- DESIGN PRINCIPLES:
--   1. Each SME business is identified by a business_id UUID.
--      No business can ever read or write another business's data
--      — enforced at two layers: application filters AND Row Level
--      Security (RLS) policies that check auth.uid() against
--      the businesses table.
--   2. auth.users (Supabase built-in) handles password hashing
--      and session tokens — we never store plain-text passwords.
--   3. RLS is the security guarantee. The application-side
--      business_id filter is a convenience / performance optimiser,
--      not the security boundary.
-- ============================================================

-- ─── EXTENSION ────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─── 1. BUSINESSES ────────────────────────────────────────────
-- One row per SME business registered on the platform.
-- business_id is a client-generated UUID (created on first install).
-- In a production onboarding flow this would be server-assigned.
create table if not exists businesses (
  id              text        primary key,        -- client-generated UUID e.g. "biz-abc123-xyz"
  name            text        not null,
  logo            text,                           -- base64 data URL; migrate to Storage in prod
  vertical        text        not null default '🚗', -- emoji key matching VERTICAL_REGISTRY
  name_color      text        not null default '#c1543a',
  address         text,
  email           text,
  phone           text,
  currency        text        not null default 'KES',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ─── 2. USER ROLES ────────────────────────────────────────────
-- Maps Supabase Auth user IDs to a role within a specific business.
-- A user can work for multiple businesses (e.g. an InverBrass admin)
-- by having multiple rows — one per business.
create table if not exists user_roles (
  id              uuid        primary key default uuid_generate_v4(),
  business_id     text        not null references businesses(id) on delete cascade,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  username        text        not null,
  full_name       text        not null,
  role            text        not null check (role in ('maker','checker')),
  created_at      timestamptz not null default now(),
  unique (business_id, username)
);
create index if not exists idx_user_roles_business on user_roles(business_id);
create index if not exists idx_user_roles_user    on user_roles(user_id);

-- ─── 3. PRODUCTS / SERVICES ───────────────────────────────────
-- The service/product catalogue for each business.
-- Products go through a maker-checker approval workflow before
-- going live — see product_requests table below.
create table if not exists products (
  id              text        not null,           -- e.g. "PRD0001", stable for shelf life
  business_id     text        not null references businesses(id) on delete cascade,
  name            text        not null,
  price           numeric     not null check (price >= 0),
  category        text        not null check (category in ('service','addon')),
  icon            text        not null default '🔧',
  is_active       boolean     not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  primary key (business_id, id)
);
create index if not exists idx_products_business on products(business_id);

-- ─── 4. TRANSACTIONS ──────────────────────────────────────────
-- Every POS sale. The business_id column is the partition key.
-- Credit sales set payment_method='Credit'; when settled later a
-- second 'Credit paid' row is inserted and the original row is
-- updated with credit_settled=true.
create table if not exists transactions (
  id                      text        not null,   -- e.g. "TX1042"
  business_id             text        not null references businesses(id) on delete cascade,
  items                   jsonb       not null,   -- [{name, qty, price, productId}]
  total                   numeric     not null check (total >= 0),
  payment_method          text        not null,   -- M-Pesa | Cash | Card | Credit | Split | Free | Credit paid
  splits                  jsonb,                  -- [{method, amount}] for Split payments
  discount_amount         numeric     not null default 0,  -- KES amount discounted (split-discount leg)
  staff_name              text,
  identifier_value        text,                   -- plate / table# / member ID (vertical-specific)
  customer_phone          text,
  customer_name           text,
  is_free_wash            boolean     not null default false,  -- any loyalty redemption
  is_fully_free           boolean     not null default false,  -- zero charge (loyalty, fully covered)
  free_wash_saving        numeric     not null default 0,      -- KES value of loyalty discount applied
  credit_settled          boolean     not null default false,
  credit_settled_by       text,
  credit_settled_date     date,
  credit_settled_at       timestamptz,
  credit_settlement       boolean     not null default false,  -- true = this IS the settlement tx
  original_tx_id          text,                               -- for settlement rows
  created_at              timestamptz not null default now(),
  primary key (business_id, id)
);
create index if not exists idx_transactions_business     on transactions(business_id);
create index if not exists idx_transactions_created      on transactions(business_id, created_at desc);
create index if not exists idx_transactions_payment      on transactions(business_id, payment_method);
create index if not exists idx_transactions_identifier   on transactions(business_id, identifier_value);
create index if not exists idx_transactions_credit_open  on transactions(business_id, credit_settled) where payment_method = 'Credit';

-- ─── 5. CUSTOMERS ─────────────────────────────────────────────
-- Loyalty tracking keyed by the vertical's identifier
-- (plate for car wash, member ID for salon, etc.)
create table if not exists customers (
  id                    uuid        primary key default uuid_generate_v4(),
  business_id           text        not null references businesses(id) on delete cascade,
  identifier_value      text        not null,     -- plate / table# / member ID
  name                  text,
  phone                 text,
  visits                integer     not null default 0,
  free_wash_available   boolean     not null default false,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (business_id, identifier_value)
);
create index if not exists idx_customers_business    on customers(business_id);
create index if not exists idx_customers_identifier  on customers(business_id, identifier_value);

-- ─── 6. PRODUCT REQUESTS (maker-checker approvals) ────────────
-- All new products and price/name changes go through this workflow
-- before taking effect. Approved records are then written to products.
create table if not exists product_requests (
  id                  uuid        primary key default uuid_generate_v4(),
  business_id         text        not null references businesses(id) on delete cascade,
  case_id             text        not null,       -- e.g. "CASE00001"
  product_id          text        not null,       -- stable product ID
  type                text        not null check (type in ('new','edit')),
  name                text        not null,
  price               numeric     not null,
  category            text        not null,
  icon                text        not null,
  reason              text,
  old_name            text,
  old_price           numeric,
  submitted_by        text        not null,
  submitted_by_user   text        not null,       -- username
  submitted_at        timestamptz not null default now(),
  status              text        not null default 'pending'
                        check (status in ('pending','approved','auto-approved','rejected','returned')),
  reviewed_by         text,
  reviewed_at         timestamptz,
  rejection_reason    text,
  is_resubmission     boolean     not null default false,
  unique (business_id, case_id)
);
create index if not exists idx_requests_business on product_requests(business_id);
create index if not exists idx_requests_status   on product_requests(business_id, status);

-- ─── 7. ALERTS (owner notifications) ─────────────────────────
-- Loyalty milestones and free reward alerts.
create table if not exists alerts (
  id              uuid        primary key default uuid_generate_v4(),
  business_id     text        not null references businesses(id) on delete cascade,
  type            text        not null,   -- 'loyalty' | 'free_wash_completed'
  message         text        not null,
  identifier_val  text,                  -- the plate / member ID that triggered it
  is_read         boolean     not null default false,
  created_at      timestamptz not null default now()
);
create index if not exists idx_alerts_business on alerts(business_id, created_at desc);

-- ─── 8. AUDIT LOG ─────────────────────────────────────────────
-- All significant actions: logins, approvals, staff changes, credit settlements.
create table if not exists audit_log (
  id              uuid        primary key default uuid_generate_v4(),
  business_id     text        not null references businesses(id) on delete cascade,
  action          text        not null,   -- 'login_success' | 'login_failed' | 'approved' |
                                          -- 'rejected' | 'returned' | 'submitted' |
                                          -- 'auto-approved' | 'staff_added' | 'staff_removed' |
                                          -- 'credit_paid'
  case_id         text,
  subject         text,                  -- product name, staff name, etc.
  amount          numeric,
  actor           text,                  -- who performed the action (username or 'System')
  reason          text,
  created_at      timestamptz not null default now()
);
create index if not exists idx_audit_business on audit_log(business_id, created_at desc);

-- ─── 9. LOGIN EVENTS ──────────────────────────────────────────
-- Security record of every login attempt (success and failure).
-- Stored at DB level so it can't be erased by clearing browser storage.
create table if not exists login_events (
  id              uuid        primary key default uuid_generate_v4(),
  business_id     text        not null references businesses(id) on delete cascade,
  username        text,
  success         boolean     not null,
  ip_address      text,                  -- populated server-side when using Edge Functions
  created_at      timestamptz not null default now()
);
create index if not exists idx_login_events_business on login_events(business_id, created_at desc);

-- ─── 10. RECONCILIATION HISTORY ───────────────────────────────
-- Saved daily reconciliation run summaries.
-- Line-item detail is not stored (too large); summaries + breakdowns are.
create table if not exists reconciliation_history (
  id                  uuid        primary key default uuid_generate_v4(),
  business_id         text        not null references businesses(id) on delete cascade,
  date_key            date        not null,        -- the calendar date of this reconciliation
  date_label          text,
  pos_total           numeric     not null default 0,
  pay_total           numeric     not null default 0,
  leakage             numeric     not null default 0,
  missing_count       integer     not null default 0,
  variance_count      integer     not null default 0,
  matched_count       integer     not null default 0,
  total_count         integer     not null default 0,
  received_by_method  jsonb,               -- {M-Pesa: 1500, Cash: 800, ...}
  saved_at            timestamptz not null default now(),
  unique (business_id, date_key)           -- one saved report per day per business
);
create index if not exists idx_recon_business on reconciliation_history(business_id, date_key desc);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- This is the real security boundary. All tables are locked down
-- so only authenticated users belonging to the correct business
-- can read or write rows. The business membership check goes
-- through user_roles which maps auth.uid() -> business_id.
-- ============================================================

-- Helper: returns all business_ids the current user belongs to
create or replace function user_business_ids()
returns setof text language sql security definer stable as $$
  select business_id from user_roles where user_id = auth.uid()
$$;

-- Helper: returns true if the current user is a checker for the given business
create or replace function is_checker(bid text)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from user_roles
    where user_id = auth.uid() and business_id = bid and role = 'checker'
  )
$$;

-- Enable RLS on every table
alter table businesses             enable row level security;
alter table user_roles             enable row level security;
alter table products               enable row level security;
alter table transactions           enable row level security;
alter table customers              enable row level security;
alter table product_requests       enable row level security;
alter table alerts                 enable row level security;
alter table audit_log              enable row level security;
alter table login_events           enable row level security;
alter table reconciliation_history enable row level security;

-- ── businesses ────────────────────────────────────────────────
create policy "Members read own business"
  on businesses for select
  using (id in (select user_business_ids()));

create policy "Checkers update own business"
  on businesses for update
  using (is_checker(id));

-- ── user_roles ────────────────────────────────────────────────
create policy "Members read roles in own business"
  on user_roles for select
  using (business_id in (select user_business_ids()));

create policy "Checkers manage roles in own business"
  on user_roles for all
  using (is_checker(business_id));

-- ── products ──────────────────────────────────────────────────
create policy "Members read own business products"
  on products for select
  using (business_id in (select user_business_ids()));

create policy "Checkers manage own business products"
  on products for all
  using (is_checker(business_id));

-- ── transactions ──────────────────────────────────────────────
create policy "Members read own business transactions"
  on transactions for select
  using (business_id in (select user_business_ids()));

create policy "Members insert own business transactions"
  on transactions for insert
  with check (business_id in (select user_business_ids()));

create policy "Members update own business transactions (credit settlement only)"
  on transactions for update
  using (business_id in (select user_business_ids()));

-- ── customers ─────────────────────────────────────────────────
create policy "Members access own business customers"
  on customers for all
  using (business_id in (select user_business_ids()));

-- ── product_requests ──────────────────────────────────────────
-- Makers can submit and see their own; checkers see all for their business
create policy "Makers read own submissions"
  on product_requests for select
  using (
    business_id in (select user_business_ids()) and
    (submitted_by_user = (select username from user_roles where user_id=auth.uid() and business_id=product_requests.business_id limit 1)
     or is_checker(business_id))
  );

create policy "Makers insert requests"
  on product_requests for insert
  with check (business_id in (select user_business_ids()));

create policy "Checkers approve / reject (cannot self-approve)"
  on product_requests for update
  using (
    is_checker(business_id) and
    submitted_by_user != (
      select username from user_roles
      where user_id = auth.uid() and business_id = product_requests.business_id
      limit 1
    )
  );

-- ── alerts ────────────────────────────────────────────────────
create policy "Members access own business alerts"
  on alerts for all
  using (business_id in (select user_business_ids()));

-- ── audit_log ─────────────────────────────────────────────────
create policy "Members read own business audit"
  on audit_log for select
  using (business_id in (select user_business_ids()));

create policy "System inserts audit entries"
  on audit_log for insert
  with check (business_id in (select user_business_ids()));

-- ── login_events ──────────────────────────────────────────────
create policy "Checkers read login events"
  on login_events for select
  using (is_checker(business_id));

create policy "Anyone insert login events (unauthenticated logins logged too)"
  on login_events for insert
  with check (true);  -- tighten in prod with a service-role-only Edge Function

-- ── reconciliation_history ────────────────────────────────────
create policy "Members access own recon history"
  on reconciliation_history for all
  using (business_id in (select user_business_ids()));

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

-- Outstanding credit per business
create or replace view outstanding_credit as
select
  t.business_id,
  t.id,
  t.identifier_value,
  t.customer_name,
  t.customer_phone,
  t.staff_name,
  t.created_at::date as sale_date,
  case
    when t.payment_method = 'Credit' then t.total
    else (
      select coalesce(sum((s->>'amount')::numeric), 0)
      from jsonb_array_elements(t.splits) s
      where s->>'method' = 'Credit'
    )
  end as credit_amount
from transactions t
where t.credit_settled = false
  and not t.credit_settlement
  and (t.payment_method = 'Credit'
    or (t.payment_method = 'Split'
        and t.splits @> '[{"method":"Credit"}]'));

-- Daily sales summary per business
create or replace view daily_sales_summary as
select
  business_id,
  created_at::date                              as sale_date,
  count(*)                                      as transaction_count,
  sum(total)                                    as gross_total,
  sum(case when payment_method = 'Credit' and not credit_settled then total else 0 end)
                                                as outstanding_credit,
  sum(case when is_fully_free then 1 else 0 end) as fully_free_count,
  sum(case when is_free_wash then free_wash_saving else 0 end)
                                                as total_loyalty_savings
from transactions
where not credit_settlement
group by business_id, created_at::date;

-- ============================================================
-- NOTES FOR PRODUCTION DEPLOYMENT
-- ============================================================
-- 1. AUTHENTICATION
--    Use Supabase Auth (signInWithPassword / signUp).
--    The current prototype stores passwords in localStorage —
--    migrate to Supabase Auth before going live.
--    Each user account in Supabase Auth needs a matching row in
--    user_roles to associate them with a business.
--
-- 2. STORAGE
--    Business logos are stored as base64 in the businesses.logo
--    column. For production migrate these to Supabase Storage:
--    - Bucket: business-logos/{business_id}/logo.png
--    - Store the public URL in businesses.logo instead of base64.
--    - Apply a Storage policy so only members of the business
--      can overwrite their own logo.
--
-- 3. BUSINESS ONBOARDING
--    Currently business_id is client-generated. In production,
--    create an onboarding Edge Function that:
--    a) Creates the auth.users record
--    b) Generates and assigns a server-side UUID as business_id
--    c) Inserts the businesses row
--    d) Inserts the first user_roles row (as checker/owner)
--    This prevents a client from choosing a business_id that
--    collides with an existing business.
--
-- 4. DB COLUMN for plate_number → identifier_value
--    The prototype still writes plate_number to the DB in the
--    saveTransactionToDb() function. Run this migration once
--    you update the app to write identifier_value instead:
--
--    alter table transactions
--      rename column plate_number to identifier_value;
--
-- 5. PRODUCT APPROVALS ENFORCEMENT
--    The RLS policy on product_requests prevents a checker from
--    approving their own submission (self-approval). Verify this
--    works with your Supabase project by running:
--
--    select id, case_id, submitted_by_user, status
--    from product_requests
--    where business_id = '<your-test-business-id>';
-- ============================================================
