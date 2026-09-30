-- Add selected-event validation without changing the existing all-events RPC.
CREATE OR REPLACE FUNCTION public.validate_and_check_in_ticket(
  p_qr_payload text,
  p_gate text,
  p_event_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ticket_event_id uuid;
  v_clean_payload text := trim(p_qr_payload);
BEGIN
  IF v_clean_payload IS NULL OR v_clean_payload = '' THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'empty_payload',
      'message', 'QR payload cannot be empty.'
    );
  END IF;

  SELECT event_id
  INTO v_ticket_event_id
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

  IF v_ticket_event_id IS DISTINCT FROM p_event_id THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'wrong_event',
      'message', 'This ticket is for a different event.'
    );
  END IF;

  RETURN public.validate_and_check_in_ticket(v_clean_payload, p_gate);
END;
$$;

REVOKE ALL ON FUNCTION public.validate_and_check_in_ticket(text, text, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_and_check_in_ticket(text, text, uuid)
  TO authenticated;
