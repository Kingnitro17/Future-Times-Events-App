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

  Future<Map<String, int>> getStartingPrices(Iterable<String> eventIds) async {
    final ids = eventIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const {};
    final rows = await _supabaseClient
        .from('events')
        .select('id,price')
        .inFilter('id', ids)
        .eq('status', 'published');
    final prices = <String, int>{};
    for (final row in rows) {
      final price = double.tryParse(row['price']?.toString() ?? '');
      if (price != null && price.isFinite && price >= 0) {
        prices[row['id'].toString()] = (price * 100).round();
      }
    }
    return prices;
  }

  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int limit = 50,
  }) async {
    if (!_validEventCoordinate(latitude, longitude) ||
        !radiusKm.isFinite ||
        radiusKm < 0 ||
        limit <= 0) {
      return const [];
    }
    final events = await _fetchPublishedEvents();
    const distance = Distance();
    final origin = LatLng(latitude, longitude);
    final nearby = events.where((event) {
      final point = _pointForEvent(event);
      return event.status == 'published' &&
          point != null &&
          distance.as(LengthUnit.Kilometer, origin, point) <= radiusKm;
    }).toList()
      ..sort((a, b) =>
          distance.as(LengthUnit.Meter, origin, _pointForEvent(a)!).compareTo(
                distance.as(LengthUnit.Meter, origin, _pointForEvent(b)!),
              ));
    return nearby.take(limit).toList();
  }

  Future<List<EventModel>> getEventsWithinBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    int limit = 100,
  }) async {
    if (!_validGeoCoordinate(northEastLat, northEastLng) ||
        !_validGeoCoordinate(southWestLat, southWestLng) ||
        northEastLat < southWestLat ||
        limit <= 0) {
      return const [];
    }

    final events = await _fetchPublishedEvents();
    final bounded = events.where((event) {
      if (event.status != 'published') return false;
      final point = _pointForEvent(event);
      if (point == null ||
          point.latitude < southWestLat ||
          point.latitude > northEastLat) {
        return false;
      }
      if (southWestLng <= northEastLng) {
        return point.longitude >= southWestLng &&
            point.longitude <= northEastLng;
      }
      return point.longitude >= southWestLng || point.longitude <= northEastLng;
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return bounded.take(limit).toList(growable: false);
  }

  Future<List<EventModel>> getHotEvents({int limit = 10}) async {
    if (limit <= 0) return const [];

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final until = now.add(const Duration(days: 30));

    try {
      final rows = await _supabaseClient
          .from('events')
          .select('id, title, slug, category, category_label, date, time, end_time, '
              'venue, address, city, image_url, price, attendees, capacity, '
              'featured, tags, lineup, organizer_name, lat, lng, status, '
              'starts_at, ends_at, timezone, venue_name')
          .eq('status', 'published')
          .gte('starts_at', from.toUtc().toIso8601String())
          .lte('starts_at', until.toUtc().toIso8601String())
          .order('starts_at', ascending: true)
          .limit(limit * 10);

      if (rows.isEmpty) return const [];

      final ids = rows
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .toList(growable: false);
      if (ids.isEmpty) return const [];

      final likesRows = await _supabaseClient
          .from('event_likes')
          .select('event_id')
          .inFilter('event_id', ids);
      final saveRows = await _supabaseClient
          .from('saved_events')
          .select('event_id')
          .inFilter('event_id', ids);

      final likeCounts = <String, int>{};
      for (final row in likesRows) {
        final id = row['event_id']?.toString();
        if (id == null) continue;
        likeCounts[id] = (likeCounts[id] ?? 0) + 1;
      }
      final saveCounts = <String, int>{};
      for (final row in saveRows) {
        final id = row['event_id']?.toString();
        if (id == null) continue;
        saveCounts[id] = (saveCounts[id] ?? 0) + 1;
      }

      final scored = rows.map((row) {
        final event = eventFromSupabaseRow(row);
        final eventId = event.id;
        final likeCount = likeCounts[eventId] ?? 0;
        final saveCount = saveCounts[eventId] ?? 0;
        final ticketsSold = event.attendeeCount;
        final hasAllMetrics = ticketsSold > 0 || likeCount > 0 || saveCount > 0;
        final score = hasAllMetrics
            ? (ticketsSold * 3) + (saveCount * 2) + (likeCount * 1)
            : (saveCount * 2) + (likeCount * 1);
        return MapEntry(event, score);
      }).toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.take(limit).map((entry) => entry.key).toList(growable: false);
    } catch (_) {
      final events = await _fetchPublishedEvents();
      final upcoming = events
          .where((event) => !event.startsAt.isBefore(now) &&
              !event.startsAt.isAfter(until))
          .toList()
        ..sort((a, b) => a.attendeeCount.compareTo(b.attendeeCount));
      return upcoming.take(limit).toList(growable: false);
    }
  }

  Future<List<EventModel>> _fetchPublishedEvents() async {
    final events = <EventModel>[];
    var page = 1;
    while (true) {
      final response = await _service.fetchEvents(page: page);
      events.addAll(response.events);
      if (!response.pagination.hasMoreItems) break;
      page++;
    }
    return events;
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
    if (lat == null || lng == null || !_validEventCoordinate(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static bool _validGeoCoordinate(double latitude, double longitude) =>
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180;

  static bool _validEventCoordinate(double latitude, double longitude) =>
      _validGeoCoordinate(latitude, longitude) &&
      !(latitude == 0 && longitude == 0);

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
