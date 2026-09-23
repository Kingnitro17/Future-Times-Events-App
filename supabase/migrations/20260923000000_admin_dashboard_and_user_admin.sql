/*
  Purpose: Admin dashboard metrics, admin-wide profile visibility, and role
  management for the super admin Users page.
  Depends on: roles_and_applications migration (is_super_admin) and
  event_lifecycle migration (events.status). Run in Supabase SQL Editor.
  Safe to re-run.
*/

-- Super admins need to read every profile for the Users page, organizer name
-- lookups on the admin event lists, and signup metrics. The existing
-- "Authenticated users can view their own profile" policy stays in place; RLS
-- grants access when ANY policy passes.
DROP POLICY IF EXISTS "Super admins can view all profiles" ON public.profiles;
CREATE POLICY "Super admins can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public.is_super_admin());

CREATE OR REPLACE FUNCTION public.admin_dashboard_kpis()
RETURNS json
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can read dashboard metrics'
      USING ERRCODE = '42501';
  END IF;

  RETURN (
    SELECT json_build_object(
      'total_events', (SELECT count(*) FROM public.events),
      'published_events', (
        SELECT count(*) FROM public.events
        WHERE status IN ('published', 'live', 'ended')
      ),
      'pending_reviews', (
        SELECT count(*) FROM public.events WHERE status = 'pending_review'
      ),
      'total_users', (SELECT count(*) FROM public.profiles),
      'total_organizers', (
        SELECT count(*) FROM public.profiles
        WHERE role IN ('organizer', 'super_admin')
      ),
      'tickets_sold', (
        SELECT count(*) FROM public.tickets
        WHERE status IN ('issued', 'checked_in')
      ),
      'revenue', (
        SELECT coalesce(sum(tt.price), 0)
        FROM public.tickets t
        JOIN public.ticket_types tt ON tt.id = t.ticket_type_id
        WHERE t.status IN ('issued', 'checked_in')
      )
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_dashboard_kpis() TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_user_role(
  p_user_id uuid,
  p_role text
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  profile_row public.profiles;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can change user roles'
      USING ERRCODE = '42501';
  END IF;

  IF p_role NOT IN ('user', 'organizer', 'super_admin') THEN
    RAISE EXCEPTION 'Unsupported role %', p_role USING ERRCODE = '22023';
  END IF;

  -- Prevent an admin from removing their own super admin access and locking
  -- the team out of this dashboard.
  IF p_user_id = auth.uid() AND p_role <> 'super_admin' THEN
    RAISE EXCEPTION 'You cannot change your own super admin role'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET role = p_role
  WHERE id = p_user_id
  RETURNING * INTO profile_row;

  IF profile_row.id IS NULL THEN
    RAISE EXCEPTION 'Profile % was not found', p_user_id USING ERRCODE = 'P0002';
  END IF;

  RETURN profile_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_set_user_role(uuid, text) TO authenticated;
