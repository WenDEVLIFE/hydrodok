-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  role text NOT NULL CHECK (role = ANY (ARRAY['farmer'::text, 'consumer'::text, 'admin'::text])),
  full_name text NOT NULL,
  phone text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT now(),
  contact_number text,
  onboarding_completed boolean NOT NULL DEFAULT false,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.farms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  farm_name text NOT NULL,
  description text,
  address text,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  contact_number text,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  produce_types ARRAY NOT NULL DEFAULT '{}'::text[],
  verification_status text NOT NULL DEFAULT 'unverified'::text CHECK (verification_status = ANY (ARRAY['unverified'::text, 'pending'::text, 'verified'::text, 'rejected'::text])),
  verification_doc_url text,
  photo_url text,
  rejection_reason text,
  rating numeric DEFAULT 0,
  review_count integer DEFAULT 0,
  CONSTRAINT farms_pkey PRIMARY KEY (id),
  CONSTRAINT farms_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farmer_id uuid,
  title text NOT NULL,
  description text,
  due_date timestamp with time zone,
  priority text DEFAULT 'Medium'::text,
  status text DEFAULT 'Pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tasks_pkey PRIMARY KEY (id),
  CONSTRAINT tasks_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.nutrient_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farm_id uuid,
  nutrient_name text NOT NULL,
  amount numeric,
  notes text,
  applied_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT nutrient_logs_pkey PRIMARY KEY (id),
  CONSTRAINT nutrient_logs_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id)
);
CREATE TABLE public.issue_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farm_id uuid,
  reporter_id uuid,
  title text NOT NULL,
  description text,
  image_url text,
  status text DEFAULT 'Pending'::text,
  admin_notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT issue_reports_pkey PRIMARY KEY (id),
  CONSTRAINT issue_reports_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id),
  CONSTRAINT issue_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farmer_id uuid,
  product_name text NOT NULL,
  description text,
  price numeric NOT NULL,
  stock integer DEFAULT 0,
  image_url text,
  available boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  farm_id uuid,
  name text,
  price_per_kg numeric DEFAULT 0,
  unit text DEFAULT 'kg'::text,
  stock_quantity integer DEFAULT 0,
  status text DEFAULT 'pending'::text,
  rejection_reason text,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id uuid,
  farmer_id uuid,
  total numeric,
  status text DEFAULT 'Pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  total_price numeric DEFAULT 0,
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES public.profiles(id),
  CONSTRAINT orders_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.order_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid,
  product_id uuid,
  quantity integer NOT NULL,
  subtotal numeric,
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.batch_pools (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text,
  target_quantity numeric,
  current_quantity numeric DEFAULT 0,
  deadline date,
  status text DEFAULT 'Open'::text,
  CONSTRAINT batch_pools_pkey PRIMARY KEY (id)
);
CREATE TABLE public.batch_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  batch_id uuid,
  farmer_id uuid,
  quantity numeric NOT NULL,
  CONSTRAINT batch_members_pkey PRIMARY KEY (id),
  CONSTRAINT batch_members_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batch_pools(id),
  CONSTRAINT batch_members_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.forum_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  author_id uuid,
  title text,
  content text,
  created_at timestamp with time zone DEFAULT now(),
  category text DEFAULT 'selling'::text,
  status text DEFAULT 'approved'::text,
  image_url text DEFAULT ''::text,
  CONSTRAINT forum_posts_pkey PRIMARY KEY (id),
  CONSTRAINT forum_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.forum_comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  author_id uuid,
  content text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT forum_comments_pkey PRIMARY KEY (id),
  CONSTRAINT forum_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.forum_posts(id),
  CONSTRAINT forum_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text,
  message text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.farm_images (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farm_id uuid,
  image_url text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  storage_path text NOT NULL DEFAULT ''::text,
  CONSTRAINT farm_images_pkey PRIMARY KEY (id),
  CONSTRAINT farm_images_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id)
);
CREATE TABLE public.delivery_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL,
  label text NOT NULL DEFAULT 'Home'::text,
  address text NOT NULL,
  latitude double precision,
  longitude double precision,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT delivery_addresses_pkey PRIMARY KEY (id),
  CONSTRAINT delivery_addresses_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.farm_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farm_id uuid,
  title text NOT NULL,
  description text,
  due_date timestamp with time zone,
  priority text DEFAULT 'medium'::text,
  status text DEFAULT 'pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT farm_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT farm_tasks_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id)
);
CREATE TABLE public.banners (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  cta_label text DEFAULT 'Learn More'::text,
  cta_url text DEFAULT ''::text,
  status text NOT NULL DEFAULT 'live'::text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT banners_pkey PRIMARY KEY (id),
  CONSTRAINT banners_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.forum_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT forum_likes_pkey PRIMARY KEY (id),
  CONSTRAINT forum_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.forum_posts(id),
  CONSTRAINT forum_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.forum_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL,
  reporter_id uuid NOT NULL,
  reason text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT forum_reports_pkey PRIMARY KEY (id),
  CONSTRAINT forum_reports_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.forum_posts(id),
  CONSTRAINT forum_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.farm_reviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farm_id uuid NOT NULL,
  user_id uuid NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text DEFAULT ''::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT farm_reviews_pkey PRIMARY KEY (id),
  CONSTRAINT farm_reviews_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id),
  CONSTRAINT farm_reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);