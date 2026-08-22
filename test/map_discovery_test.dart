import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/models/event_model.dart';
import 'package:future_times_events/data/models/venue_model.dart';
import 'package:future_times_events/presentation/screens/map_discovery_screen.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('rejects missing and zero map coordinates', () {
    expect(mapPointForEvent(_event('missing')), isNull);
    expect(mapPointForEvent(_event('zero', lat: 0, lng: 0)), isNull);
  });

  test('matches cities case-insensitively', () {
    final events = [
      _event('harare', city: 'Harare', lat: -17.82, lng: 31.05),
      _event('bulawayo', city: 'Bulawayo', lat: -20.15, lng: 28.58),
    ];

    final filtered = filterEventsForMap(events, city: ' harare ');

    expect(filtered.map((event) => event.id), ['harare']);
  });

  test('orders My Location cards from nearest to farthest', () {
    final events = [
      _event('far', lat: -17.70, lng: 31.20),
      _event('near', lat: -17.821, lng: 31.051),
    ];

    final filtered = filterEventsForMap(
      events,
      userLocation: const LatLng(-17.82, 31.05),
    );

    expect(filtered.map((event) => event.id), ['near', 'far']);
  });
}

EventModel _event(
  String id, {
  String? city,
  double? lat,
  double? lng,
}) =>
    EventModel(
      id: id,
      name: EventText(text: id, html: id),
      url: id,
      start: const EventDateTime(
        timezone: 'Africa/Harare',
        local: '2026-09-10T18:00:00+02:00',
        utc: '2026-09-10T16:00:00Z',
      ),
      end: const EventDateTime(
        timezone: 'Africa/Harare',
        local: '2026-09-10T20:00:00+02:00',
        utc: '2026-09-10T18:00:00Z',
      ),
      venue: VenueModel(
        id: '$id-venue',
        name: '$id venue',
        latitude: lat?.toString(),
        longitude: lng?.toString(),
        address: VenueAddress(city: city),
      ),
    );
