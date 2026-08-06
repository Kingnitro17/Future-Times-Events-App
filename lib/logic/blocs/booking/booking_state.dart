import 'package:equatable/equatable.dart';
import '../../../data/models/event_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Payment intent is being created / Stripe sheet is being prepared.
class BookingProcessing extends BookingState {
  const BookingProcessing({
    required this.event,
    required this.selectedTicket,
    required this.quantity,
  });

  final EventModel event;
  final TicketClass selectedTicket;
  final int quantity;

  int get totalCents =>
      (selectedTicket.cost?.value ?? 0) * quantity;

  @override
  List<Object?> get props => [event, selectedTicket, quantity];
}

/// Stripe payment sheet is showing (waiting for user interaction).
class BookingAwaitingPayment extends BookingState {
  const BookingAwaitingPayment({
    required this.event,
    required this.selectedTicket,
    required this.quantity,
    required this.clientSecret,
  });

  final EventModel event;
  final TicketClass selectedTicket;
  final int quantity;
  final String clientSecret;

  @override
  List<Object?> get props => [event, selectedTicket, quantity, clientSecret];
}

/// Booking completed successfully.
class BookingSuccess extends BookingState {
  const BookingSuccess({
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

/// Opening in-app WebView to Eventbrite's own checkout.
class BookingExternalCheckout extends BookingState {
  const BookingExternalCheckout({
    required this.checkoutUrl,
    required this.event,
  });

  final String checkoutUrl;
  final EventModel event;

  @override
  List<Object?> get props => [checkoutUrl, event];
}

/// An error occurred during the booking process.
class BookingError extends BookingState {
  const BookingError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
