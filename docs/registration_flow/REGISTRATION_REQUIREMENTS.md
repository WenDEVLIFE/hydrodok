# Registration & Onboarding Requirements

## Overview

Three user roles with tiered registration requirements:
- **Farmer** — provides farm details and optional verification
- **Consumer** — basic info, delivery address set post-signup
- **Admin** — created externally by the platform owner

---

## Registration Form (shared across roles)

| Field              | Farmer     | Consumer   | Admin      |
| ------------------ | ---------- | ---------- | ---------- |
| Full Name          | ✅ required | ✅ required | ✅ required |
| Email              | ✅ required | ✅ required | ✅ required |
| Password           | ✅ required | ✅ required | ✅ required |
| Confirm Password   | ✅ required | ✅ required | ✅ required |
| Role               | ✅ Farmer  | ✅ Consumer | ✅ Admin   |
| Contact Number     | ✅ required | ✅ required | ✅ required |

---

## Role-Specific Fields (registration step)

Collected **during registration** so the profile is seeded right away.

| Field                      | Farmer       | Consumer |
| -------------------------- | ------------ | -------- |
| Farm / Business Name       | ✅ required  | ❌       |
| Farm Location (address)    | ✅ required  | ❌       |
| Farm Location (coordinates)| ✅ optional  | ❌       |
| Primary Produce Type       | ✅ required  | ❌       |
| Farm Description / Bio     | ✅ optional  | ❌       |
| Farm Photo                 | ✅ optional  | ❌       |
| Delivery Address           | ❌           | ✅ optional (can set later via onboarding) |
| Profile Photo              | ✅ optional  | ✅ optional |

> **Admin** — no additional fields; accounts created internally.

---

## Document Verification (Farmer only)

Farmers may optionally upload a verification document to earn a **Verified Farmer** badge.

| Document Type | Status |
|---|---|
| DTI / SEC Registration | optional |
| Barangay Clearance | optional |
| Farm Photo (geotagged) | optional |

**Verification states:**
- `unverified` — default after signup
- `pending` — document submitted, awaiting review
- `verified` — approved by admin; shows "Verified" badge on profile
- `rejected` — document did not pass; farmer can resubmit

> Verification is **not a blocker** — farmers can start listing products and managing their farm immediately. The badge is a trust signal for consumers.

---

## Post-Registration Onboarding

After the user signs up and logs in for the first time (`onboarding_completed = false`), prompt them to complete role-specific setup **before** entering the main app.

### Consumer Onboarding

1. Welcome screen → "Set up your delivery address"
2. Address form (text + optional MapTiler pin)
3. Optional: profile photo
4. Set `profiles.onboarding_completed = true`
5. Done → redirect to marketplace

### Farmer Onboarding

1. Welcome screen → "Set up your farm"
2. Farm name + location
3. Primary produce type (multi-select)
4. Farm photo (optional)
5. Optional: verification document upload
6. Set `profiles.onboarding_completed = true`
7. Done → redirect to farm dashboard

---

## Database Migration

### `profiles` table — add columns

```sql
-- The table already exists with: id, role, full_name, phone, avatar_url, created_at

-- Rename phone → contact_number for consistency, or just add as alias
alter table profiles add column if not exists contact_number text;

-- Track whether the user completed post-reg onboarding
alter table profiles add column if not exists onboarding_completed boolean not null default false;
```

### `farms` table — add columns

The table already exists with: `id, owner_id, farm_name, description, address, latitude, longitude, contact_number, status, created_at, updated_at`

```sql
-- Existing columns already cover:
--   farm_name     ↔ RegisterScreen "Farm / Business Name"
--   address       ↔ RegisterScreen "Farm Location"
--   latitude/longitude ↔ optional MapTiler coordinates
--   description   ↔ Farm Description / Bio

-- Add produce_types (array so farmers can list multiple crops)
alter table farms add column if not exists produce_types text[] not null default '{}';

-- Add verification columns for the Verified Farmer badge
alter table farms add column if not exists verification_status text not null default 'unverified'
  check (verification_status in ('unverified', 'pending', 'verified', 'rejected'));

alter table farms add column if not exists verification_doc_url text;
```

### Delivery addresses (Consumer)

For now, Consumer delivery addresses can be stored in a new table or as a JSONB column in `profiles`. A separate table gives more flexibility:

```sql
create table if not exists delivery_addresses (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  label text not null default 'Home',
  address text not null,
  latitude double precision,
  longitude double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
```

---

## UI ↔ Database Field Mapping

| UI Label (RegisterScreen)    | DB Table / Column        | Status          |
| ---------------------------- | ------------------------ | --------------- |
| Full Name                    | `profiles.full_name`     | ✅ exists       |
| Email                        | Supabase Auth email      | ✅ exists       |
| Contact Number               | `profiles.contact_number`| ⚠️ needs migration |
| Role (Farmer / Consumer)     | `profiles.role`          | ✅ exists       |
| Farm / Business Name         | `farms.farm_name`        | ✅ exists       |
| Farm Location                | `farms.address`          | ✅ exists       |
| Primary Produce Type         | `farms.produce_types`    | ⚠️ needs migration |
| Farm Description             | `farms.description`      | ✅ exists       |
| Farm Photo                   | `farm_images` table      | ✅ exists       |
| Verification Document        | `farms.verification_*`   | ⚠️ needs migration |
| Delivery Address (Consumer)  | `delivery_addresses`     | ⚠️ needs migration |
| Onboarding completed         | `profiles.onboarding_completed` | ⚠️ needs migration |

---

## UI Component Summary

| Component | Screen | Role |
|---|---|---|
| Role toggle (Farmer / Consumer) | Register | All |
| Contact number field | Register | All |
| Extended farmer fields | Register | Farmer |
| Document upload | Register | Farmer (optional) |
| Delivery address form | Onboarding | Consumer |
| Farm setup form | Onboarding | Farmer |

---

## Future Considerations

- **Admin approval flow**: when a farmer uploads a verification document, notify an admin to review.
- **Re-verification**: if a farmer's verification is rejected, allow re-upload with a reason message.
- **Multiple farms**: a single farmer account managing multiple farm sites.
- **Co-farmers**: multiple users associated with one farm.
