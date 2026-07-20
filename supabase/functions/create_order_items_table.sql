-- ==============================================================================
-- Migration: Order Items Table and Atomic Order Creation RPC
-- Execute this SQL in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
-- ==============================================================================

-- ── Create order_items table ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  subtotal numeric(10,2),
  CONSTRAINT order_items_pkey PRIMARY KEY (id)
);

-- ── Enable RLS ────────────────────────────────────────────────────────────────
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ── RLS Policies ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Farmers select order items" ON public.order_items;
CREATE POLICY "Farmers select order items"
  ON public.order_items FOR select
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.farmer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Buyers select order items" ON public.order_items;
CREATE POLICY "Buyers select order items"
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

-- ── Add order total column if not present (matches database.md) ─────────────
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total numeric(10,2) DEFAULT 0;

-- ── Atomic Order Creation Functions ───────────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_order_with_items(uuid, uuid, text, jsonb, text);
DROP FUNCTION IF EXISTS public.create_order_with_items(uuid, uuid, text, jsonb);

-- Atomic order creation function (aligned with database.md)
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
  -- Create the order header using only columns from database.md
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

  -- Update order total
  UPDATE public.orders
  SET total = v_total
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.create_order_with_items(uuid, uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(uuid, uuid, text, jsonb) TO service_role;
