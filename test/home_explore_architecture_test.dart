import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/core/utils/event_discovery.dart';
import 'package:future_times_events/data/models/event_model.dart';
import 'package:future_times_events/data/models/venue_model.dart';

EventModel _event({
  required String id,
  String? title,
  String? categoryId,
  String? categoryLabel,
  String? city,
  String? status,
  String? startsAt,
  bool featured = false,
  double price = 0,
}) {
  final day = startsAt ?? '2026-12-10';
  return EventModel(
    id: id,
    name: EventText(text: title ?? id, html: title ?? id),
    url: id,
    start: EventDateTime(
      timezone: 'Africa/Harare',
      utc: '${day}T18:00:00Z',
      local: '${day}T18:00:00',
    ),
    end: EventDateTime(
      timezone: 'Africa/Harare',
      utc: '${day}T20:00:00Z',
      local: '${day}T20:00:00',
    ),
    logo: null,
    venue: VenueModel(
      id: 'venue-$id',
      name: 'Venue $id',
      latitude: '0',
      longitude: '0',
      address: VenueAddress(
        address1: 'Main Street',
        city: city ?? 'Harare',
        country: 'Zimbabwe',
        localizedDisplay: city ?? 'Harare',
      ),
    ),
    categoryId: categoryId ?? 'music',
    categoryLabel: categoryLabel ?? 'Music',
    isFree: price == 0,
    featured: featured,
    status: status ?? 'published',
    currency: 'USD',
  );
}

void main() {
  test(
      'home ranking falls back to featured and upcoming events when preferences are empty',
      () {
    final events = [
      _event(
          id: 'older', title: 'Old', startsAt: '2026-01-10', featured: false),
      _event(
          id: 'featured',
          title: 'Featured',
          startsAt: '2026-12-20',
          featured: true),
      _event(
          id: 'upcoming',
          title: 'Upcoming',
          startsAt: '2026-12-12',
          featured: false),
    ];

    final ranked =
        rankHomeEvents(events, preferredCity: 'Harare', interests: const {});

    expect(ranked.first.id, 'featured');
    expect(ranked.map((event) => event.id).contains('upcoming'), isTrue);
  });

  test(
      'this weekend calculation resolves to the next relevant weekend in Harare',
      () {
    final weekend = nextWeekendStartForHarare(DateTime(2026, 8, 22));

    expect(weekend.weekday, DateTime.saturday);
    expect(weekend.year, 2026);
    expect(weekend.month, 8);
    expect(weekend.day, 22);
  });

  test(
      'explore filters by search, category and date without mutating the shared filter state',
      () {
    final events = [
      _event(
          id: 'a',
          title: 'Festival Night',
          categoryId: 'music',
          city: 'Harare',
          startsAt: '2026-12-12',
          price: 0),
      _event(
          id: 'b',
          title: 'Business Summit',
          categoryId: 'business',
          city: 'Bulawayo',
          startsAt: '2026-12-15',
          price: 25),
      _event(
          id: 'c',
          title: 'Rooftop Jazz',
          categoryId: 'music',
          city: 'Harare',
          startsAt: '2026-12-20',
          price: 0),
    ];

    final filtered = filterExploreEvents(
      events,
      query: 'festival',
      category: 'music',
      city: 'Harare',
      startDate: DateTime(2026, 12, 10),
      endDate: DateTime(2026, 12, 18),
      isFree: true,
    );

    expect(filtered.map((e) => e.id), ['a']);
  });
}
