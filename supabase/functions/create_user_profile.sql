-- =============================================================================
--  Database functions & RLS Policies for HydroDok
--  Run this script in your Supabase SQL Editor.
-- =============================================================================

-- Ensure required columns exist on tables
alter table public.farms
  add column if not exists rejection_reason text;

alter table public.farms
  add column if not exists status text default 'active';

alter table public.farms
  add column if not exists verification_status text default 'unverified';

alter table public.farms
  add column if not exists verification_doc_url text;

alter table public.profiles
  add column if not exists onboarding_completed boolean default false;

-- ─────────────────────────────────────────────────────────────────────────────
--  1. Helper function: is_admin()
--     Checks if the current authenticated user has role = 'admin' in profiles.
--     SECURITY DEFINER avoids RLS infinite recursion.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.is_admin()
returns boolean
language sql
security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ─────────────────────────────────────────────────────────────────────────────
--  2. Create user profile (required for ALL registrations)
--     Writes to both `phone` (original) and `contact_number` (migration alias)
--     so neither column is null. Sets avatar_url = '' (UI falls back to logo.png).
-- ─────────────────────────────────────────────────────────────────────────────

-- Clean up any old function overloads first so PostgREST resolves the 4-parameter version
drop function if exists public.create_user_profile(text, text, text);
drop function if exists public.create_user_profile(text, text, text, uuid);
drop function if exists public.create_user_profile(uuid, text, text, text);

create or replace function public.create_user_profile(
  p_user_id uuid,
  p_role text,
  p_full_name text,
  p_contact_number text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id, role, full_name, phone, contact_number, avatar_url, onboarding_completed
  ) values (
    p_user_id, p_role, p_full_name, p_contact_number, p_contact_number, '', false
  )
  on conflict (id) do update set
    role = excluded.role,
    full_name = excluded.full_name,
    phone = excluded.phone,
    contact_number = excluded.contact_number;

  return p_user_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
--  3. Create farm (only for Farmer registrations)
-- ─────────────────────────────────────────────────────────────────────────────

drop function if exists public.create_farm(uuid, text, text, text[]);

create or replace function public.create_farm(
  p_owner_id uuid,
  p_farm_name text,
  p_address text,
  p_produce_types text[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_farm_id uuid;
begin
  insert into public.farms (owner_id, farm_name, address, produce_types, status, latitude, longitude)
  values (p_owner_id, p_farm_name, p_address, p_produce_types, 'active', 0, 0)
  returning id into v_farm_id;

  return v_farm_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
--  4. RLS policies for profiles
--     - Users view/update own profile
--     - Admins view/update all profiles
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users and Admins view profiles" on public.profiles;

create policy "Users and Admins view profiles"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users and Admins update profiles" on public.profiles;

create policy "Users and Admins update profiles"
  on public.profiles for update
  using (auth.uid() = id or public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
--  5. RLS policies for farms
--     - Farmers view & update own farm
--     - Consumers/public view verified published farms
--     - Admins view & update ALL farms (pending, verified, rejected, etc.)
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.farms enable row level security;

drop policy if exists "Farmers can view own farms" on public.farms;
drop policy if exists "Farmers, Consumers, and Admins view farms" on public.farms;

create policy "Farmers, Consumers, and Admins view farms"
  on public.farms for select
  using (
    auth.uid() = owner_id
    or verification_status = 'verified'
    or public.is_admin()
  );

drop policy if exists "Farmers can update own farms" on public.farms;
drop policy if exists "Farmers and Admins update farms" on public.farms;

create policy "Farmers and Admins update farms"
  on public.farms for update
  using (auth.uid() = owner_id or public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
--  6. Storage Buckets (avatars, farm-images) — public read, authenticated upload
-- ─────────────────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "Avatar images are publicly viewable" on storage.objects;
create policy "Avatar images are publicly viewable"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can update their own avatar" on storage.objects;
create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─────────────────────────────────────────────────────────────────────────────
--  7. Products Table & RLS Policies
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid references public.profiles(id) on delete cascade,
  farm_id uuid references public.farms(id) on delete cascade,
  name text not null,
  description text,
  price_per_kg numeric default 0,
  unit text default 'kg',
  stock_quantity integer default 0,
  image_url text default '',
  status text default 'pending',
  rejection_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Ensure all columns exist on products table if table was created previously
alter table public.products
  add column if not exists farmer_id uuid,
  add column if not exists farm_id uuid,
  add column if not exists name text,
  add column if not exists product_name text,
  add column if not exists description text,
  add column if not exists price_per_kg numeric default 0,
  add column if not exists price numeric default 0,
  add column if not exists unit text default 'kg',
  add column if not exists stock_quantity integer default 0,
  add column if not exists stock integer default 0,
  add column if not exists image_url text default '',
  add column if not exists status text default 'pending',
  add column if not exists rejection_reason text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.products enable row level security;

drop policy if exists "Farmers can insert own products" on public.products;
create policy "Farmers can insert own products"
  on public.products for insert
  with check (auth.uid() = farmer_id or auth.role() = 'authenticated');

drop policy if exists "Farmers, Consumers, and Admins view products" on public.products;
drop policy if exists "Anyone can view products" on public.products;
create policy "Anyone can view products"
  on public.products for select
  using (true);

drop policy if exists "Farmers and Admins update products" on public.products;
create policy "Farmers and Admins update products"
  on public.products for update
  using (auth.uid() = farmer_id or public.is_admin());

drop policy if exists "Farmers and Admins delete products" on public.products;
create policy "Farmers and Admins delete products"
  on public.products for delete
  using (auth.uid() = farmer_id or public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
--  8. Nutrient Logs Table & RLS Policies
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.nutrient_logs (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid references public.farms(id) on delete cascade,
  nutrient_name text not null,
  amount numeric default 0,
  notes text,
  created_at timestamptz default now()
);

alter table public.nutrient_logs add column if not exists created_at timestamptz default now();

alter table public.nutrient_logs enable row level security;

drop policy if exists "Farmers can insert own nutrient logs" on public.nutrient_logs;
create policy "Farmers can insert own nutrient logs"
  on public.nutrient_logs for insert
  with check (
    auth.role() = 'authenticated'
  );

drop policy if exists "Farmers and Admins view nutrient logs" on public.nutrient_logs;
create policy "Farmers and Admins view nutrient logs"
  on public.nutrient_logs for select
  using (
    auth.role() = 'authenticated'
  );

-- ─────────────────────────────────────────────────────────────────────────────
--  9. Farm Tasks Table & RLS Policies
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.farm_tasks (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid references public.farms(id) on delete cascade,
  title text not null,
  description text,
  due_date timestamptz,
  priority text default 'medium',
  status text default 'pending',
  created_at timestamptz default now()
);

alter table public.farm_tasks add column if not exists created_at timestamptz default now();

alter table public.farm_tasks enable row level security;

drop policy if exists "Farmers can insert own tasks" on public.farm_tasks;
create policy "Farmers can insert own tasks"
  on public.farm_tasks for insert
  with check (
    auth.role() = 'authenticated'
  );

drop policy if exists "Farmers and Admins view tasks" on public.farm_tasks;
create policy "Farmers and Admins view tasks"
  on public.farm_tasks for select
  using (
    auth.role() = 'authenticated'
  );

drop policy if exists "Farmers and Admins update tasks" on public.farm_tasks;
create policy "Farmers and Admins update tasks"
  on public.farm_tasks for update
  using (
    auth.role() = 'authenticated'
  );

drop policy if exists "Farmers and Admins delete tasks" on public.farm_tasks;
create policy "Farmers and Admins delete tasks"
  on public.farm_tasks for delete
  using (
    auth.role() = 'authenticated'
  );


