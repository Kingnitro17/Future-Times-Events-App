import 'package:equatable/equatable.dart';
import '../../../data/models/event_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Begin the booking flow for a specific event + ticket class.
class InitiateBooking extends BookingEvent {
  const InitiateBooking({
    required this.event,
    required this.selectedTicket,
    required this.quantity,
  });

  final EventModel event;
  final TicketClass selectedTicket;
  final int quantity;

  @override
  List<Object?> get props => [event, selectedTicket, quantity];
}

/// User confirmed payment (Stripe sheet has been presented).
class ConfirmPayment extends BookingEvent {
  const ConfirmPayment({required this.clientSecret});

  final String clientSecret;

  @override
  List<Object?> get props => [clientSecret];
}

/// User cancelled or dismissed the booking flow.
class CancelBooking extends BookingEvent {
  const CancelBooking();
}

/// Fall back to Eventbrite's own checkout URL (in-app WebView).
class OpenExternalCheckout extends BookingEvent {
  const OpenExternalCheckout({required this.checkoutUrl});

  final String checkoutUrl;

  @override
  List<Object?> get props => [checkoutUrl];
}

/// Reset the booking state (e.g., after success/error dismissal).
class ResetBooking extends BookingEvent {
  const ResetBooking();
}
