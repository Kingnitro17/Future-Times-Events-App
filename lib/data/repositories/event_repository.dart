import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_partner.dart';
import '../models/event_model.dart';
import '../models/event_list_response.dart';
import '../services/supabase_event_service.dart';

class EventRepository {
  EventRepository({SupabaseEventService? service, SupabaseClient? client})
      : _service = service ?? SupabaseEventService(client: client),
        _client = client;

  final SupabaseEventService _service;
  final SupabaseClient? _client;
  final Map<String, EventListResponse> _cache = {};

  SupabaseClient get _supabaseClient => _client ?? Supabase.instance.client;

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

  Future<({EventModel event, List<EventPartner> partners, bool hasFtPartner})>
      getEventWithPartners(String eventId) async {
    try {
      final row = await _supabaseClient
          .from('events')
          .select(SupabaseEventService.selection)
          .eq('id', eventId)
          .single();
      final partnerRows = await _supabaseClient
          .from('event_partners')
          .select()
          .eq('event_id', eventId)
          .order('sort_order')
          .order('name');
      final hasFtPartner = await _supabaseClient.rpc(
        'event_has_ft_service',
        params: {'p_event_id': eventId},
      );
      return (
        event: eventFromSupabaseRow(row),
        partners: partnerRows
            .map<EventPartner>((item) => EventPartner.fromSupabase(item))
            .toList(growable: false),
        hasFtPartner: hasFtPartner == true,
      );
    } on PostgrestException catch (error) {
      throw DataFailure(
        'Event partners could not be loaded.',
        code: error.code,
        cause: error,
      );
    }
  }

  Future<List<EventModel>> getEventsByIds(Iterable<String> eventIds) =>
      _service.fetchEventsByIds(eventIds);

  Future<List<EventModel>> getNearbyEvents({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int limit = 50,
  }) async {
    final response = await getEvents(forceRefresh: true, page: 1);
    const distance = Distance();
    final origin = LatLng(lat, lng);
    final nearby = response.events.where((event) {
      if (event.status != 'published') return false;
      final eventLat = double.tryParse(event.venue?.latitude ?? '');
      final eventLng = double.tryParse(event.venue?.longitude ?? '');
      if (eventLat == null || eventLng == null) return false;
      return distance.as(
            LengthUnit.Kilometer,
            origin,
            LatLng(eventLat, eventLng),
          ) <=
          radiusKm;
    }).toList()
      ..sort((a, b) => distance
          .as(LengthUnit.Meter, origin, _pointForEvent(a)!)
          .compareTo(
              distance.as(LengthUnit.Meter, origin, _pointForEvent(b)!)));
    return nearby.take(limit).toList();
  }

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

  LatLng? _pointForEvent(EventModel event) {
    final lat = double.tryParse(event.venue?.latitude ?? '');
    final lng = double.tryParse(event.venue?.longitude ?? '');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return LatLng(lat, lng);
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
