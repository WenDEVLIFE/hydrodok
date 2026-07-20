-- =============================================================================
--  Adapt existing products table + create orders table
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- ── Add missing columns to existing products table ────────────────────────
-- These are idempotent (IF NOT EXISTS) so safe to re-run.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS description text default '';

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS price_per_kg numeric(10,2) default 0;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS unit text default 'kg';

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS stock_quantity integer default 0;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS image_url text default '';

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS status text default 'pending';

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS rejection_reason text;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS updated_at timestamptz default now();

-- ── Add status index ──────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_farmer_id ON public.products(farmer_id);

-- ── Orders table ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
  id          uuid primary key default gen_random_uuid(),
  buyer_id    uuid not null references auth.users(id) on delete cascade,
  farmer_id   uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  quantity    integer not null default 1,
  total_price numeric(10,2) not null default 0,
  status      text not null default 'pending',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── Products RLS (recreate policies safely) ───────────────────────────────
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Farmers read own products" ON public.products;
DROP POLICY IF EXISTS "Farmers insert own products" ON public.products;
DROP POLICY IF EXISTS "Farmers update own products" ON public.products;
DROP POLICY IF EXISTS "Public read approved products" ON public.products;

CREATE POLICY "Farmers read own products"
  ON public.products FOR select
  USING (farmer_id = auth.uid());

CREATE POLICY "Farmers insert own products"
  ON public.products FOR insert
  WITH CHECK (farmer_id = auth.uid());

CREATE POLICY "Farmers update own products"
  ON public.products FOR update
  USING (farmer_id = auth.uid());

CREATE POLICY "Public read approved products"
  ON public.products FOR select
  USING (status = 'approved');

-- ── Orders RLS ────────────────────────────────────────────────────────────
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Farmers read own orders"
  ON public.orders FOR select
  USING (farmer_id = auth.uid());

CREATE POLICY "Farmers update own orders"
  ON public.orders FOR update
  USING (farmer_id = auth.uid());

CREATE POLICY "Buyers read own orders"
  ON public.orders FOR select
  USING (buyer_id = auth.uid());

CREATE POLICY "Buyers create orders"
  ON public.orders FOR insert
  WITH CHECK (buyer_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_orders_farmer_id ON public.orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
