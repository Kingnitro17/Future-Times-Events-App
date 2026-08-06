import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/models.dart';
import '../../shared/models/enums.dart';

/// Event repository — all Supabase queries for events and ticket types.
class EventRepository {
  EventRepository();

  SupabaseClient get _client => SupabaseService.client;

  // ── Event Listing ──────────────────────────────────────────────────────────

  /// Fetch paginated published events.
  Future<List<Event>> getEvents({
    String? category,
    String? city,
    bool? isFree,
    DateTime? fromDate,
    int page = 0,
    int pageSize = AppConfig.eventPageSize,
  }) async {
    try {
      var query = _client
          .from('events')
          .select('''
            id, title, slug, subtitle, category, category_label,
            description, status, featured, starts_at, ends_at,
            cover_image_url, image_url, venue_name, venue, city,
            address, lat, lng, capacity, attendees, organizer_name, tags
          ''')
          .inFilter('status', ['published', 'sold_out'])
          .order('featured', ascending: false)
          .order('starts_at', ascending: true)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (city != null && city.isNotEmpty) {
        query = query.ilike('city', '%$city%');
      }
      if (fromDate != null) {
        query = query.gte('starts_at', fromDate.toIso8601String());
      } else {
        // Default: only future events
        query = query.gte(
          'starts_at',
          DateTime.now()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
        );
      }

      final data = await query;
      var events = (data as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();

      if (isFree == true) {
        // Filter free events by checking ticket_types server-side is complex;
        // we filter on the ticket_types join in getEventWithTicketTypes.
        // For the list view, we rely on category/description heuristics
        // or a `is_free` virtual column if added in DB.
      }

      return events;
    } on PostgrestException catch (e) {
      dev.log('[EventRepository] getEvents: ${e.message}', name: 'EventRepository');
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Fetch featured events for the home hero section.
  Future<List<Event>> getFeaturedEvents({int limit = 5}) async {
    try {
      final data = await _client
          .from('events')
          .select('''
            id, title, slug, subtitle, category, category_label,
            description, status, featured, starts_at, ends_at,
            cover_image_url, image_url, venue_name, venue, city,
            capacity, attendees, organizer_name, tags
          ''')
          .eq('featured', true)
          .inFilter('status', ['published', 'sold_out'])
          .gte(
            'starts_at',
            DateTime.now()
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
          )
          .order('starts_at', ascending: true)
          .limit(limit);

      return (data as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Search events by title/venue/city.
  Future<List<Event>> searchEvents(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    try {
      final data = await _client
          .from('events')
          .select('''
            id, title, slug, subtitle, category, category_label,
            description, status, starts_at, ends_at,
            cover_image_url, image_url, venue_name, city
          ''')
          .inFilter('status', ['published', 'sold_out'])
          .or('title.ilike.%$query%,venue_name.ilike.%$query%,city.ilike.%$query%')
          .order('starts_at', ascending: true)
          .limit(limit);

      return (data as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Single Event ────────────────────────────────────────────────────────────

  Future<Event?> getEventBySlug(String slug) async {
    try {
      final data = await _client
          .from('events')
          .select('''
            id, title, slug, subtitle, category, category_label,
            description, long_description, status, featured,
            starts_at, ends_at, doors_open_at,
            cover_image_url, image_url, timezone,
            venue_id, venue, venue_name, address, city, lat, lng,
            capacity, attendees, dress_code, age_guidance, event_rules,
            contact_email, organizer_id, organizer_name, tags, created_at
          ''')
          .eq('slug', slug)
          .maybeSingle();

      if (data == null) return null;
      return Event.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Ticket Types ─────────────────────────────────────────────────────────

  Future<List<TicketType>> getTicketTypes(String eventId) async {
    try {
      final data = await _client
          .from('ticket_types')
          .select('''
            id, event_id, name, description, price,
            quantity_total, quantity_available, claim_limit_per_contact,
            claim_opens_at, claim_closes_at, is_active, is_visible, sort_order
          ''')
          .eq('event_id', eventId)
          .eq('is_active', true)
          .eq('is_visible', true)
          .order('sort_order', ascending: true);

      return (data as List<dynamic>)
          .map((e) => TicketType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(e.code);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Event FAQs / Schedule ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEventFaqs(String eventId) async {
    try {
      final data = await _client
          .from('event_faqs')
          .select('question, answer, sort_order')
          .eq('event_id', eventId)
          .order('sort_order', ascending: true);

      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventSchedule(String eventId) async {
    try {
      final data = await _client
          .from('event_schedule_items')
          .select('title, description, starts_at, ends_at, sort_order')
          .eq('event_id', eventId)
          .order('sort_order', ascending: true);

      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Distinct cities from published events — for city filter.
  Future<List<String>> getEventCities() async {
    try {
      final data = await _client
          .from('events')
          .select('city')
          .inFilter('status', ['published', 'sold_out'])
          .not('city', 'is', null);

      final cities = (data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['city'] as String?)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      return cities;
    } catch (_) {
      return [];
    }
  }
}
