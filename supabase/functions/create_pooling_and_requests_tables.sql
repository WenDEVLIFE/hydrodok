-- ==============================================================================
-- Migration: Create Batch Pooling & Buyer Crop Requests Tables + RLS Policies
-- Execute this SQL in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ==============================================================================

-- ── 1. Batch Pooling Tables ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.batch_pools (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  crop_name text NOT NULL DEFAULT ''::text,
  target_quantity numeric NOT NULL DEFAULT 100,
  current_quantity numeric NOT NULL DEFAULT 0,
  target_price numeric DEFAULT 0,
  deadline date,
  status text NOT NULL DEFAULT 'Open'::text,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT batch_pools_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.batch_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  batch_id uuid REFERENCES public.batch_pools(id) ON DELETE CASCADE,
  farmer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  quantity numeric NOT NULL CHECK (quantity > 0),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT batch_members_pkey PRIMARY KEY (id)
);

ALTER TABLE public.batch_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read batch pools" ON public.batch_pools;
CREATE POLICY "Public read batch pools" ON public.batch_pools FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated create batch pools" ON public.batch_pools;
CREATE POLICY "Authenticated create batch pools" ON public.batch_pools FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated update batch pools" ON public.batch_pools;
CREATE POLICY "Authenticated update batch pools" ON public.batch_pools FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Public read batch members" ON public.batch_members;
CREATE POLICY "Public read batch members" ON public.batch_members FOR SELECT USING (true);

DROP POLICY IF EXISTS "Farmers join batch pool" ON public.batch_members;
CREATE POLICY "Farmers join batch pool" ON public.batch_members FOR INSERT WITH CHECK (auth.uid() = farmer_id);


-- ── 2. Buyer Crop Requests & Quotes ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.buyer_crop_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  buyer_name text NOT NULL DEFAULT ''::text,
  crop_name text NOT NULL,
  quantity_kg numeric NOT NULL,
  target_date date,
  buyer_budget_price numeric,
  notes text DEFAULT ''::text,
  status text NOT NULL DEFAULT 'Open'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT buyer_crop_requests_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.crop_quotes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id uuid REFERENCES public.buyer_crop_requests(id) ON DELETE CASCADE,
  farmer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  offered_price numeric NOT NULL,
  notes text DEFAULT ''::text,
  status text NOT NULL DEFAULT 'Pending'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crop_quotes_pkey PRIMARY KEY (id)
);

ALTER TABLE public.buyer_crop_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_quotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read buyer crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Public read buyer crop requests" ON public.buyer_crop_requests FOR SELECT USING (true);

DROP POLICY IF EXISTS "Buyers insert crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Buyers insert crop requests" ON public.buyer_crop_requests FOR INSERT WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Buyers update crop requests" ON public.buyer_crop_requests;
CREATE POLICY "Buyers update crop requests" ON public.buyer_crop_requests FOR UPDATE USING (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Public read crop quotes" ON public.crop_quotes;
CREATE POLICY "Public read crop quotes" ON public.crop_quotes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Farmers insert crop quotes" ON public.crop_quotes;
CREATE POLICY "Farmers insert crop quotes" ON public.crop_quotes FOR INSERT WITH CHECK (auth.uid() = farmer_id);

-- Grants
GRANT ALL ON TABLE public.batch_pools TO authenticated, service_role;
GRANT ALL ON TABLE public.batch_members TO authenticated, service_role;
GRANT ALL ON TABLE public.buyer_crop_requests TO authenticated, service_role;
GRANT ALL ON TABLE public.crop_quotes TO authenticated, service_role;
