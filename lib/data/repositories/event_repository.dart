import '../models/event_model.dart';
import '../models/venue_model.dart';
import '../services/eventbrite_api_service.dart';

/// Abstracts [EventbriteApiService] behind a clean contract.
/// Handles in-memory pagination caching.
class EventRepository {
  EventRepository({EventbriteApiService? service})
      : _service = service ?? EventbriteApiService();

  final EventbriteApiService _service;

  // Simple in-memory page cache
  final Map<String, List<EventModel>> _cache = {};

  String _cacheKey({
    String? categoryId,
    String? query,
    int page = 1,
  }) =>
      '${categoryId ?? ''}_${query ?? ''}_$page';

  // ─── Fetch Events ──────────────────────────────────────────────────────────

  Future<EventListResponse> getEvents({
    String? categoryId,
    String? query,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? startDateRangeStart,
    String? startDateRangeEnd,
    bool? isFree,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    // TEMPORARILY MOCKED FOR UI ONLY
    await Future.delayed(const Duration(milliseconds: 800)); // simulate network

    final fakeEvents = List.generate(
      10,
      (index) => EventModel(
        id: 'mock_event_${page}_$index',
        name: EventText(
          text: 'Exclusive Tech Showcase & Gala ${page * 10 + index}', 
          html: 'Exclusive Tech Showcase & Gala ${page * 10 + index}'
        ),
        description: EventText(
          text: 'Join industry leaders for an unforgettable night of innovation, networking, and premium experiences.', 
          html: 'Join industry leaders for an unforgettable night of innovation, networking, and premium experiences.'
        ),
        url: 'https://example.com',
        start: EventDateTime(timezone: 'UTC', local: '2026-10-01T19:00:00', utc: '2026-10-01T19:00:00Z'),
        end: EventDateTime(timezone: 'UTC', local: '2026-10-01T23:00:00', utc: '2026-10-01T23:00:00Z'),
        logo: EventImage(id: 'logo_$index', url: 'https://picsum.photos/seed/${page * 10 + index}/800/400'),
        venue: VenueModel(
          id: 'venue_$index',
          name: 'The Grand Moscone Center',
          latitude: '37.7842',
          longitude: '-122.4016',
          address: const VenueAddress(localizedDisplay: '747 Howard St, San Francisco, CA'),
        ),
        isFree: false,
      ),
    );

    return EventListResponse(
      events: fakeEvents,
      pagination: PaginationMeta(
        objectCount: 100,
        pageNumber: page,
        pageSize: 10,
        pageCount: 10,
        hasMoreItems: page < 10,
      ),
    );
  }

  // ─── Get Single Event ──────────────────────────────────────────────────────

  Future<EventModel> getEventById(String eventId) async {
    final list = await getEvents();
    return list.events.first;
  }

  // ─── Get Ticket Classes ────────────────────────────────────────────────────

  Future<List<TicketClass>> getTicketClasses(String eventId) async {
    // TEMPORARILY MOCKED FOR UI ONLY
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TicketClass(
        id: 'ticket_1',
        name: 'General Admission',
        free: false,
        cost: EventCost(display: '\$49.99', currency: 'USD', value: 4999),
      ),
      TicketClass(
        id: 'ticket_2',
        name: 'VIP Experience',
        free: false,
        cost: EventCost(display: '\$199.99', currency: 'USD', value: 19999),
      ),
    ];
  }

  // ─── Cache Control ─────────────────────────────────────────────────────────

  void clearCache() => _cache.clear();
}
