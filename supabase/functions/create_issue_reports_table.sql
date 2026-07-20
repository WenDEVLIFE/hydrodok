-- =============================================================================
--  Issue Reports table — problem reports submitted by farmers to support & admin
--  Run this in Supabase SQL Editor.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.issue_reports (
  id           uuid primary key default gen_random_uuid(),
  farm_id      uuid references public.farms(id) on delete cascade,
  reporter_id  uuid not null references auth.users(id) on delete cascade,
  category     text not null default 'General Support',
  title        text not null,
  description  text not null,
  priority     text not null default 'medium',  -- low | medium | high
  image_url    text default '',
  status       text not null default 'under_review',  -- under_review | in_progress | resolved | closed
  admin_notes  text default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Enable RLS
ALTER TABLE public.issue_reports ENABLE ROW LEVEL SECURITY;

-- Policies: users read/create their reports, admins read/update all
DROP POLICY IF EXISTS "Public select issue_reports" ON public.issue_reports;
CREATE POLICY "Public select issue_reports"
  ON public.issue_reports FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Auth insert issue_reports" ON public.issue_reports;
CREATE POLICY "Auth insert issue_reports"
  ON public.issue_reports FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth update issue_reports" ON public.issue_reports;
CREATE POLICY "Auth update issue_reports"
  ON public.issue_reports FOR UPDATE
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth delete issue_reports" ON public.issue_reports;
CREATE POLICY "Auth delete issue_reports"
  ON public.issue_reports FOR DELETE
  USING (auth.role() = 'authenticated');

-- Indexes & Realtime
CREATE INDEX IF NOT EXISTS idx_issue_reports_reporter ON public.issue_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_issue_reports_status ON public.issue_reports(status);
CREATE INDEX IF NOT EXISTS idx_issue_reports_created_at ON public.issue_reports(created_at desc);

ALTER PUBLICATION supabase_realtime ADD TABLE public.issue_reports;
