-- =============================================================================
--  Community Forum Tables (Exact Schema as specified)
--  Run this script in your Supabase SQL Editor.
-- =============================================================================

-- ── 1. Create forum_posts table ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.forum_posts (
  id             uuid primary key default gen_random_uuid(),
  author_id      uuid not null references public.profiles(id) on delete cascade,
  title          text default '',
  content        text not null,
  category       text not null default 'selling',  -- selling | qna | tips
  image_url      text default '',
  likes_count    integer not null default 0,
  comments_count integer not null default 0,
  status         text not null default 'approved',  -- pending | approved | rejected
  created_at     timestamptz not null default now()
);

-- Ensure columns exist if table already exists
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS author_id uuid references public.profiles(id) on delete cascade;
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS title text default '';
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS category text default 'selling';
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS status text default 'approved';
ALTER TABLE public.forum_posts ADD COLUMN IF NOT EXISTS image_url text default '';

-- ── 2. Create forum_comments table ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.forum_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.forum_posts(id) on delete cascade,
  author_id  uuid not null references public.profiles(id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now()
);

ALTER TABLE public.forum_comments ADD COLUMN IF NOT EXISTS author_id uuid references public.profiles(id) on delete cascade;

-- ── 3. Create forum_likes table ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.forum_likes (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.forum_posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(post_id, user_id)
);

-- ── 4. Create forum_reports table ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.forum_reports (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references public.forum_posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason      text not null,
  created_at  timestamptz not null default now()
);

-- ── 5. Enable Row Level Security (RLS) ───────────────────────────────────────
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reports ENABLE ROW LEVEL SECURITY;

-- ── 6. RLS Policies ──────────────────────────────────────────────────────────

-- forum_posts
DROP POLICY IF EXISTS "Public select forum_posts" ON public.forum_posts;
CREATE POLICY "Public select forum_posts"
  ON public.forum_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_posts" ON public.forum_posts;
CREATE POLICY "Auth insert forum_posts"
  ON public.forum_posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth update forum_posts" ON public.forum_posts;
CREATE POLICY "Auth update forum_posts"
  ON public.forum_posts FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete forum_posts" ON public.forum_posts;
CREATE POLICY "Auth delete forum_posts"
  ON public.forum_posts FOR DELETE USING (auth.role() = 'authenticated');

-- forum_comments
DROP POLICY IF EXISTS "Public select forum_comments" ON public.forum_comments;
CREATE POLICY "Public select forum_comments"
  ON public.forum_comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_comments" ON public.forum_comments;
CREATE POLICY "Auth insert forum_comments"
  ON public.forum_comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete forum_comments" ON public.forum_comments;
CREATE POLICY "Auth delete forum_comments"
  ON public.forum_comments FOR DELETE USING (auth.role() = 'authenticated');

-- forum_likes
DROP POLICY IF EXISTS "Public select forum_likes" ON public.forum_likes;
CREATE POLICY "Public select forum_likes"
  ON public.forum_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_likes" ON public.forum_likes;
CREATE POLICY "Auth insert forum_likes"
  ON public.forum_likes FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete forum_likes" ON public.forum_likes;
CREATE POLICY "Auth delete forum_likes"
  ON public.forum_likes FOR DELETE USING (auth.role() = 'authenticated');

-- forum_reports
DROP POLICY IF EXISTS "Public select forum_reports" ON public.forum_reports;
CREATE POLICY "Public select forum_reports"
  ON public.forum_reports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_reports" ON public.forum_reports;
CREATE POLICY "Auth insert forum_reports"
  ON public.forum_reports FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ── 7. Indexes ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_forum_posts_author ON public.forum_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_post ON public.forum_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_author ON public.forum_comments(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_likes_post ON public.forum_likes(post_id);

-- ── 8. Realtime Enablement ───────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_likes;
