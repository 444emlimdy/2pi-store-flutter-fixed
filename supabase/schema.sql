-- 2pi STORE starter schema for Supabase PostgreSQL.
-- Review and apply in a TEST project first. Never expose the service_role key in the app.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'customer' check (role in ('customer','influencer','staff','owner')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  name text not null,
  subtitle text not null default '',
  category text not null check (category in ('games','apps','gift','subs')),
  price numeric(12,2) not null check (price >= 0),
  currency char(3) not null default 'USD',
  icon_key text not null default 'digital',
  image_url text,
  is_active boolean not null default true,
  stock_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.influencers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  display_name text not null,
  referral_code text not null unique,
  commission_percent numeric(5,2) not null default 0 check (commission_percent between 0 and 100),
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.coupons (
  code text primary key,
  discount_percent numeric(5,2) not null check (discount_percent > 0 and discount_percent <= 100),
  influencer_id uuid references public.influencers(id) on delete set null,
  starts_at timestamptz,
  expires_at timestamptz,
  max_uses integer check (max_uses is null or max_uses > 0),
  uses_count integer not null default 0 check (uses_count >= 0),
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  customer_name text not null,
  customer_email text not null,
  game_account_ref text,
  notes text,
  items jsonb not null check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) > 0),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  total numeric(12,2) not null check (total >= 0),
  currency char(3) not null default 'USD',
  coupon_code text references public.coupons(code) on delete set null,
  influencer_id uuid references public.influencers(id) on delete set null,
  payment_method text not null check (payment_method in ('local_transfer','card')),
  payment_status text not null default 'pending' check (payment_status in ('pending','verified','failed','refunded')),
  order_status text not null default 'awaiting_payment' check (order_status in ('awaiting_payment','paid','processing','delivered','cancelled','refunded')),
  payment_reference text,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.commissions (
  id uuid primary key default gen_random_uuid(),
  influencer_id uuid not null references public.influencers(id) on delete restrict,
  order_id uuid not null unique references public.orders(id) on delete restrict,
  amount numeric(12,2) not null check (amount >= 0),
  status text not null default 'pending' check (status in ('pending','approved','paid','reversed')),
  payout_reference text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists orders_user_created_idx on public.orders(user_id, created_at desc);
create index if not exists orders_status_created_idx on public.orders(order_status, created_at desc);
create index if not exists commissions_influencer_status_idx on public.commissions(influencer_id, status);

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.influencers enable row level security;
alter table public.coupons enable row level security;
alter table public.orders enable row level security;
alter table public.commissions enable row level security;
alter table public.audit_logs enable row level security;

-- The app_metadata role must be assigned by a trusted admin process, never by the user client.
create or replace function public.is_store_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') in ('owner','staff'), false);
$$;

create policy "profiles_read_self_or_admin" on public.profiles for select to authenticated
using (id = (select auth.uid()) or public.is_store_admin());
create policy "profiles_update_self_limited" on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "products_public_active_read" on public.products for select to anon, authenticated
using (is_active = true or public.is_store_admin());
create policy "products_admin_write" on public.products for all to authenticated
using (public.is_store_admin()) with check (public.is_store_admin());
create policy "influencers_read_own_or_admin" on public.influencers for select to authenticated
using (user_id = (select auth.uid()) or public.is_store_admin());
create policy "influencers_admin_write" on public.influencers for all to authenticated
using (public.is_store_admin()) with check (public.is_store_admin());
create policy "coupons_admin_only" on public.coupons for all to authenticated
using (public.is_store_admin()) with check (public.is_store_admin());
create policy "orders_read_owner_or_admin" on public.orders for select to authenticated
using (user_id = (select auth.uid()) or public.is_store_admin());
create policy "orders_create_own_pending" on public.orders for insert to authenticated
with check (user_id = (select auth.uid()) and payment_status = 'pending' and order_status = 'awaiting_payment');
create policy "orders_admin_update" on public.orders for update to authenticated
using (public.is_store_admin()) with check (public.is_store_admin());
create policy "commissions_read_influencer_or_admin" on public.commissions for select to authenticated
using (exists (select 1 from public.influencers i where i.id = influencer_id and i.user_id = (select auth.uid())) or public.is_store_admin());
create policy "commissions_admin_write" on public.commissions for all to authenticated
using (public.is_store_admin()) with check (public.is_store_admin());
create policy "audit_logs_admin_read" on public.audit_logs for select to authenticated
using (public.is_store_admin());
create policy "audit_logs_admin_insert" on public.audit_logs for insert to authenticated
with check (public.is_store_admin());

-- Security notes:
-- 1) Do NOT let clients calculate trusted prices/discounts or set payment_status='verified'.
-- 2) Before real launch, move order creation to a server/Edge Function that loads prices and coupon rules from DB.
-- 3) Card payment must use a supported provider's hosted checkout and signed server-side webhook.
-- 4) Local transfer should remain pending until a staff member verifies it in a protected admin panel.
-- 5) Create the first owner by setting app_metadata.role='owner' through a trusted server/admin process.

-- Prevent customers from editing their own role field through profile updates.
create or replace function public.protect_profile_role() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.role is distinct from old.role and not public.is_store_admin() then
    raise exception 'Only store administrators can change profile roles';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_profile_role_trigger on public.profiles;
create trigger protect_profile_role_trigger before update on public.profiles
for each row execute function public.protect_profile_role();
