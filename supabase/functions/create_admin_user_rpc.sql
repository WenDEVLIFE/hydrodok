-- =============================================================================
--  Admin user creation RPC
--  Allows an existing admin to create a new admin account from the admin panel.
--  Run this in Supabase SQL Editor.
-- =============================================================================

-- Make sure required extensions are available
-- (uuid-ossp for uuid_generate_v4, pgcrypto for crypt/gen_salt)
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Ensure the profiles table can store the admin email for display
alter table public.profiles add column if not exists email text;

create or replace function public.create_admin_user(
  email text,
  password text,
  full_name text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  -- Only existing admins can call this function
  if not public.is_admin() then
    raise exception 'Only admins can create admin users';
  end if;

  -- Generate a fresh user id
  v_user_id := extensions.uuid_generate_v4();

  -- Insert the auth user. This requires postgres/service-role privileges
  -- because direct writes to auth.users are normally restricted.
  insert into auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
  ) values (
    v_user_id,
    email,
    extensions.crypt(password, extensions.gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', full_name)
  );

  -- Create (or overwrite) the public profile as an admin
  insert into public.profiles (
    id, role, full_name, email, onboarding_completed, avatar_url
  ) values (
    v_user_id, 'admin', full_name, create_admin_user.email, true, ''
  )
  on conflict (id) do update set
    role = excluded.role,
    full_name = excluded.full_name,
    email = excluded.email,
    onboarding_completed = excluded.onboarding_completed;

  return v_user_id;
end;
$$;

-- Authenticated users can execute; the function itself enforces the admin check
grant execute on function public.create_admin_user(text, text, text) to authenticated;
