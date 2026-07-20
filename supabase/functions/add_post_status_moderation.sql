-- =============================================================================
--  Add moderation status & RPC functions for forum_posts
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- Add status column to forum_posts
ALTER TABLE public.forum_posts
  ADD COLUMN IF NOT EXISTS status text not null default 'approved';  -- pending | approved | rejected

-- Index
CREATE INDEX IF NOT EXISTS idx_forum_posts_status ON public.forum_posts(status);

-- ── Admin moderation RPCs ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_approve_post(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.forum_posts
  SET status = 'approved'
  WHERE id = p_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_reject_post(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.forum_posts
  SET status = 'rejected'
  WHERE id = p_post_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_approve_post(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reject_post(uuid) TO authenticated;
