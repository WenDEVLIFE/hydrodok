-- =============================================================================
--  Forum RPC functions: atomic count updates
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- ── add_post_comment ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.add_post_comment(
  p_post_id uuid,
  p_user_id uuid,
  p_content text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.post_comments (post_id, user_id, content)
  VALUES (p_post_id, p_user_id, p_content);

  UPDATE public.posts
  SET comments_count = comments_count + 1,
      updated_at = now()
  WHERE id = p_post_id;
END;
$$;

-- ── add_post_like ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.add_post_like(
  p_post_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.post_likes (post_id, user_id)
  VALUES (p_post_id, p_user_id)
  ON CONFLICT (post_id, user_id) DO NOTHING;

  UPDATE public.posts
  SET likes_count = likes_count + 1,
      updated_at = now()
  WHERE id = p_post_id;
END;
$$;

-- ── remove_post_like ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.remove_post_like(
  p_post_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted boolean;
BEGIN
  DELETE FROM public.post_likes
  WHERE post_id = p_post_id AND user_id = p_user_id;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  IF v_deleted THEN
    UPDATE public.posts
    SET likes_count = greatest(0, likes_count - 1),
        updated_at = now()
    WHERE id = p_post_id;
  END IF;
END;
$$;

-- ── add_post_report ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.add_post_report(
  p_post_id uuid,
  p_reporter_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.post_reports (post_id, reporter_id, reason)
  VALUES (p_post_id, p_reporter_id, p_reason);

  UPDATE public.posts
  SET reports_count = reports_count + 1,
      updated_at = now()
  WHERE id = p_post_id;
END;
$$;

-- ── increment_post_shares ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.increment_post_shares(
  p_post_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts
  SET shares_count = shares_count + 1,
      updated_at = now()
  WHERE id = p_post_id;
END;
$$;

-- Grant execute to authenticated
GRANT EXECUTE ON FUNCTION public.add_post_comment(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_post_like(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_post_like(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_post_report(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_post_shares(uuid) TO authenticated;
