# Farmer Onboarding Flow

## When does this appear?

Right after OTP verification — first time login only. Never shows again on subsequent logins.

```
Register → OTP → ONBOARDING → Dashboard
```

---

## Step 1 — Farm Profile

Pre-filled from registration, but the farmer can edit before confirming.

| Field | Pre-filled? | Editable? |
|---|---|---|
| Farm / Business Name | ✅ from register | ✅ |
| Farm Location | ✅ from register | ✅ |
| Primary Produce Type | ✅ from register | ✅ |
| Farm Description | ❌ blank | ✅ (optional) |
| Farm Photo | ❌ blank | ✅ (optional, upload) |

### UI Layout

```
┌─────────────────────────────┐
│  🏠 Set Up Your Farm        │
│                             │
│  Let's complete your farm   │
│  profile so buyers can      │
│  find you.                  │
│                             │
│  ┌───────────────────────┐  │
│  │ Farm / Business Name  │  │
│  │ Green Valley Farm     │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Farm Location         │  │
│  │ Brgy. San Jose, Gen.… │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Primary Produce Type  │  │
│  │ Lettuce, Tomatoes     │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ Farm Description      │  │
│  │ (optional)            │  │
│  └───────────────────────┘  │
│                             │
│  ┌───┐                      │
│  │ 📷 │ Add Farm Photo      │
│  └───┘ (optional)           │
│                             │
│  ┌───────────────────────┐  │
│  │     Continue          │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Fields

**Farm / Business Name** — required, pre-filled
- TextInputType: text
- Max 100 characters

**Farm Location** — required, pre-filled
- TextInputType: text (address)
- Can be refined later with MapTiler pin

**Primary Produce Type** — required, pre-filled
- Text field or multi-select chips
- Examples: Lettuce, Tomatoes, Pechay, Kangkong, Bell Pepper, Strawberry, Herbs

**Farm Description** — optional
- TextArea, max 500 characters
- Example: "We grow hydroponic lettuce and tomatoes using NFT systems. Pesticide-free."

**Farm Photo** — optional
- Upload from gallery or camera
- Single photo for now (may add multiple later using farm_images table)
- Stored in Supabase Storage → `farm-images` bucket

### Database Write

```sql
-- Update farms row created during registration
update farms
set
  description = $description,
  photo_url   = $uploadedPhotoUrl,
  updated_at  = now()
where owner_id = $userId;
```

---

## Step 2 — Get Verified (optional)

This is a separate optional step. The farmer can **skip** it and go straight to the dashboard.

### UI Layout

```
┌─────────────────────────────┐
│  ✅ Get Verified (Optional) │
│                             │
│  Verify your farm to earn   │
│  a badge that builds trust  │
│  with buyers.               │
│                             │
│  ┌───┐                      │
│  │ 📄 │ Upload DTI / SEC   │
│  └───┘ Registration        │
│                             │
│  ┌───┐                      │
│  │ 📄 │ Upload Barangay    │
│  └───┘ Clearance           │
│                             │
│  ┌───┐                      │
│  │ 📷 │ Upload Farm Photo  │
│  └───┘ (geotagged)         │
│                             │
│  Upload at least one        │
│  document to submit.        │
│                             │
│  ┌───────────────────────┐  │
│  │     Submit for Review │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │  Skip → Go to Dashboard│  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Flow

```
           ┌──────────┐
           │  Upload  │
           │ document │
           └────┬─────┘
                │
                ▼
         ┌──────────────┐
         │   Pending    │
         │  (admin sees │
         │  notif)      │
         └──────┬───────┘
                │
        ┌───────┴───────┐
        ▼               ▼
  ┌──────────┐   ┌──────────┐
  │ Approved │   │ Rejected │
  │ ✅ Badge │   │  See why │
  │  Active  │   │ Re-upload│
  └──────────┘   └──────────┘
```

### States

| State | What farmer sees | What happens |
|---|---|---|
| `unverified` | No badge yet | Default after onboarding skip |
| `pending` | "Verification under review" | Admin notified, waiting for review |
| `verified` | "✅ Verified Farmer" badge on profile & products | Ready to go |
| `rejected` | "Verification rejected — [reason]" + Re-upload button | Can upload new document |

### Database Write

```sql
-- If farmer submits documents
update farms
set
  verification_status    = 'pending',
  verification_doc_url   = $uploadedDocUrl,
  updated_at             = now()
where owner_id = $userId;
```

---

## After Onboarding

```sql
-- Mark onboarding as complete regardless of verification choice
update profiles
set onboarding_completed = true
where id = $userId;
```

Then redirect to **Farmer Dashboard**.

---

## Summary — Farmer vs Consumer Onboarding

| Step | Farmer | Consumer |
|---|---|---|
| OTP verification | ✅ | ✅ |
| Farm profile completion | ✅ (can edit pre-filled) | ❌ |
| Delivery address setup | ❌ | ✅ (simple form) |
| Document verification | ✅ (optional skip) | ❌ |
| Profile photo | ✅ (optional) | ✅ (optional) |
| Redirect | Farmer Dashboard | Marketplace |

---

## Future Ideas

- **Progressive verification**: start with unverified, get reminded after 7 days to upload
- **Multi-step onboarding wizard** instead of a single scrollable page
- **Farm location picker using MapTiler** in onboarding instead of just text
