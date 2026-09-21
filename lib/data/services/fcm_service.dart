import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background notification message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      debugPrint('[FCM] Handling background message: ${message.messageId}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[FCM] Background handler init error: $e');
    }
  }
}

class FCMService {
  factory FCMService() => _instance;
  FCMService._internal();
  static final FCMService _instance = FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Initializes FCM permissions, local notification channels, and token listeners.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Request Notification Permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint(
            '[FCM] User notification status: ${settings.authorizationStatus}');
      }

      // 2. Setup Local Notifications for Foreground Banners
      await _setupLocalNotifications();

      // 3. Obtain & Save FCM Token
      final token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) debugPrint('[FCM] Token obtained: $token');
        await syncTokenToSupabase(token);
      }

      // Listen for Token Refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) debugPrint('[FCM] Token refreshed: $newToken');
        await syncTokenToSupabase(newToken);
      });

      // 4. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint(
              '[FCM] Foreground message received: ${message.notification?.title}');
        }
        _showForegroundNotification(message);
      });

      // 5. App Opened From Background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[FCM] App opened from notification: ${message.data}');
        }
        // Navigation or deep-link logic can be dispatched here
      });

      // 6. Terminated state launch
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint(
              '[FCM] App launched from notification: ${initialMessage.data}');
        }
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Service initialization warning/error: $e');
      }
    }
  }

  /// Saves or updates the FCM token in Supabase `user_fcm_tokens` table.
  Future<void> syncTokenToSupabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        if (kDebugMode) {
          debugPrint('[FCM] No logged-in user to save FCM token for.');
        }
        return;
      }

      await client.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_type': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, fcm_token',
      );

      if (kDebugMode) {
        debugPrint('[FCM] Successfully synced FCM token to Supabase.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error saving token to Supabase: $e');
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(initSettings);

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}
