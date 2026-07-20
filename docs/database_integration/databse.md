Table profiles {
  id uuid [pk]
  role text
  full_name text
  phone text
  avatar_url text
  created_at timestamp
}

Table farms {
  id uuid [pk]
  owner_id uuid
  farm_name text
  description text
  address text
  latitude double
  longitude double
  contact_number text
  status text
  created_at timestamp
  updated_at timestamp
}

Table tasks {
  id uuid [pk]
  farmer_id uuid
  title text
  description text
  due_date timestamp
  priority text
  status text
  created_at timestamp
}

Table nutrient_logs {
  id uuid [pk]
  farm_id uuid
  nutrient_name text
  amount decimal
  notes text
  applied_at timestamp
}

Table issue_reports {
  id uuid [pk]
  farm_id uuid
  reporter_id uuid
  title text
  description text
  image_url text
  status text
  admin_notes text
  created_at timestamp
}

Table pest_catalog {
  id uuid [pk]
  name text
  symptoms text
  causes text
  solution text
  image_url text
}

Table products {
  id uuid [pk]
  farmer_id uuid
  product_name text
  description text
  price decimal
  stock int
  image_url text
  available boolean
  created_at timestamp
}

Table orders {
  id uuid [pk]
  buyer_id uuid
  farmer_id uuid
  total decimal
  status text
  created_at timestamp
}

Table order_items {
  id uuid [pk]
  order_id uuid
  product_id uuid
  quantity int
  subtotal decimal
}

Table batch_pools {
  id uuid [pk]
  title text
  target_quantity decimal
  current_quantity decimal
  deadline date
  status text
}

Table batch_members {
  id uuid [pk]
  batch_id uuid
  farmer_id uuid
  quantity decimal
}

Table forum_posts {
  id uuid [pk]
  author_id uuid
  title text
  content text
  created_at timestamp
}

Table forum_comments {
  id uuid [pk]
  post_id uuid
  author_id uuid
  content text
  created_at timestamp
}

Table notifications {
  id uuid [pk]
  user_id uuid
  title text
  message text
  is_read boolean
  created_at timestamp
}

Table farm_images {
  id uuid [pk]
  farm_id uuid
  image_url text
  created_at timestamp
}

Ref: farms.owner_id > profiles.id

Ref: tasks.farmer_id > profiles.id

Ref: nutrient_logs.farm_id > farms.id

Ref: issue_reports.farm_id > farms.id
Ref: issue_reports.reporter_id > profiles.id

Ref: products.farmer_id > profiles.id

Ref: orders.buyer_id > profiles.id
Ref: orders.farmer_id > profiles.id

Ref: order_items.order_id > orders.id
Ref: order_items.product_id > products.id

Ref: batch_members.batch_id > batch_pools.id
Ref: batch_members.farmer_id > profiles.id

Ref: forum_posts.author_id > profiles.id

Ref: forum_comments.post_id > forum_posts.id
Ref: forum_comments.author_id > profiles.id

Ref: notifications.user_id > profiles.id

Ref: farm_images.farm_id > farms.id. here is the table of the forum related