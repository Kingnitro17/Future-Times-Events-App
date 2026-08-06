import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/event_model.dart';

/// Wraps Eventbrite REST API v3.
/// Reference: https://www.eventbrite.com/platform/api
class EventbriteApiService {
  EventbriteApiService() : _dio = DioClient.instance.dio;

  final Dio _dio;

  // ─── Fetch Events ──────────────────────────────────────────────────────────

  /// Fetches events with optional category, search query, and date range.
  /// Always expands `venue` to avoid a second request.
  Future<EventListResponse> fetchEvents({
    String? categoryId,
    String? query,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    double locationWithin = 50,
    String? startDateRangeStart,
    String? startDateRangeEnd,
    bool? isFree,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'expand': 'venue,ticket_classes',
      'page': page,
      'page_size': pageSize,
      'sort_by': 'date',
    };

    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['categories'] = categoryId;
    }
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (locationAddress != null) {
      queryParams['location.address'] = locationAddress;
    }
    if (locationLatitude != null) {
      queryParams['location.latitude'] = locationLatitude;
      queryParams['location.longitude'] = locationLongitude;
      queryParams['location.within'] = '${locationWithin}km';
    }
    if (startDateRangeStart != null) {
      queryParams['start_date.range_start'] = startDateRangeStart;
    }
    if (startDateRangeEnd != null) {
      queryParams['start_date.range_end'] = startDateRangeEnd;
    }
    if (isFree != null) {
      queryParams['price'] = isFree ? 'free' : 'paid';
    }

    final response = await _dio.get(
      'events/search/',
      queryParameters: queryParams,
    );

    return EventListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Fetch Single Event ────────────────────────────────────────────────────

  /// Fetches a single event by ID with venue and ticket classes expanded.
  Future<EventModel> fetchEventById(String eventId) async {
    final response = await _dio.get(
      'events/$eventId/',
      queryParameters: {'expand': 'venue,ticket_classes,category'},
    );

    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Ticket Classes ────────────────────────────────────────────────────────

  /// Fetches ticket classes (pricing tiers) for an event.
  Future<List<TicketClass>> fetchTicketClasses(String eventId) async {
    final response = await _dio.get('events/$eventId/ticket_classes/');
    final List<dynamic> items =
        (response.data as Map<String, dynamic>)['ticket_classes'] as List;
    return items
        .map((e) => TicketClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─── Pagination Wrapper ────────────────────────────────────────────────────

class EventListResponse {
  EventListResponse({
    required this.events,
    required this.pagination,
  });

  final List<EventModel> events;
  final PaginationMeta pagination;

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEvents = json['events'] as List<dynamic>? ?? [];
    return EventListResponse(
      events: rawEvents
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PaginationMeta {
  PaginationMeta({
    required this.objectCount,
    required this.pageNumber,
    required this.pageSize,
    required this.pageCount,
    required this.hasMoreItems,
  });

  final int objectCount;
  final int pageNumber;
  final int pageSize;
  final int pageCount;
  final bool hasMoreItems;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      objectCount: json['object_count'] as int? ?? 0,
      pageNumber: json['page_number'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      pageCount: json['page_count'] as int? ?? 1,
      hasMoreItems: json['has_more_items'] as bool? ?? false,
    );
  }
}
