-- =============================================================================
--  Database functions to create user profiles & farms from the client,
--  bypassing RLS via SECURITY DEFINER.
-- =============================================================================

-- Run this in your Supabase SQL Editor.

-- ─────────────────────────────────────────────────────────────────────────────
--  1. Create user profile (required for ALL registrations)
--     Writes to both `phone` (original) and `contact_number` (migration alias)
--     so neither column is null. Sets avatar_url = '' (UI falls back to logo.png).
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function create_user_profile(
  p_role text,
  p_full_name text,
  p_contact_number text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (
    id, role, full_name, phone, contact_number, avatar_url, onboarding_completed
  ) values (
    v_user_id, p_role, p_full_name, p_contact_number, p_contact_number, '', false
  );

  return v_user_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
--  2. Create farm (only for Farmer registrations)
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function create_farm(
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
  values (auth.uid(), p_farm_name, p_address, p_produce_types, 'active', 0, 0)
  returning id into v_farm_id;

  return v_farm_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
--  3. RLS policies for profiles — SELECT / UPDATE own row
--     INSERT is handled by the functions above.
-- ─────────────────────────────────────────────────────────────────────────────

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- ─────────────────────────────────────────────────────────────────────────────
--  4. RLS policies for farms — SELECT / UPDATE own farm
-- ─────────────────────────────────────────────────────────────────────────────

drop policy if exists "Farmers can view own farms" on public.farms;
create policy "Farmers can view own farms"
  on public.farms for select
  using (auth.uid() = owner_id);

drop policy if exists "Farmers can update own farms" on public.farms;
create policy "Farmers can update own farms"
  on public.farms for update
  using (auth.uid() = owner_id);

-- ─────────────────────────────────────────────────────────────────────────────
--  5. avatars storage bucket — public read, authenticated upload
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
