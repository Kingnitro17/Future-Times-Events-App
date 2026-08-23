import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/saved_events_repository.dart';
import '../repositories/social_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/notification_repository.dart';

class RealtimeService {
  RealtimeService({
    required AuthRepository authRepository,
    required SavedEventsRepository savedEventsRepository,
    required SocialRepository socialRepository,
    required TicketRepository ticketRepository,
    required NotificationRepository notificationRepository,
    SupabaseClient? client,
  })  : _auth = authRepository,
        _saved = savedEventsRepository,
        _social = socialRepository,
        _tickets = ticketRepository,
        _notifications = notificationRepository,
        _client = client ?? Supabase.instance.client {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthRepository _auth;
  final SavedEventsRepository _saved;
  final SocialRepository _social;
  final TicketRepository _tickets;
  final NotificationRepository _notifications;
  final SupabaseClient _client;

  RealtimeChannel? _channel;

  void _onAuthChanged() {
    final user = _auth.user;
    if (user != null) {
      _subscribe(user.id);
    } else {
      _unsubscribe();
    }
  }

  void _subscribe(String userId) {
    if (_channel != null) return;
    try {
      _channel = _client
          .channel('public:app_realtime:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'saved_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _saved.sync(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tickets',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _tickets.getMyTickets(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_follows',
            callback: (payload) => _social.getSocialStats(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'rsvps',
            callback: (payload) => _social.getSocialStats(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _notifications.fetchNotifications(),
          );
      _channel?.subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('[realtime] subscription error: $e');
    }
  }

  void _unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _unsubscribe();
  }
}
