/*
  Safe to re-run. Run after any migration that creates or replaces functions.
  Ensures no RPC returns 401 permission denied.
*/

DO $$
DECLARE
  function_signature text;
BEGIN
  FOR function_signature IN
    SELECT format(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
  LOOP
    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %s TO authenticated, anon',
      function_signature
    );
  END LOOP;
END
$$;
