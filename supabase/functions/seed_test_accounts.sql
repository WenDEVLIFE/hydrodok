-- =============================================================================
--  Prerequisites: run these first to ensure dependencies exist
-- =============================================================================

-- Enable pgcrypto for gen_random_uuid(), crypt(), gen_salt()
create extension if not exists pgcrypto;

-- Ensure onboarding_completed column exists on profiles
alter table public.profiles
  add column if not exists onboarding_completed boolean default false;

-- =============================================================================
--  Clean up & Seed test accounts: consumer + admin
--  Run this in your Supabase SQL Editor.
--  Both accounts use the same password: TestPass123
-- =============================================================================

do $$
declare
  v_consumer_id uuid;
  v_admin_id    uuid;
begin
  -- ───────────────────────────────────────────────────────────────────────────
  -- 0. Clean up existing corrupted test accounts if present
  -- ───────────────────────────────────────────────────────────────────────────
  delete from public.profiles where id in (
    select id from auth.users where email in ('consumer@test.com', 'admin@test.com')
  );
  delete from auth.identities where user_id in (
    select id from auth.users where email in ('consumer@test.com', 'admin@test.com')
  );
  delete from auth.users where email in ('consumer@test.com', 'admin@test.com');

  -- ───────────────────────────────────────────────────────────────────────────
  -- 1. Seed consumer account (consumer@test.com / TestPass123)
  -- ───────────────────────────────────────────────────────────────────────────
  v_consumer_id := gen_random_uuid();

  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, role, aud, confirmation_sent_at,
    is_anonymous, is_sso_user
  ) values (
    v_consumer_id,
    '00000000-0000-0000-0000-000000000000',
    'consumer@test.com',
    crypt('TestPass123', gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', array['email']),
    '{}'::jsonb,
    now(), now(),
    'authenticated',
    'authenticated',
    now(),
    false,
    false
  );

  insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) values (
    v_consumer_id,
    v_consumer_id,
    format('{"sub":"%s","email":"%s"}', v_consumer_id, 'consumer@test.com')::jsonb,
    'email',
    v_consumer_id::text,
    now(),
    now(),
    now()
  );

  insert into public.profiles (
    id, role, full_name, phone, contact_number, avatar_url, onboarding_completed
  ) values (
    v_consumer_id, 'consumer', 'Test Consumer',
    '09170000001', '09170000001', '', true
  );

  raise notice 'Created consumer account: consumer@test.com / TestPass123';

  -- ───────────────────────────────────────────────────────────────────────────
  -- 2. Seed admin account (admin@test.com / TestPass123)
  -- ───────────────────────────────────────────────────────────────────────────
  v_admin_id := gen_random_uuid();

  insert into auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, role, aud, confirmation_sent_at,
    is_anonymous, is_sso_user
  ) values (
    v_admin_id,
    '00000000-0000-0000-0000-000000000000',
    'admin@test.com',
    crypt('TestPass123', gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', array['email']),
    '{}'::jsonb,
    now(), now(),
    'authenticated',
    'authenticated',
    now(),
    false,
    false
  );

  insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) values (
    v_admin_id,
    v_admin_id,
    format('{"sub":"%s","email":"%s"}', v_admin_id, 'admin@test.com')::jsonb,
    'email',
    v_admin_id::text,
    now(),
    now(),
    now()
  );

  insert into public.profiles (
    id, role, full_name, phone, contact_number, avatar_url, onboarding_completed
  ) values (
    v_admin_id, 'admin', 'Test Admin',
    '09170000002', '09170000002', '', true
  );

  raise notice 'Created admin account: admin@test.com / TestPass123';
end;
$$;
