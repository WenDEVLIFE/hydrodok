-- =============================================================================
--  Farm Images Table Setup
--  Run this in Supabase SQL Editor.
--  Based on: database.md  →  Table farm_images { id, farm_id, image_url, created_at }
--  We add storage_path column for safe storage deletion.
-- =============================================================================

-- Create table (idempotent)
CREATE TABLE IF NOT EXISTS public.farm_images (
  id           uuid primary key default gen_random_uuid(),
  farm_id      uuid not null references public.farms(id) on delete cascade,
  image_url    text not null default '',
  storage_path text not null default '',
  created_at   timestamptz not null default now()
);

-- Add storage_path if table already exists without it
ALTER TABLE public.farm_images
  ADD COLUMN IF NOT EXISTS storage_path text not null default '';

-- Enable RLS
ALTER TABLE public.farm_images ENABLE ROW LEVEL SECURITY;

-- Anyone can view farm images (public gallery)
CREATE POLICY "Public read farm images"
  ON public.farm_images FOR SELECT
  USING (true);

-- Only the farm owner can insert images for their farm
CREATE POLICY "Owner insert farm images"
  ON public.farm_images FOR INSERT
  WITH CHECK (
    auth.uid() = (
      SELECT owner_id FROM public.farms WHERE id = farm_id
    )
  );

-- Only the farm owner can delete their farm images
CREATE POLICY "Owner delete farm images"
  ON public.farm_images FOR DELETE
  USING (
    auth.uid() = (
      SELECT owner_id FROM public.farms WHERE id = farm_id
    )
  );

-- Index for fast lookups by farm
CREATE INDEX IF NOT EXISTS idx_farm_images_farm_id ON public.farm_images(farm_id);

-- Enable Realtime (optional)
ALTER PUBLICATION supabase_realtime ADD TABLE public.farm_images;
