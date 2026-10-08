import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_models.dart';

class NotificationRepository extends ChangeNotifier {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _lastError;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<List<NotificationModel>> fetchNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _notifications = const [];
      _lastError = null;
      notifyListeners();
      return const [];
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final rows = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(40);

      _notifications = (rows as List)
          .map((row) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      _lastError = 'Notifications could not be loaded. Please try again.';
      if (kDebugMode) debugPrint('[notifications] query error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in is required to manage notifications.');
    }

    try {
      await _client.from('notifications').update({
        'read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId).eq('user_id', userId);
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            eventId: n.eventId,
            payload: n.payload,
            read: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[notifications] markAsRead error: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in is required to dismiss notifications.');
    }

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
      _notifications =
          _notifications.where((item) => item.id != notificationId).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[notifications] delete error: $e');
      rethrow;
    }
  }
}
