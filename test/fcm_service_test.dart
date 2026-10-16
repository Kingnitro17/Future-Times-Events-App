import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/services/fcm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification failure does not prevent the app from rendering',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var firebaseCalls = 0;
    var messagingCalls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const coreChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
      StandardMessageCodec(),
    );
    messenger.setMockDecodedMessageHandler<Object?>(coreChannel, (_) async {
      firebaseCalls++;
      return <Object?>['unavailable', 'Firebase unavailable', null];
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      (_) async {
        messagingCalls++;
        throw PlatformException(code: 'unexpected-messaging-access');
      },
    );
    addTearDown(() {
      messenger.setMockDecodedMessageHandler<Object?>(coreChannel, null);
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_messaging'),
        null,
      );
    });

    // Construction must be safe even when no default Firebase app exists.
    try {
      final service = FCMService();
      await service.syncCurrentTokenToSupabase();
      await service.initialize();
      await service.syncCurrentTokenToSupabase();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }

    // Web must skip Firebase even when the browser's target platform is Android.
    expect(firebaseCalls, kIsWeb ? 0 : 1);
    expect(messagingCalls, 0);
    await tester.pumpWidget(const MaterialApp(home: Text('App ready')));
    expect(find.text('App ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
