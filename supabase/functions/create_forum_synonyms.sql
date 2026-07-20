-- =============================================================================
--  Forum Synonyms / Aliases Script
--  Run this in Supabase SQL Editor to support both table naming conventions:
--  - forum_posts / posts
--  - forum_comments / post_comments
--  - forum_likes / post_likes
--  - forum_reports / post_reports
-- =============================================================================

-- 1. Create tables if using forum_ prefix
CREATE TABLE IF NOT EXISTS public.forum_posts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  category       text not null default 'selling',  -- selling | qna | tips
  content        text not null,
  image_url      text default '',
  likes_count    int not null default 0,
  comments_count int not null default 0,
  reports_count  int not null default 0,
  status         text not null default 'pending',  -- pending | approved | rejected
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

CREATE TABLE IF NOT EXISTS public.forum_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.forum_posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now()
);

CREATE TABLE IF NOT EXISTS public.forum_likes (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.forum_posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.forum_reports (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.forum_posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  reason     text not null,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

-- Enable RLS
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reports ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Public select forum_posts" ON public.forum_posts;
CREATE POLICY "Public select forum_posts" ON public.forum_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_posts" ON public.forum_posts;
CREATE POLICY "Auth insert forum_posts" ON public.forum_posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth update forum_posts" ON public.forum_posts;
CREATE POLICY "Auth update forum_posts" ON public.forum_posts FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public select forum_comments" ON public.forum_comments;
CREATE POLICY "Public select forum_comments" ON public.forum_comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_comments" ON public.forum_comments;
CREATE POLICY "Auth insert forum_comments" ON public.forum_comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public select forum_likes" ON public.forum_likes;
CREATE POLICY "Public select forum_likes" ON public.forum_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Auth insert forum_likes" ON public.forum_likes;
CREATE POLICY "Auth insert forum_likes" ON public.forum_likes FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete forum_likes" ON public.forum_likes;
CREATE POLICY "Auth delete forum_likes" ON public.forum_likes FOR DELETE USING (user_id = auth.uid());
