-- Ensure the live database matches the app's required event schema and image storage rules.
-- Safe to re-run.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS slug text,
  ADD COLUMN IF NOT EXISTS lat double precision,
  ADD COLUMN IF NOT EXISTS lng double precision,
  ADD COLUMN IF NOT EXISTS image_url text,
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS venue_name text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'draft';

UPDATE public.events
SET status = 'draft'
WHERE status IS NULL;

UPDATE public.events
SET slug = CASE
  WHEN slug IS NULL OR trim(slug) = '' THEN
    'event-' || id::text
  ELSE slug
END
WHERE slug IS NULL OR trim(slug) = '';

UPDATE public.events
SET slug = lower(regexp_replace(slug, '[^a-z0-9]+', '-', 'g'))
WHERE slug IS NOT NULL
  AND trim(slug) <> ''
  AND slug <> lower(regexp_replace(slug, '[^a-z0-9]+', '-', 'g'));

ALTER TABLE public.events
  ALTER COLUMN status SET DEFAULT 'draft';

CREATE UNIQUE INDEX IF NOT EXISTS events_slug_unique_idx
  ON public.events (slug)
  WHERE slug IS NOT NULL AND trim(slug) <> '';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('events', 'events', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public event images are viewable" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users upload event images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users update event images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users delete event images" ON storage.objects;

CREATE POLICY "Public event images are viewable"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'events');

CREATE POLICY "Authenticated users upload event images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'events'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR auth.uid()::text = split_part(name, '/', 1)
    )
  );

CREATE POLICY "Authenticated users update event images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'events'
    AND auth.uid()::text = split_part(name, '/', 1)
  )
  WITH CHECK (
    bucket_id = 'events'
    AND auth.uid()::text = split_part(name, '/', 1)
  );

CREATE POLICY "Authenticated users delete event images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'events'
    AND auth.uid()::text = split_part(name, '/', 1)
  );

CREATE OR REPLACE FUNCTION public.validate_and_check_in_ticket(
  p_qr_payload text,
  p_gate text DEFAULT NULL,
  p_event_id uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clean_payload text := trim(p_qr_payload);
  v_ticket_record record;
  v_event_record record;
  v_ticket_type_record record;
BEGIN
  IF v_clean_payload IS NULL OR v_clean_payload = '' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'empty_payload',
      'message', 'QR payload cannot be empty.'
    );
  END IF;

  SELECT *
  INTO v_ticket_record
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

  IF p_event_id IS NOT NULL AND v_ticket_record.event_id IS DISTINCT FROM p_event_id THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'wrong_event',
      'message', 'This ticket is for a different event.'
    );
  END IF;

  SELECT *
  INTO v_event_record
  FROM public.events
  WHERE id = v_ticket_record.event_id;

  IF NOT public.is_super_admin()
     AND (v_event_record.organizer_id IS NULL OR v_event_record.organizer_id <> auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized to scan this ticket'
      USING ERRCODE = '42501';
  END IF;

  SELECT name, price
  INTO v_ticket_type_record
  FROM public.ticket_types
  WHERE id = v_ticket_record.ticket_type_id;

  IF v_ticket_record.status = 'cancelled' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'cancelled',
      'message', 'This ticket has been cancelled.',
      'ticket_number', v_ticket_record.ticket_number
    );
  END IF;

  IF v_ticket_record.status = 'revoked' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'revoked',
      'message', 'This ticket has been revoked by the organizer.',
      'ticket_number', v_ticket_record.ticket_number
    );
  END IF;

  IF v_ticket_record.status = 'checked_in' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'already_checked_in',
      'message',
        'Ticket was already checked in at '
        || to_char(v_ticket_record.checked_in_at, 'YYYY-MM-DD HH24:MI:SS')
        || coalesce(' (' || v_ticket_record.gate || ')', '')
        || '.',
      'checked_in_at', v_ticket_record.checked_in_at,
      'gate', v_ticket_record.gate,
      'attendee_name', v_ticket_record.attendee_name,
      'ticket_number', v_ticket_record.ticket_number,
      'event_title', v_event_record.title
    );
  END IF;

  UPDATE public.tickets
  SET status = 'checked_in',
      checked_in_at = now(),
      gate = coalesce(p_gate, 'Main Gate'),
      updated_at = now()
  WHERE id = v_ticket_record.id;

  RETURN json_build_object(
    'valid', true,
    'status', 'checked_in',
    'message', 'Check-in successful! Welcome, ' || v_ticket_record.attendee_name || '.',
    'ticket_id', v_ticket_record.id,
    'ticket_number', v_ticket_record.ticket_number,
    'attendee_name', v_ticket_record.attendee_name,
    'attendee_email', v_ticket_record.attendee_email,
    'event_title', coalesce(v_event_record.title, 'Event'),
    'venue', coalesce(v_event_record.venue_name, 'Venue TBA'),
    'ticket_type', coalesce(v_ticket_type_record.name, 'Admission'),
    'checked_in_at', now(),
    'gate', coalesce(p_gate, 'Main Gate')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.validate_and_check_in_ticket(text, text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_and_check_in_ticket(text, text, uuid) TO authenticated;
