-- Run supabase/fix_production_backend.sql first, then run this script.
-- Grants EXECUTE on every current public-schema RPC to app clients.
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
END $$;
