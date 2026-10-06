import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events_app/data/models/event_model.dart';
import 'package:future_times_events_app/presentation/widgets/price_label.dart';

void main() {
  testWidgets('shows Free only when the event is marked free', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PriceLabel(isFree: true, ticketClasses: []),
              PriceLabel(isFree: false, ticketClasses: []),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('View tickets'), findsOneWidget);
  });

  testWidgets('shows the cheapest paid ticket when pricing is available',
      (tester) async {
    const tickets = [
      TicketClass(
        id: 'expensive',
        name: 'Premium',
        free: false,
        cost: EventCost(currency: 'USD', value: 5000, display: '\$50.00'),
      ),
      TicketClass(
        id: 'standard',
        name: 'Standard',
        free: false,
        cost: EventCost(currency: 'USD', value: 2500, display: '\$25.00'),
      ),
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriceLabel(isFree: false, ticketClasses: tickets),
        ),
      ),
    );

    expect(find.text('Starting from \$25.00'), findsOneWidget);
  });
}
