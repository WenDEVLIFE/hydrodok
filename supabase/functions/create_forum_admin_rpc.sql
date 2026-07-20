-- =============================================================================
--  Admin Forum Moderation RPC functions
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- ── admin_delete_post ───────────────────────────────────────────────────
-- Deletes a post and all related comments, likes, reports (CASCADE).
CREATE OR REPLACE FUNCTION public.admin_delete_post(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.posts WHERE id = p_post_id;
END;
$$;

-- ── admin_dismiss_reports ───────────────────────────────────────────────
-- Clears all reports for a post and resets reports_count to 0.
CREATE OR REPLACE FUNCTION public.admin_dismiss_reports(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.post_reports WHERE post_id = p_post_id;

  UPDATE public.posts
  SET reports_count = 0,
      updated_at = now()
  WHERE id = p_post_id;
END;
$$;

-- Grant execute to authenticated users (admin role is enforced in app UI)
GRANT EXECUTE ON FUNCTION public.admin_delete_post(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_dismiss_reports(uuid) TO authenticated;
