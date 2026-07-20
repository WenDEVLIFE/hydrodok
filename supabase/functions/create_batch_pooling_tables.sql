-- =============================================================================
--  Create batch pooling tables (batch_pools + batch_members)
--  Run this in Supabase SQL Editor.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.batch_pools (
  id              uuid primary key default gen_random_uuid()
);

-- Add missing columns if the table already existed without them.
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS title text not null default '';
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS crop_name text not null default '';
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS target_quantity numeric(12,2) not null default 0;
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS current_quantity numeric(12,2) not null default 0;
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS target_price numeric(12,2) default 0;
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS status text not null default 'Open';
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS created_at timestamptz not null default now();
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS updated_at timestamptz not null default now();
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS created_by uuid references auth.users(id) on delete set null;
ALTER TABLE public.batch_pools ADD COLUMN IF NOT EXISTS deadline date;

CREATE TABLE IF NOT EXISTS public.batch_members (
  id          uuid primary key default gen_random_uuid()
);

ALTER TABLE public.batch_members ADD COLUMN IF NOT EXISTS batch_id uuid not null references public.batch_pools(id) on delete cascade;
ALTER TABLE public.batch_members ADD COLUMN IF NOT EXISTS farmer_id uuid not null references auth.users(id) on delete cascade;
ALTER TABLE public.batch_members ADD COLUMN IF NOT EXISTS quantity numeric(12,2) not null default 0;
ALTER TABLE public.batch_members ADD COLUMN IF NOT EXISTS created_at timestamptz not null default now();

-- Add unique constraint if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'batch_members_batch_id_farmer_id_key'
      AND conrelid = 'public.batch_members'::regclass
  ) THEN
    ALTER TABLE public.batch_members
      ADD CONSTRAINT batch_members_batch_id_farmer_id_key
      UNIQUE (batch_id, farmer_id);
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_batch_pools_status ON public.batch_pools(status);
CREATE INDEX IF NOT EXISTS idx_batch_pools_created_by ON public.batch_pools(created_by);
CREATE INDEX IF NOT EXISTS idx_batch_members_batch_id ON public.batch_members(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_members_farmer_id ON public.batch_members(farmer_id);

-- RLS
ALTER TABLE public.batch_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read batch pools" ON public.batch_pools;
DROP POLICY IF EXISTS "Creators manage batch pools" ON public.batch_pools;
DROP POLICY IF EXISTS "Public read batch members" ON public.batch_members;
DROP POLICY IF EXISTS "Farmers contribute to batch members" ON public.batch_members;

CREATE POLICY "Public read batch pools"
  ON public.batch_pools FOR select
  USING (true);

CREATE POLICY "Creators manage batch pools"
  ON public.batch_pools FOR all
  USING (created_by = auth.uid());

CREATE POLICY "Public read batch members"
  ON public.batch_members FOR select
  USING (true);

CREATE POLICY "Farmers contribute to batch members"
  ON public.batch_members FOR insert
  WITH CHECK (farmer_id = auth.uid());

-- Trigger to update updated_at on batch_pools
CREATE OR REPLACE FUNCTION public.update_batch_pool_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_batch_pools_updated_at ON public.batch_pools;
CREATE TRIGGER trg_batch_pools_updated_at
  BEFORE UPDATE ON public.batch_pools
  FOR EACH ROW
  EXECUTE FUNCTION public.update_batch_pool_updated_at();
