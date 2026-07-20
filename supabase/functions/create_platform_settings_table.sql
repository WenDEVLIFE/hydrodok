-- =============================================================================
--  Platform settings table — global system configuration for Hydrodok
--  Run this in Supabase SQL Editor.
-- =============================================================================

create table if not exists public.platform_settings (
  id                      text primary key default 'global',
  maintenance_mode        boolean default false,
  require_farm_verification boolean default true,
  enable_auto_mod         boolean default true,
  email_notifications     boolean default true,
  admin_contact_email     text default 'admin@agriconnect.ph',
  max_listings_per_farmer integer default 10,
  created_at              timestamptz default now(),
  updated_at              timestamptz default now()
);

-- Enable RLS
alter table public.platform_settings enable row level security;

-- Anyone can read the global settings (even anonymous users may need them)
drop policy if exists "Public read platform settings" on public.platform_settings;
create policy "Public read platform settings"
  on public.platform_settings for select
  using (true);

-- Only admins can insert or update settings
drop policy if exists "Admins insert platform settings" on public.platform_settings;
create policy "Admins insert platform settings"
  on public.platform_settings for insert
  with check (public.is_admin());

drop policy if exists "Admins update platform settings" on public.platform_settings;
create policy "Admins update platform settings"
  on public.platform_settings for update
  using (public.is_admin());

-- Seed the single global row if it does not exist yet
insert into public.platform_settings (id)
values ('global')
on conflict (id) do nothing;
