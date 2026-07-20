-- =============================================================================
--  Reviews table for farm ratings
--  Run this in Supabase SQL Editor.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.farm_reviews (
  id          uuid primary key default gen_random_uuid(),
  farm_id     uuid not null references public.farms(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  rating      integer not null check (rating >= 1 and rating <= 5),
  comment     text default '',
  created_at  timestamptz not null default now()
);

ALTER TABLE public.farm_reviews ENABLE ROW LEVEL SECURITY;

-- Public can read reviews
CREATE POLICY "Public read reviews"
  ON public.farm_reviews FOR select USING (true);

-- Authenticated users can create one review per farm
CREATE POLICY "Users create reviews"
  ON public.farm_reviews FOR insert
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_farm_reviews_farm_id ON public.farm_reviews(farm_id);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.farm_reviews;

-- Update farms table to cache average rating and review count
ALTER TABLE public.farms
  ADD COLUMN IF NOT EXISTS rating numeric(2,1) default 0,
  ADD COLUMN IF NOT EXISTS review_count integer default 0;

-- Function to recalculate farm rating
CREATE OR REPLACE FUNCTION public.recalculate_farm_rating(p_farm_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg numeric(2,1);
  v_count integer;
BEGIN
  SELECT avg(rating), count(*)
  INTO v_avg, v_count
  FROM public.farm_reviews
  WHERE farm_id = p_farm_id;

  UPDATE public.farms
  SET rating = coalesce(v_avg, 0),
      review_count = coalesce(v_count, 0),
      updated_at = now()
  WHERE id = p_farm_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.recalculate_farm_rating(uuid) TO authenticated;
