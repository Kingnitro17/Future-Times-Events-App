import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/services/supabase_event_service.dart';

void main() {
  test('prefers authoritative production timestamps and venue name', () {
    final event = eventFromSupabaseRow({
      'id': 'event-id',
      'title': 'Future Summit',
      'slug': 'future-summit',
      'date': '2026-09-10',
      'time': '18:00:00',
      'end_time': '20:00:00',
      'starts_at': '2026-09-10T18:30:00+02:00',
      'ends_at': '2026-09-10T22:15:00+02:00',
      'timezone': 'Africa/Harare',
      'venue': 'venue-id',
      'venue_name': 'Harare Conference Centre',
      'city': 'Harare',
      'price': 12.50,
      'status': 'published',
    });

    expect(event.start.local, '2026-09-10T18:30:00+02:00');
    expect(event.end.local, '2026-09-10T22:15:00+02:00');
    expect(event.start.timezone, 'Africa/Harare');
    expect(event.venue?.name, 'Harare Conference Centre');
    expect(event.isFree, isFalse);
  });

  test('falls back to legacy date and time fields safely', () {
    final event = eventFromSupabaseRow({
      'id': 'legacy-event',
      'title': 'Legacy Event',
      'date': '2026-10-01',
      'time': '09:00:00',
      'end_time': '11:00:00',
      'venue': 'Community Hall',
      'price': 0,
    });

    expect(event.start.local, '2026-10-01T09:00:00');
    expect(event.end.local, '2026-10-01T11:00:00');
    expect(event.venue?.name, 'Community Hall');
    expect(event.isFree, isTrue);
  });
}
