import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/event_list_response.dart';
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
    try {
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
      await _persist(key, response);
      return response;
    } catch (_) {
      final offline = await _readPersisted(key, page);
      if (offline != null) {
        _cache[key] = offline;
        return offline;
      }
      rethrow;
    }
  }

  Future<EventModel> getEventById(String eventId) =>
      _service.fetchEventById(eventId);

  Future<List<TicketClass>> getTicketClasses(String eventId) async =>
      (await _service.fetchEventById(eventId)).ticketClasses;

  void clearCache() => _cache.clear();

  static String _storageKey(String key) =>
      'future_times.events.${base64Url.encode(utf8.encode(key))}';

  Future<void> _persist(String key, EventListResponse response) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'events': response.events.map((event) => event.toJson()).toList(),
      'has_more': response.pagination.hasMoreItems,
    });
    await preferences.setString(_storageKey(key), payload);
  }

  Future<EventListResponse?> _readPersisted(String key, int page) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey(key));
      if (raw == null) return null;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final rows = payload['events'] as List<dynamic>?;
      if (rows == null) return null;
      final events = rows
          .map((row) => EventModel.fromJson(row as Map<String, dynamic>))
          .toList();
      return EventListResponse(
        events: events,
        pagination: PaginationMeta(
          objectCount: events.length,
          pageNumber: page,
          pageSize: events.length,
          pageCount: page,
          hasMoreItems: payload['has_more'] == true,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
