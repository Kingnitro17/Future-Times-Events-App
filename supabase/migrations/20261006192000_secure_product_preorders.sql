-- Keep preorder creation behind the RPC, which validates product, price, and
-- stock atomically. Organizers may update status, but no other preorder data.
REVOKE INSERT, UPDATE ON public.product_preorders
  FROM PUBLIC, anon, authenticated;
GRANT UPDATE (status) ON public.product_preorders TO authenticated;

DROP POLICY IF EXISTS "Customers may create their own product preorders"
  ON public.product_preorders;

DO $$
DECLARE
  constraint_row record;
BEGIN
  FOR constraint_row IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.user_follows'::regclass
      AND contype IN ('u', 'p')
      AND cardinality(conkey) = 2
      AND conkey[1] = (
        SELECT attnum FROM pg_attribute
        WHERE attrelid = 'public.user_follows'::regclass
          AND attname = 'follower_id'
      )
      AND conkey[2] = (
        SELECT attnum FROM pg_attribute
        WHERE attrelid = 'public.user_follows'::regclass
          AND attname = 'following_id'
      )
  LOOP
    EXECUTE format(
      'ALTER TABLE public.user_follows DROP CONSTRAINT %I',
      constraint_row.conname
    );
  END LOOP;
END $$;

DO $$
DECLARE
  index_row record;
BEGIN
  FOR index_row IN
    SELECT index_class.relname AS index_name
    FROM pg_index index_info
    JOIN pg_class table_class ON table_class.oid = index_info.indrelid
    JOIN pg_namespace table_schema ON table_schema.oid = table_class.relnamespace
    JOIN pg_class index_class ON index_class.oid = index_info.indexrelid
    LEFT JOIN pg_constraint constraint_info
      ON constraint_info.conindid = index_info.indexrelid
    WHERE table_schema.nspname = 'public'
      AND table_class.relname = 'user_follows'
      AND index_info.indisunique
      AND index_info.indnkeyatts = 2
      AND index_info.indkey[0] = (
        SELECT attnum FROM pg_attribute
        WHERE attrelid = table_class.oid AND attname = 'follower_id'
      )
      AND index_info.indkey[1] = (
        SELECT attnum FROM pg_attribute
        WHERE attrelid = table_class.oid AND attname = 'following_id'
      )
      AND constraint_info.oid IS NULL
  LOOP
    EXECUTE format('DROP INDEX public.%I', index_row.index_name);
  END LOOP;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS user_follows_target_unique
  ON public.user_follows (follower_id, following_id, target_type);

CREATE OR REPLACE FUNCTION public.guard_product_preorder_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.product_id IS DISTINCT FROM OLD.product_id
    OR NEW.event_id IS DISTINCT FROM OLD.event_id
    OR NEW.organizer_id IS DISTINCT FROM OLD.organizer_id
    OR NEW.user_id IS DISTINCT FROM OLD.user_id
    OR NEW.quantity IS DISTINCT FROM OLD.quantity
    OR NEW.unit_price IS DISTINCT FROM OLD.unit_price
    OR NEW.currency IS DISTINCT FROM OLD.currency
    OR NEW.notes IS DISTINCT FROM OLD.notes
    OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Only preorder status may be updated';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS product_preorders_guard_update
  ON public.product_preorders;
CREATE TRIGGER product_preorders_guard_update
  BEFORE UPDATE ON public.product_preorders
  FOR EACH ROW EXECUTE FUNCTION public.guard_product_preorder_update();

CREATE OR REPLACE FUNCTION public.restore_product_preorder_stock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  product_row public.organizer_products%ROWTYPE;
BEGIN
  IF OLD.status <> 'cancelled' AND NEW.status = 'cancelled' THEN
    UPDATE public.organizer_products
    SET stock_quantity = stock_quantity + OLD.quantity, updated_at = now()
    WHERE id = OLD.product_id AND stock_quantity IS NOT NULL;
  ELSIF OLD.status = 'cancelled' AND NEW.status <> 'cancelled' THEN
    SELECT * INTO product_row
    FROM public.organizer_products
    WHERE id = OLD.product_id
    FOR UPDATE;
    IF product_row.stock_quantity IS NOT NULL
      AND product_row.stock_quantity < OLD.quantity THEN
      RAISE EXCEPTION 'Not enough stock is available to reopen this preorder';
    END IF;
    IF product_row.stock_quantity IS NOT NULL THEN
      UPDATE public.organizer_products
      SET stock_quantity = stock_quantity - OLD.quantity, updated_at = now()
      WHERE id = OLD.product_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS product_preorders_restore_stock
  ON public.product_preorders;
CREATE TRIGGER product_preorders_restore_stock
  BEFORE UPDATE OF status ON public.product_preorders
  FOR EACH ROW EXECUTE FUNCTION public.restore_product_preorder_stock();
