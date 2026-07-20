-- =============================================================================
--  Clean broken test admin accounts
--  Run this in Supabase SQL Editor to remove broken test admin users before creating a new one.
-- =============================================================================

DELETE FROM auth.identities WHERE user_id IN (
  SELECT id FROM public.profiles WHERE role = 'admin' AND (email LIKE '%test%' OR email LIKE '%admin%')
);

DELETE FROM public.profiles WHERE role = 'admin' AND (email LIKE '%test%' OR email LIKE '%admin%');

DELETE FROM auth.users WHERE email LIKE '%test%' OR email LIKE '%admin%';
