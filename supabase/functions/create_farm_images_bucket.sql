-- =============================================================================
--  Migration: Create farm-images storage bucket and add columns to farms table
--  Run this in your Supabase SQL Editor.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
--  1. Create farm-images storage bucket (public, like avatars)
-- ─────────────────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('farm-images', 'farm-images', true)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────────────────────
--  2. RLS policies for farm-images storage bucket
--     public SELECT, authenticated INSERT/UPDATE/DELETE scoped to own folder
-- ─────────────────────────────────────────────────────────────────────────────

drop policy if exists "Farm images are publicly viewable" on storage.objects;
create policy "Farm images are publicly viewable"
  on storage.objects for select
  using (bucket_id = 'farm-images');

drop policy if exists "Farmers can upload farm images" on storage.objects;
create policy "Farmers can upload farm images"
  on storage.objects for insert
  with check (
    bucket_id = 'farm-images'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Farmers can update own farm images" on storage.objects;
create policy "Farmers can update own farm images"
  on storage.objects for update
  using (
    bucket_id = 'farm-images'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Farmers can delete own farm images" on storage.objects;
create policy "Farmers can delete own farm images"
  on storage.objects for delete
  using (
    bucket_id = 'farm-images'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─────────────────────────────────────────────────────────────────────────────
--  3. Add columns to farms table
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.farms
  add column if not exists description text,
  add column if not exists photo_url text,
  add column if not exists verification_status text default 'unverified',
  add column if not exists verification_doc_url text,
  add column if not exists updated_at timestamptz default now();

-- ─────────────────────────────────────────────────────────────────────────────
--  4. INSERT policy for farms (needed for onboarding Step 1 where the
--     farm is created directly from the client, not via the old RPC function)
-- ─────────────────────────────────────────────────────────────────────────────

drop policy if exists "Farmers can create their own farm" on public.farms;
create policy "Farmers can create their own farm"
  on public.farms for insert
  with check (auth.uid() = owner_id);
