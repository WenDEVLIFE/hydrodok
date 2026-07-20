-- =============================================================================
--  Banners table — admin-published pop-up announcements shown to users
--  Run this in Supabase SQL Editor.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.banners (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  content     text not null,
  cta_label   text default 'Learn More',          -- call-to-action button text
  cta_url     text default '',                    -- optional URL to open
  status      text not null default 'live',       -- live | scheduled | expired
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Enable RLS — admins manage, everyone can read live/scheduled banners
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

-- Anyone (even anon) can read banners — they're public announcements
CREATE POLICY "Public read banners"
  ON public.banners FOR select
  USING (true);

-- Only authenticated users can insert/update/delete
-- (admin role is enforced in app; RLS allows any authenticated user
--  but the admin shell only shows for role='admin')
CREATE POLICY "Authenticated insert banners"
  ON public.banners FOR insert
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated update banners"
  ON public.banners FOR update
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated delete banners"
  ON public.banners FOR delete
  USING (auth.role() = 'authenticated');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_banners_status ON public.banners(status);
CREATE INDEX IF NOT EXISTS idx_banners_created_at ON public.banners(created_at desc);

-- Enable realtime for banners table (so clients get live updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.banners;