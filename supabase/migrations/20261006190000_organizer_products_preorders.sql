-- Add typed follow targets so user friendships and organizer follows do not
-- overwrite one another for the same pair of accounts.
ALTER TABLE public.user_follows
  ADD COLUMN IF NOT EXISTS target_type text NOT NULL DEFAULT 'user';

DO $$
DECLARE
  constraint_row record;
BEGIN
  FOR constraint_row IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.user_follows'::regclass
      AND contype = 'u'
      AND pg_get_constraintdef(oid) = 'UNIQUE (follower_id, following_id)'
  LOOP
    EXECUTE format('ALTER TABLE public.user_follows DROP CONSTRAINT %I', constraint_row.conname);
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

ALTER TABLE public.user_follows
  ADD CONSTRAINT user_follows_target_type_check
  CHECK (target_type IN ('user', 'organizer'));

CREATE TABLE IF NOT EXISTS public.organizer_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  organizer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(trim(name)) > 0),
  description text,
  image_url text,
  price numeric(12, 2) NOT NULL CHECK (price >= 0),
  currency text NOT NULL DEFAULT 'USD' CHECK (length(currency) = 3),
  stock_quantity integer CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS organizer_products_event_active_idx
  ON public.organizer_products (event_id, is_active, created_at DESC);

CREATE TABLE IF NOT EXISTS public.product_preorders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.organizer_products(id) ON DELETE RESTRICT,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  organizer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
  currency text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'fulfilled', 'cancelled')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS product_preorders_user_created_idx
  ON public.product_preorders (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS product_preorders_event_created_idx
  ON public.product_preorders (event_id, created_at DESC);

ALTER TABLE public.organizer_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_preorders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active organizer products"
  ON public.organizer_products FOR SELECT
  USING (is_active OR organizer_id = auth.uid());
CREATE POLICY "Organizers manage their products"
  ON public.organizer_products FOR ALL
  USING (
    organizer_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id AND e.organizer_id = auth.uid()
    )
  )
  WITH CHECK (
    organizer_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id AND e.organizer_id = auth.uid()
    )
  );
CREATE POLICY "Customers and organizers view product preorders"
  ON public.product_preorders FOR SELECT
  USING (user_id = auth.uid() OR organizer_id = auth.uid());
CREATE POLICY "Customers may create their own product preorders"
  ON public.product_preorders FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.organizer_products p
      WHERE p.id = product_id
        AND p.event_id = event_id
        AND p.organizer_id = organizer_id
        AND p.is_active
    )
  );
CREATE POLICY "Organizers update preorder status"
  ON public.product_preorders FOR UPDATE
  USING (organizer_id = auth.uid())
  WITH CHECK (organizer_id = auth.uid());

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
    SET stock_quantity = stock_quantity + NEW.quantity, updated_at = now()
    WHERE id = NEW.product_id AND stock_quantity IS NOT NULL;
  ELSIF OLD.status = 'cancelled' AND NEW.status <> 'cancelled' THEN
    SELECT * INTO product_row
    FROM public.organizer_products
    WHERE id = NEW.product_id
    FOR UPDATE;
    IF product_row.stock_quantity IS NOT NULL
      AND product_row.stock_quantity < NEW.quantity THEN
      RAISE EXCEPTION 'Not enough stock is available to reopen this preorder';
    END IF;
    IF product_row.stock_quantity IS NOT NULL THEN
      UPDATE public.organizer_products
      SET stock_quantity = stock_quantity - NEW.quantity, updated_at = now()
      WHERE id = NEW.product_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER product_preorders_restore_stock
  BEFORE UPDATE OF status ON public.product_preorders
  FOR EACH ROW EXECUTE FUNCTION public.restore_product_preorder_stock();

CREATE OR REPLACE FUNCTION public.create_product_preorder(
  p_product_id uuid,
  p_quantity integer,
  p_notes text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  product_row public.organizer_products%ROWTYPE;
  preorder_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Sign in to preorder products';
  END IF;
  IF p_quantity IS NULL OR p_quantity < 1 THEN
    RAISE EXCEPTION 'Quantity must be at least one';
  END IF;

  SELECT * INTO product_row
  FROM public.organizer_products
  WHERE id = p_product_id AND is_active
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'This product is no longer available';
  END IF;
  IF product_row.stock_quantity IS NOT NULL
    AND product_row.stock_quantity < p_quantity THEN
    RAISE EXCEPTION 'Not enough stock is available';
  END IF;

  INSERT INTO public.product_preorders (
    product_id, event_id, organizer_id, user_id, quantity, unit_price, currency, notes
  )
  VALUES (
    product_row.id, product_row.event_id, product_row.organizer_id, auth.uid(),
    p_quantity, product_row.price, product_row.currency, NULLIF(trim(p_notes), '')
  )
  RETURNING id INTO preorder_id;

  IF product_row.stock_quantity IS NOT NULL THEN
    UPDATE public.organizer_products
    SET stock_quantity = stock_quantity - p_quantity, updated_at = now()
    WHERE id = product_row.id;
  END IF;

  RETURN preorder_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_product_preorder(uuid, integer, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_product_preorder(uuid, integer, text)
  TO authenticated;
