-- =============================================================================
--  Delete User Account RPC Function
--  Allows admins to delete user or admin accounts completely.
--  Run this in Supabase SQL Editor.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.delete_user_account(
  target_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- 1. Security check: Only admins can call this function
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can delete user accounts.';
  END IF;

  -- 2. Prevent self-deletion while logged in
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot delete your own account while logged in.';
  END IF;

  -- 3. Delete user associated records from public tables
  -- Forum activity
  BEGIN DELETE FROM public.forum_likes WHERE user_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.forum_reports WHERE reporter_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.forum_comments WHERE author_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.forum_posts WHERE author_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;

  -- Ecommerce & Farms
  BEGIN DELETE FROM public.delivery_addresses WHERE profile_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.delivery_addresses WHERE user_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.order_items WHERE order_id IN (SELECT id FROM public.orders WHERE buyer_id = target_user_id OR farmer_id = target_user_id); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.orders WHERE buyer_id = target_user_id OR farmer_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.products WHERE farmer_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.farms WHERE owner_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;

  -- Pooling & Requests
  BEGIN DELETE FROM public.batch_members WHERE farmer_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.crop_quotes WHERE farmer_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.buyer_crop_requests WHERE buyer_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DELETE FROM public.issue_reports WHERE user_id = target_user_id; EXCEPTION WHEN OTHERS THEN NULL; END;

  -- Profile
  DELETE FROM public.profiles WHERE id = target_user_id;

  -- 4. Delete from auth.users (requires SECURITY DEFINER)
  BEGIN
    DELETE FROM auth.users WHERE id = target_user_id;
  EXCEPTION WHEN OTHERS THEN
    -- If direct auth.users deletion fails, profile deletion above still succeeded
    NULL;
  END;

  RETURN true;
END;
$$;

-- RLS policy to allow admins to delete from public.profiles
DROP POLICY IF EXISTS "Admins delete profiles" ON public.profiles;
CREATE POLICY "Admins delete profiles"
  ON public.profiles FOR DELETE
  USING (public.is_admin());

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.delete_user_account(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_account(uuid) TO service_role;
