/*
  Purpose: Add profile roles and organizer application workflows.
  Depends on: nothing. Run in Supabase SQL Editor. Safe to re-run.
*/

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role text;

ALTER TABLE public.profiles
  ALTER COLUMN role SET DEFAULT 'user';

UPDATE public.profiles
SET role = 'user'
WHERE role IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN role SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_role_check'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_role_check
      CHECK (role IN ('user', 'organizer', 'super_admin'));
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS profiles_role_idx
  ON public.profiles (role);

CREATE OR REPLACE FUNCTION public.is_organizer()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('organizer', 'super_admin')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_organizer() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_organizer() TO anon;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'super_admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO anon;

CREATE TABLE IF NOT EXISTS public.organizer_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name text NOT NULL,
  business_registration text,
  contact_phone text,
  contact_email text,
  description text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS organizer_applications_status_created_at_idx
  ON public.organizer_applications (status, created_at DESC);

CREATE INDEX IF NOT EXISTS organizer_applications_user_id_idx
  ON public.organizer_applications (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS organizer_applications_one_pending_per_user_idx
  ON public.organizer_applications (user_id)
  WHERE status = 'pending';

ALTER TABLE public.organizer_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS organizer_applications_select_own_or_admin
  ON public.organizer_applications;
CREATE POLICY organizer_applications_select_own_or_admin
  ON public.organizer_applications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_super_admin());

DROP POLICY IF EXISTS organizer_applications_insert_own
  ON public.organizer_applications;
CREATE POLICY organizer_applications_insert_own
  ON public.organizer_applications
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS organizer_applications_update_admin
  ON public.organizer_applications;
CREATE POLICY organizer_applications_update_admin
  ON public.organizer_applications
  FOR UPDATE
  TO authenticated
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

CREATE OR REPLACE FUNCTION public.approve_organizer_application(
  p_application_id uuid
)
RETURNS public.organizer_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  application_row public.organizer_applications;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can approve organizer applications'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.organizer_applications
  SET status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = NULL
  WHERE id = p_application_id
  RETURNING * INTO application_row;

  IF application_row.id IS NULL THEN
    RAISE EXCEPTION 'Organizer application % was not found', p_application_id
      USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.profiles
  SET role = 'organizer'
  WHERE id = application_row.user_id
    AND role = 'user';

  RETURN application_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_organizer_application(uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_organizer_application(
  p_application_id uuid,
  p_reason text
)
RETURNS public.organizer_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  application_row public.organizer_applications;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can reject organizer applications'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.organizer_applications
  SET status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = p_reason
  WHERE id = p_application_id
  RETURNING * INTO application_row;

  IF application_row.id IS NULL THEN
    RAISE EXCEPTION 'Organizer application % was not found', p_application_id
      USING ERRCODE = 'P0002';
  END IF;

  RETURN application_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_organizer_application(uuid, text)
  TO authenticated;
