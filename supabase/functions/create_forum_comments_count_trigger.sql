-- =============================================================================
--  Keep forum_posts.comments_count in sync with forum_comments
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- Ensure the counter column exists
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS comments_count integer not null default 0;

-- Function: increment comment count
CREATE OR REPLACE FUNCTION public.increment_forum_comments_count()
RETURNS trigger AS $$
BEGIN
  UPDATE public.forum_posts
  SET comments_count = comments_count + 1,
      updated_at = now()
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: decrement comment count
CREATE OR REPLACE FUNCTION public.decrement_forum_comments_count()
RETURNS trigger AS $$
BEGIN
  UPDATE public.forum_posts
  SET comments_count = greatest(0, comments_count - 1),
      updated_at = now()
  WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers
DROP TRIGGER IF EXISTS trg_forum_comments_insert ON public.forum_comments;
CREATE TRIGGER trg_forum_comments_insert
  AFTER INSERT ON public.forum_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_forum_comments_count();

DROP TRIGGER IF EXISTS trg_forum_comments_delete ON public.forum_comments;
CREATE TRIGGER trg_forum_comments_delete
  AFTER DELETE ON public.forum_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.decrement_forum_comments_count();

-- Backfill existing counts (optional but recommended)
UPDATE public.forum_posts p
SET comments_count = (
  SELECT count(*)::int FROM public.forum_comments c WHERE c.post_id = p.id
);
