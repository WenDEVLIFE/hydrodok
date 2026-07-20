-- ==============================================================================
-- Migration: Create and Configure public.delivery_addresses Table & RLS Policies
-- Execute this SQL in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ==============================================================================

-- 1. Create table if not exists
CREATE TABLE IF NOT EXISTS public.delivery_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL,
  label text NOT NULL DEFAULT 'Home'::text,
  address text NOT NULL,
  latitude double precision,
  longitude double precision,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT delivery_addresses_pkey PRIMARY KEY (id),
  CONSTRAINT delivery_addresses_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- 2. Enable Row-Level Security
ALTER TABLE public.delivery_addresses ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to prevent conflict errors
DROP POLICY IF EXISTS "Users select own delivery addresses" ON public.delivery_addresses;
DROP POLICY IF EXISTS "Users insert own delivery addresses" ON public.delivery_addresses;
DROP POLICY IF EXISTS "Users update own delivery addresses" ON public.delivery_addresses;
DROP POLICY IF EXISTS "Users delete own delivery addresses" ON public.delivery_addresses;

-- 4. Create RLS Policies allowing authenticated users to manage their own addresses
CREATE POLICY "Users select own delivery addresses"
  ON public.delivery_addresses FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "Users insert own delivery addresses"
  ON public.delivery_addresses FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users update own delivery addresses"
  ON public.delivery_addresses FOR UPDATE
  USING (auth.uid() = profile_id);

CREATE POLICY "Users delete own delivery addresses"
  ON public.delivery_addresses FOR DELETE
  USING (auth.uid() = profile_id);

-- Grant privileges
GRANT ALL ON TABLE public.delivery_addresses TO authenticated;
GRANT ALL ON TABLE public.delivery_addresses TO service_role;
