-- ==============================================================================
-- Migration: Fix Orders & Order Items RLS Policies
-- Execute this SQL in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ==============================================================================

-- ── 1. Orders Table RLS ───────────────────────────────────────────────────────
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on public.orders
DROP POLICY IF EXISTS "Farmers read own orders" ON public.orders;
DROP POLICY IF EXISTS "Farmers select own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers read own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers select own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers create orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Farmers update own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers update own orders" ON public.orders;

-- Create full set of RLS policies for orders
CREATE POLICY "Buyers select own orders"
  ON public.orders FOR SELECT
  USING (auth.uid() = buyer_id);

CREATE POLICY "Farmers select own orders"
  ON public.orders FOR SELECT
  USING (auth.uid() = farmer_id);

CREATE POLICY "Buyers insert own orders"
  ON public.orders FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Farmers update own orders"
  ON public.orders FOR UPDATE
  USING (auth.uid() = farmer_id);

CREATE POLICY "Buyers update own orders"
  ON public.orders FOR UPDATE
  USING (auth.uid() = buyer_id);

-- ── 2. Order Items Table RLS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  subtotal numeric(10,2),
  CONSTRAINT order_items_pkey PRIMARY KEY (id)
);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on public.order_items
DROP POLICY IF EXISTS "Farmers select order items" ON public.order_items;
DROP POLICY IF EXISTS "Buyers select order items" ON public.order_items;
DROP POLICY IF EXISTS "Buyers insert order items" ON public.order_items;

CREATE POLICY "Farmers select order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.farmer_id = auth.uid()
    )
  );

CREATE POLICY "Buyers select order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.buyer_id = auth.uid()
    )
  );

CREATE POLICY "Buyers insert order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.buyer_id = auth.uid()
    )
  );

-- ── 3. Grant Table Permissions ───────────────────────────────────────────────
GRANT ALL ON TABLE public.orders TO authenticated, service_role;
GRANT ALL ON TABLE public.order_items TO authenticated, service_role;

-- ── 4. Create Indexes for High Performance ────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_farmer_id ON public.orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
