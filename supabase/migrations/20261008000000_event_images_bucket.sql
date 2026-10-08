INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'events_images',
  'events_images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Public event images are viewable" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users upload event images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users update event images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users delete event images" ON storage.objects;

CREATE POLICY "Public event images are viewable"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id IN ('events', 'events_images'));

CREATE POLICY "Authenticated users upload event images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id IN ('events', 'events_images')
    AND auth.uid()::text = split_part(name, '/', 1)
  );

CREATE POLICY "Authenticated users update event images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id IN ('events', 'events_images')
    AND auth.uid()::text = split_part(name, '/', 1)
  )
  WITH CHECK (
    bucket_id IN ('events', 'events_images')
    AND auth.uid()::text = split_part(name, '/', 1)
  );

CREATE POLICY "Authenticated users delete event images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id IN ('events', 'events_images')
    AND auth.uid()::text = split_part(name, '/', 1)
  );
