-- =============================================================================
--  Add order_items table and normalize order totals
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- ── Add order_items table (idempotent) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  quantity    integer not null default 1,
  subtotal    numeric(10,2) not null default 0,
  created_at  timestamptz not null default now()
);

-- ── Ensure both total and total_price columns exist on orders table ──────────
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS total numeric(10,2) default 0,
  ADD COLUMN IF NOT EXISTS total_price numeric(10,2) default 0;

-- ── Make legacy single-product columns nullable (if they exist) ───────────────
DO $$
BEGIN
  ALTER TABLE public.orders ALTER COLUMN product_id DROP NOT NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TABLE public.orders ALTER COLUMN quantity DROP NOT NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

-- ── RLS Policies for order_items ─────────────────────────────────────────────
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Farmers view order items" ON public.order_items;
CREATE POLICY "Farmers view order items"
  ON public.order_items FOR select
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.farmer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Buyers view order items" ON public.order_items;
CREATE POLICY "Buyers view order items"
  ON public.order_items FOR select
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.buyer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Buyers insert order items" ON public.order_items;
CREATE POLICY "Buyers insert order items"
  ON public.order_items FOR insert
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.buyer_id = auth.uid()
    )
  );

-- ── Allow updating total on orders for buyers/farmers ───────────────────────
DROP POLICY IF EXISTS "Buyers update own orders" ON public.orders;
CREATE POLICY "Buyers update own orders"
  ON public.orders FOR update
  USING (auth.uid() = buyer_id);

-- ── Atomic Order Creation Function ───────────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_order_with_items(uuid, uuid, text, jsonb);

CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_buyer_id uuid,
  p_farmer_id uuid,
  p_status text,
  p_items jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order_id uuid;
  v_item jsonb;
  v_total numeric(10,2) := 0;
BEGIN
  -- Create the order header using `total` column
  INSERT INTO public.orders (buyer_id, farmer_id, status, total)
  VALUES (p_buyer_id, p_farmer_id, p_status, 0)
  RETURNING id INTO v_order_id;

  -- Insert items and calculate total
  FOR v_item IN SELECT jsonb_array_elements(p_items)
  LOOP
    INSERT INTO public.order_items (order_id, product_id, quantity, subtotal)
    VALUES (
      v_order_id,
      (v_item->>'product_id')::uuid,
      (v_item->>'quantity')::int,
      (v_item->>'subtotal')::numeric
    );

    v_total := v_total + (v_item->>'subtotal')::numeric;
  END LOOP;

  -- Update order totals (set total, and total_price if column exists)
  BEGIN
    UPDATE public.orders
    SET total = v_total, total_price = v_total
    WHERE id = v_order_id;
  EXCEPTION WHEN undefined_column THEN
    UPDATE public.orders
    SET total = v_total
    WHERE id = v_order_id;
  END;

  RETURN v_order_id;
END;
$$;

-- Only authenticated users can create orders via RPC
REVOKE ALL ON FUNCTION public.create_order_with_items(uuid, uuid, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(uuid, uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(uuid, uuid, text, jsonb) TO anon;
