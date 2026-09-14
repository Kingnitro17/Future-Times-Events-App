/*
  Purpose: Add event lifecycle states, review workflows, and organizer ticket
  check-in authorization.
  Depends on: roles_and_applications migration (uses is_super_admin). Run in
  Supabase SQL Editor. Safe to re-run.
*/

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS status text;

ALTER TABLE public.events
  ALTER COLUMN status SET DEFAULT 'draft';

UPDATE public.events
SET status = 'draft'
WHERE status IS NULL;

ALTER TABLE public.events
  ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'events_status_check'
      AND conrelid = 'public.events'::regclass
  ) THEN
    ALTER TABLE public.events
      ADD CONSTRAINT events_status_check
      CHECK (
        status IN (
          'draft',
          'pending_review',
          'approved',
          'published',
          'live',
          'ended',
          'archived',
          'rejected'
        )
      );
  END IF;
END
$$;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS submitted_at timestamptz,
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS rejection_reason text,
  ADD COLUMN IF NOT EXISTS published_at timestamptz;

CREATE INDEX IF NOT EXISTS events_status_starts_at_idx
  ON public.events (status, starts_at);

CREATE INDEX IF NOT EXISTS events_organizer_status_idx
  ON public.events (organizer_id, status);

CREATE TABLE IF NOT EXISTS public.event_review_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  reviewer_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS event_review_log_event_created_at_idx
  ON public.event_review_log (event_id, created_at DESC);

ALTER TABLE public.event_review_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS event_review_log_select_admin_or_organizer
  ON public.event_review_log;
CREATE POLICY event_review_log_select_admin_or_organizer
  ON public.event_review_log
  FOR SELECT
  TO authenticated
  USING (
    public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.events
      WHERE public.events.id = event_review_log.event_id
        AND public.events.organizer_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.submit_event_for_review(
  p_event_id uuid
)
RETURNS public.events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  event_row public.events;
BEGIN
  SELECT *
  INTO event_row
  FROM public.events
  WHERE id = p_event_id
    AND organizer_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found or not owned by the current user'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.events
  SET status = 'pending_review',
      submitted_at = now(),
      rejection_reason = NULL
  WHERE id = p_event_id
    AND status IN ('draft', 'rejected')
  RETURNING * INTO event_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event must be in draft or rejected status before submission'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.event_review_log (event_id, reviewer_id, action)
  VALUES (p_event_id, auth.uid(), 'submitted');

  RETURN event_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_event_for_review(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.approve_event(
  p_event_id uuid
)
RETURNS public.events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  event_row public.events;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can approve events'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.events
  SET status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = NULL
  WHERE id = p_event_id
    AND status = 'pending_review'
  RETURNING * INTO event_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found or is not pending review'
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.event_review_log (event_id, reviewer_id, action)
  VALUES (p_event_id, auth.uid(), 'approved');

  RETURN event_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_event(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_event(
  p_event_id uuid,
  p_reason text
)
RETURNS public.events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  event_row public.events;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can reject events'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.events
  SET status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = p_reason
  WHERE id = p_event_id
    AND status = 'pending_review'
  RETURNING * INTO event_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found or is not pending review'
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.event_review_log (event_id, reviewer_id, action, reason)
  VALUES (p_event_id, auth.uid(), 'rejected', p_reason);

  RETURN event_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_event(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.publish_event(
  p_event_id uuid
)
RETURNS public.events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  event_row public.events;
BEGIN
  SELECT *
  INTO event_row
  FROM public.events
  WHERE id = p_event_id
    AND organizer_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found or not owned by the current user'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.events
  SET status = 'published',
      published_at = now()
  WHERE id = p_event_id
    AND status = 'approved'
  RETURNING * INTO event_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event must be approved before publishing'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.event_review_log (event_id, reviewer_id, action)
  VALUES (p_event_id, auth.uid(), 'published');

  RETURN event_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.publish_event(uuid) TO authenticated;

DROP POLICY IF EXISTS "Events are viewable by everyone" ON public.events;
DROP POLICY IF EXISTS "Published events viewable by everyone" ON public.events;
CREATE POLICY "Published events viewable by everyone"
  ON public.events
  FOR SELECT
  TO anon, authenticated
  USING (
    status IN ('published', 'live', 'ended')
    OR organizer_id = auth.uid()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "Organizers manage own events" ON public.events;
CREATE POLICY "Organizers manage own events"
  ON public.events
  FOR ALL
  TO authenticated
  USING (organizer_id = auth.uid() OR public.is_super_admin())
  WITH CHECK (organizer_id = auth.uid() OR public.is_super_admin());

CREATE OR REPLACE FUNCTION public.validate_and_check_in_ticket(
  p_qr_payload text,
  p_gate text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clean_payload text := trim(p_qr_payload);
  v_ticket record;
  v_event record;
  v_ticket_type record;
BEGIN
  IF v_clean_payload IS NULL OR v_clean_payload = '' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'empty_payload',
      'message', 'QR payload cannot be empty.'
    );
  END IF;

  SELECT *
  INTO v_ticket
  FROM public.tickets
  WHERE qr_code = v_clean_payload
     OR ticket_number = v_clean_payload
     OR id::text = v_clean_payload
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'not_found',
      'message', 'Ticket not found. Invalid QR code or reference.'
    );
  END IF;

  SELECT *
  INTO v_event
  FROM public.events
  WHERE id = v_ticket.event_id;

  IF NOT public.is_super_admin()
     AND (v_event.organizer_id IS NULL OR v_event.organizer_id <> auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized to scan this ticket'
      USING ERRCODE = '42501';
  END IF;

  SELECT name, price
  INTO v_ticket_type
  FROM public.ticket_types
  WHERE id = v_ticket.ticket_type_id;

  IF v_ticket.status = 'cancelled' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'cancelled',
      'message', 'This ticket has been cancelled.',
      'ticket_number', v_ticket.ticket_number
    );
  END IF;

  IF v_ticket.status = 'revoked' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'revoked',
      'message', 'This ticket has been revoked by the organizer.',
      'ticket_number', v_ticket.ticket_number
    );
  END IF;

  IF v_ticket.status = 'checked_in' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'already_checked_in',
      'message',
        'Ticket was already checked in at '
        || to_char(v_ticket.checked_in_at, 'YYYY-MM-DD HH24:MI:SS')
        || coalesce(' (' || v_ticket.gate || ')', '')
        || '.',
      'checked_in_at', v_ticket.checked_in_at,
      'gate', v_ticket.gate,
      'attendee_name', v_ticket.attendee_name,
      'ticket_number', v_ticket.ticket_number,
      'event_title', v_event.title
    );
  END IF;

  UPDATE public.tickets
  SET status = 'checked_in',
      checked_in_at = now(),
      gate = coalesce(p_gate, 'Main Gate'),
      updated_at = now()
  WHERE id = v_ticket.id;

  RETURN json_build_object(
    'valid', true,
    'status', 'checked_in',
    'message', 'Check-in successful! Welcome, ' || v_ticket.attendee_name || '.',
    'ticket_id', v_ticket.id,
    'ticket_number', v_ticket.ticket_number,
    'attendee_name', v_ticket.attendee_name,
    'attendee_email', v_ticket.attendee_email,
    'event_title', coalesce(v_event.title, 'Event'),
    'venue', coalesce(v_event.venue_name, 'Venue TBA'),
    'ticket_type', coalesce(v_ticket_type.name, 'Admission'),
    'checked_in_at', now(),
    'gate', coalesce(p_gate, 'Main Gate')
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_and_check_in_ticket(text, text)
  TO authenticated;

/*
  Optional pg_cron lifecycle automation.
  Enable pg_cron in the Supabase Dashboard before running this snippet.

  SELECT cron.schedule(
    'transition-events-every-five-minutes',
    '0-59/5 * * * *',
    $cron$
      UPDATE public.events
      SET status = 'live'
      WHERE status = 'published'
        AND starts_at <= now()
        AND ends_at > now();

      UPDATE public.events
      SET status = 'ended'
      WHERE status = 'live'
        AND ends_at <= now();
    $cron$
  );
*/
