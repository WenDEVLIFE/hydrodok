-- =============================================================================
--  Admin user creation RPC
--  Allows an existing admin to create a new admin account from the admin panel.
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- Make sure required extensions are available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Ensure the profiles table can store the admin email for display
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;

CREATE OR REPLACE FUNCTION public.create_admin_user(
  email text,
  password text,
  full_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_instance_id uuid;
BEGIN
  -- Only existing admins can call this function
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can create admin users';
  END IF;

  -- Generate a fresh user id
  v_user_id := extensions.uuid_generate_v4();

  -- Fetch instance_id from existing auth.users or default
  SELECT instance_id INTO v_instance_id FROM auth.users LIMIT 1;
  IF v_instance_id IS NULL THEN
    v_instance_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;

  -- 1. Insert into auth.users (email_confirmed_at automatically satisfies confirmed_at)
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
  ) VALUES (
    v_instance_id,
    v_user_id,
    'authenticated',
    'authenticated',
    lower(email),
    extensions.crypt(password, extensions.gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', full_name),
    false
  );

  -- 2. Insert into auth.identities (REQUIRED by Supabase GoTrue Auth)
  BEGIN
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at,
      provider_id
    ) VALUES (
      v_user_id,
      v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', lower(email)),
      'email',
      now(),
      now(),
      now(),
      v_user_id::text
    );
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', lower(email)),
      'email',
      now(),
      now(),
      now()
    );
  END;

  -- 3. Create public.profiles record
  INSERT INTO public.profiles (
    id, role, full_name, email, onboarding_completed, avatar_url
  ) VALUES (
    v_user_id, 'admin', full_name, lower(email), true, ''
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    onboarding_completed = true;

  RETURN v_user_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.create_admin_user(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_admin_user(text, text, text) TO service_role;
