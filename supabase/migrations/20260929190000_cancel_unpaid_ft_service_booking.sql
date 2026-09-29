-- Let organizers cancel only unpaid service booking requests.
CREATE OR REPLACE FUNCTION public.cancel_service_booking(p_booking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  booking_row public.ft_service_bookings;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO booking_row
  FROM public.ft_service_bookings
  WHERE id = p_booking_id
    AND organizer_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found or not owned by you'
      USING ERRCODE = '42501';
  END IF;
  IF booking_row.status NOT IN ('draft', 'pending_payment') THEN
    RAISE EXCEPTION 'Only bookings without a paid deposit can be cancelled'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.ft_service_bookings
  SET status = 'cancelled',
      updated_at = now()
  WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_service_booking(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_service_booking(uuid) TO authenticated;
