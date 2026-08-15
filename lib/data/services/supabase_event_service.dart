import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../models/event_model.dart';
import '../models/venue_model.dart';
import 'eventbrite_api_service.dart' show EventListResponse, PaginationMeta;

class SupabaseEventService {
  SupabaseEventService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const pageSize = 20;
  static const selection =
      'id,title,slug,category,category_label,date,time,end_time,venue,'
      'address,city,description,long_description,price,attendees,capacity,'
      'image_url,mood,tags,featured,lineup,organizer_name,lat,lng,status';

  Future<EventListResponse> fetchEvents({
    String? category,
    String? query,
    String? city,
    String? startDate,
    String? endDate,
    bool? isFree,
    int page = 1,
  }) async {
    try {
      var request =
          _client.from('events').select(selection).eq('status', 'published');
      if (category?.isNotEmpty == true)
        request = request.eq('category', category!);
      if (city?.isNotEmpty == true) request = request.eq('city', city!);
      if (query?.trim().isNotEmpty == true) {
        final safe = query!.trim().replaceAll(',', ' ');
        request = request
            .or('title.ilike.%$safe%,venue.ilike.%$safe%,city.ilike.%$safe%');
      }
      if (startDate?.isNotEmpty == true)
        request = request.gte('date', startDate!.substring(0, 10));
      if (endDate?.isNotEmpty == true)
        request = request.lte('date', endDate!.substring(0, 10));
      if (isFree == true) request = request.eq('price', 0);
      if (isFree == false) request = request.gt('price', 0);

      final from = (page - 1) * pageSize;
      final rows = await request
          .order('date', ascending: true)
          .range(from, from + pageSize);
      final events = rows.map<EventModel>(_mapEvent).toList();
      return EventListResponse(
        events: events,
        pagination: PaginationMeta(
          objectCount: from + events.length,
          pageNumber: page,
          pageSize: pageSize,
          pageCount: events.length == pageSize ? page + 1 : page,
          hasMoreItems: events.length == pageSize,
        ),
      );
    } on PostgrestException catch (error) {
      throw DataFailure(
        'Events could not be loaded. Please try again shortly.',
        code: error.code,
        cause: error,
      );
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw NetworkFailure(
        'No internet connection. Check your connection and try again.',
        cause: error,
      );
    }
  }

  Future<EventModel> fetchEventById(String id) async {
    try {
      final row =
          await _client.from('events').select(selection).eq('id', id).single();
      final ticketRows = await _client
          .from('ticket_types')
          .select(
              'id,name,price,quantity_total,quantity_available,claim_opens_at,claim_closes_at,is_active,is_visible')
          .eq('event_id', id)
          .eq('is_active', true)
          .eq('is_visible', true)
          .order('sort_order', ascending: true);
      return _mapEvent(row).copyWith(
        ticketClasses: ticketRows.map<TicketClass>(_mapTicketType).toList(),
      );
    } on PostgrestException catch (error) {
      throw DataFailure('This event could not be loaded.',
          code: error.code, cause: error);
    }
  }

  EventModel _mapEvent(Map<String, dynamic> row) {
    final date = row['date']?.toString() ?? '';
    final startTime = row['time']?.toString() ?? '00:00:00';
    final endTime = row['end_time']?.toString() ?? startTime;
    final price = double.tryParse(row['price']?.toString() ?? '') ?? 0;
    final start = '${date}T$startTime';
    final end = '${date}T$endTime';
    final image = row['image_url']?.toString() ?? '';
    return EventModel(
      id: row['id'].toString(),
      name: EventText(
          text: row['title']?.toString() ?? 'Event',
          html: row['title']?.toString() ?? 'Event'),
      description: EventText(
        text: row['long_description']?.toString().isNotEmpty == true
            ? row['long_description'].toString()
            : row['description']?.toString() ?? '',
        html: row['description']?.toString() ?? '',
      ),
      url: row['slug']?.toString() ?? row['id'].toString(),
      start: EventDateTime(timezone: 'Africa/Harare', local: start, utc: start),
      end: EventDateTime(timezone: 'Africa/Harare', local: end, utc: end),
      logo: image.isEmpty
          ? null
          : EventImage(id: row['id'].toString(), url: image),
      venue: VenueModel(
        id: row['venue']?.toString() ?? '',
        name: row['venue']?.toString() ?? '',
        latitude: row['lat']?.toString(),
        longitude: row['lng']?.toString(),
        address: VenueAddress(
            localizedDisplay: [row['address'], row['city']]
                .where((value) => value?.toString().isNotEmpty == true)
                .join(', ')),
      ),
      categoryId: row['category']?.toString(),
      isFree: price == 0,
      capacity: int.tryParse(row['capacity']?.toString() ?? ''),
      status: row['status']?.toString(),
      currency: 'USD',
      ticketClasses: const [],
    );
  }

  TicketClass _mapTicketType(Map<String, dynamic> row) {
    final price = double.tryParse(row['price']?.toString() ?? '') ?? 0;
    final total = int.tryParse(row['quantity_total']?.toString() ?? '');
    final available = int.tryParse(row['quantity_available']?.toString() ?? '');
    return TicketClass(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? 'Admission',
      free: price == 0,
      quantityTotal: total,
      quantitySold:
          total != null && available != null ? total - available : null,
      salesStart: row['claim_opens_at']?.toString(),
      salesEnd: row['claim_closes_at']?.toString(),
      cost: EventCost(
        currency: 'USD',
        value: (price * 100).round(),
        display: price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
      ),
    );
  }
}
