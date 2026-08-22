import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/presentation/widgets/event_network_image.dart';

void main() {
  testWidgets('invalid artwork has an accessible, stable fallback',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: EventNetworkImage(
              url: 'not-a-valid-url',
              semanticLabel: 'Future Summit artwork',
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Future Summit artwork unavailable'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
    semantics.dispose();
  });
}
