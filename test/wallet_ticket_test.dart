import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/models/wallet_ticket.dart';

void main() {
  test('maps the production ticket payload including the real QR value', () {
    final ticket = WalletTicket.fromSupabase({
      'id': 'ticket-row-id',
      'ticket_id': 'FTE-LEGACY-42',
      'ticket_number': 'FTE-000042',
      'event_id': 'event-id',
      'status': 'issued',
      'issued_at': '2026-08-22T08:00:00Z',
      'attendee_name': 'Future Guest',
      'attendee_email': 'guest@example.com',
      'qr_code': 'production-qr-payload',
      'events': {
        'title': 'Future Summit',
        'starts_at': '2026-09-10T18:30:00+02:00',
        'venue_name': 'Harare Conference Centre',
        'image_url': 'https://images.example.test/event.jpg',
      },
      'ticket_type': {'name': 'General Admission'},
    });

    expect(ticket.ticketNumber, 'FTE-000042');
    expect(ticket.qrPayload, 'production-qr-payload');
    expect(ticket.eventTitle, 'Future Summit');
    expect(ticket.ticketType, 'General Admission');
    expect(ticket.isActive, isTrue);
    expect(ticket.isViewable, isTrue);
  });

  test('supports legacy holder fields and never invents a QR payload', () {
    final ticket = WalletTicket.fromSupabase({
      'id': 'legacy-ticket',
      'event_id': 'event-id',
      'holder_name': 'Legacy Guest',
      'holder_email': 'legacy@example.com',
      'qr_code': '   ',
    });

    expect(ticket.attendeeName, 'Legacy Guest');
    expect(ticket.attendeeEmail, 'legacy@example.com');
    expect(ticket.qrPayload, isNull);
    expect(ticket.ticketNumber, 'legacy-ticket');
    expect(ticket.isViewable, isTrue);
  });

  test('cancelled and revoked tickets are not treated as viewable admission',
      () {
    for (final status in ['cancelled', 'revoked']) {
      final ticket = WalletTicket.fromSupabase({
        'id': status,
        'event_id': 'event-id',
        'status': status,
      });
      expect(ticket.isViewable, isFalse);
    }
  });
}
