# SUPABASE.md

# Supabase Architecture

HydroDok uses **Supabase** as its Backend-as-a-Service (BaaS), providing authentication, PostgreSQL database, realtime synchronization, object storage, and serverless edge functions.

---

# Tech Stack

- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Supabase Realtime
- Supabase Edge Functions
- Row Level Security (RLS)

---

# Project Structure

```
supabase/
├── migrations/
├── seed.sql
├── functions/
│   ├── notifications/
│   ├── reminders/
│   ├── marketplace/
│   └── analytics/
├── policies/
├── storage/
└── config.toml
```

---

# Authentication

Authentication is handled using **Supabase Auth**.

Supported login methods:

- Email & Password
- Password Reset
- Session Refresh
- Secure JWT Authentication

Roles:

- Farmer
- Consumer
- Administrator

---

# Database

Database Engine:

- PostgreSQL

Primary schema:

```
public
```

---

# Database Tables

## profiles

Stores user information.

Fields

- id
- role (farmer | consumer | admin)
- full_name
- phone
- avatar_url
- contact_number (added by migration — alias for phone)
- onboarding_completed (added by migration — defaults to false)
- created_at

---

## farms

Hydroponic farm information.

Fields

- id
- owner_id
- farm_name
- description
- address
- latitude
- longitude
- contact_number
- produce_types (added by migration — text[], e.g. {"Lettuce","Tomatoes"})
- verification_status (added by migration — unverified | pending | verified | rejected)
- verification_doc_url (added by migration)
- status (active | inactive)
- created_at
- updated_at

---

## delivery_addresses

Consumer delivery addresses. Created during post-registration onboarding.

Fields

- id
- profile_id
- label (default: "Home")
- address
- latitude
- longitude
- is_default
- created_at

---

## tasks

Daily farming schedules.

Fields

- id
- farmer_id
- title
- description
- due_date
- priority
- status
- created_at

Status

- Pending
- Ongoing
- Completed

---

## nutrient_logs

Records nutrient applications.

Fields

- id
- farm_id
- nutrient_name
- amount
- notes
- applied_at

---

## issue_reports

Problem reports submitted by farmers.

Fields

- id
- farm_id
- reporter_id
- title
- description
- image_url
- status
- admin_notes
- created_at

Status

- Pending
- Under Review
- Resolved

---

## pest_catalog

Reference information.

Fields

- id
- name
- symptoms
- causes
- solution
- image_url

---

## products

Marketplace listings.

Fields

- id
- farmer_id
- product_name
- description
- price
- stock
- image_url
- available

---

## orders

Marketplace transactions.

Fields

- id
- buyer_id
- farmer_id
- status
- total
- created_at

Status

- Pending
- Accepted
- Completed
- Cancelled

---

## order_items

Fields

- id
- order_id
- product_id
- quantity
- subtotal

---

## batch_pools

Harvest pooling.

Fields

- id
- title
- target_quantity
- current_quantity
- deadline
- status

---

## batch_members

Fields

- id
- batch_id
- farmer_id
- quantity

---

## forum_posts

Community discussions.

Fields

- id
- author_id
- title
- content
- created_at

---

## forum_comments

Fields

- id
- post_id
- author_id
- content
- created_at

---

## notifications

User notifications.

Fields

- id
- user_id
- title
- message
- read
- created_at

---

# Relationships

```
profiles
    │
    ├── farms
    ├── delivery_addresses
    ├── tasks
    ├── products
    ├── issue_reports
    ├── forum_posts
    └── notifications

farms
    ├── nutrient_logs
    ├── issue_reports
    └── batch_pools

products
    └── order_items

orders
    └── order_items

forum_posts
    └── forum_comments
```

---

# Storage Buckets

## avatars

Stores profile pictures.

---

## issue-images

Stores issue report photos.

---

## product-images

Stores marketplace product images.

---

## pest-images

Stores pest catalog images.

---

## farm-images

Stores farm photos.

---

# Realtime

Realtime subscriptions are used for:

- Notifications
- Marketplace updates
- New issue reports
- Community forum updates
- Order status changes
- Task updates

---

# Row Level Security (RLS)

Enabled on every table.

Policies include:

Farmer

- Access own farms
- Manage own products
- View own tasks
- Submit issue reports
- Join batch pools

Consumer

- View marketplace
- Place orders
- Manage own orders

Administrator

- Full system management
- Moderate community
- Manage reports
- Manage marketplace

---

# Edge Functions

Server-side logic.

Examples:

## reminders

Automatically send overdue task reminders.

---

## notifications

Broadcast important announcements.

---

## analytics

Generate dashboard statistics.

---

## marketplace

Validate product listings.

---

# Security

- Row Level Security enabled
- JWT Authentication
- Secure Storage URLs
- HTTPS only
- Database Constraints
- Foreign Keys
- Cascade Deletes where appropriate

---

# Indexes

Recommended indexes:

- profiles(role)
- farms(owner_id)
- farms(verification_status)
- delivery_addresses(profile_id)
- tasks(farmer_id)
- tasks(status)
- issue_reports(status)
- products(farmer_id)
- orders(buyer_id)
- forum_posts(author_id)

---

# Backup Strategy

- Daily database backup
- Weekly storage backup
- Migration version control
- GitHub repository backup

---

# Development Workflow

1. Create migration
2. Update schema
3. Apply RLS policies
4. Test locally
5. Deploy to Supabase
6. Verify Edge Functions
7. Release mobile update

---

# Environment Variables

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
MAPTILER_API_KEY=
```

---

# Flutter Packages

Recommended packages:

```
supabase_flutter
flutter_riverpod
go_router
freezed
json_annotation
flutter_dotenv
image_picker
cached_network_image
geolocator
flutter_map
latlong2
```

---

# Future Improvements

- Offline synchronization
- Full-text search
- Database views
- Materialized views
- Audit logs
- Soft deletes
- Scheduled Edge Functions
- Analytics dashboard
- Push notifications via FCM
- AI-powered farm recommendations

---

# Summary

Supabase serves as the centralized backend for HydroDok, managing authentication, PostgreSQL data storage, realtime synchronization, secure file storage, and server-side business logic. Combined with Flutter and MapTiler, it provides a scalable, secure, and modern architecture for hydroponic farm management.