import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_models.dart';

class NotificationRepository extends ChangeNotifier {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<List<NotificationModel>> fetchNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _notifications = const [];
      notifyListeners();
      return const [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(40);

      _notifications = (rows as List)
          .map((row) => NotificationModel.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[notifications] query error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            eventId: n.eventId,
            read: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[notifications] markAsRead error: $e');
    }
  }
}
