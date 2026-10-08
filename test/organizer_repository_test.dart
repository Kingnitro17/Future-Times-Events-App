import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/repositories/organizer_repository.dart';

void main() {
  test('normalizeEventPayload maps legacy coordinates and populates a slug',
      () {
    final payload = OrganizerRepository.normalizeEventPayload({
      'title': 'Summer Bash',
      'latitude': '12.34',
      'longitude': '56.78',
      'slug': '',
    });

    expect(payload['title'], 'Summer Bash');
    expect(payload['lat'], 12.34);
    expect(payload['lng'], 56.78);
    expect(payload['slug'], isNotEmpty);
    expect(payload['slug'], contains('summer-bash-'));
  });

  test('generateEventSlug sanitizes titles and preserves suffixes', () {
    final slug = OrganizerRepository.generateEventSlug('Late Night! Live',
        suffix: 'abc123');
    expect(slug, 'late-night-live-abc123');
  });

  test(
      'formatEventMutationError maps storage and slug failures to helpful messages',
      () {
    expect(
      OrganizerRepository.formatEventMutationError(
          'duplicate key value violates unique constraint "events_slug_unique_idx"'),
      contains('already in use'),
    );
    expect(
      OrganizerRepository.formatEventMutationError(
          'new row violates row-level security policy for table "storage.objects"'),
      contains('storage policy'),
    );
  });
}
