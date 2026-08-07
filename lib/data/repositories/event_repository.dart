import '../models/event_model.dart';
import '../services/eventbrite_api_service.dart' show EventListResponse;
import '../services/supabase_event_service.dart';

class EventRepository {
  EventRepository({SupabaseEventService? service})
      : _service = service ?? SupabaseEventService();

  final SupabaseEventService _service;
  final Map<String, EventListResponse> _cache = {};

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
    final key =
        '$categoryId|$query|$locationAddress|$startDateRangeStart|$startDateRangeEnd|$isFree|$page';
    final cached = _cache[key];
    if (!forceRefresh && cached != null) return cached;
    final response = await _service.fetchEvents(
      category: categoryId,
      query: query,
      city: locationAddress,
      startDate: startDateRangeStart,
      endDate: startDateRangeEnd,
      isFree: isFree,
      page: page,
    );
    _cache[key] = response;
    return response;
  }

  Future<EventModel> getEventById(String eventId) =>
      _service.fetchEventById(eventId);

  Future<List<TicketClass>> getTicketClasses(String eventId) async =>
      (await _service.fetchEventById(eventId)).ticketClasses;

  void clearCache() => _cache.clear();
}
