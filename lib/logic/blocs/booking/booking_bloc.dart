import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/services/payment_service.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required EventRepository eventRepository,
    required PaymentService paymentService,
  })  : _eventRepository = eventRepository,
        _paymentService = paymentService,
        super(const BookingInitial()) {
    on<InitiateBooking>(_onInitiateBooking);
    on<ConfirmPayment>(_onConfirmPayment);
    on<CancelBooking>(_onCancelBooking);
    on<OpenExternalCheckout>(_onOpenExternalCheckout);
    on<ResetBooking>(_onResetBooking);
  }

  final EventRepository _eventRepository;
  final PaymentService _paymentService;

  // ─── Initiate Booking ──────────────────────────────────────────────────────

  Future<void> _onInitiateBooking(
    InitiateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingProcessing(
      event: event.event,
      selectedTicket: event.selectedTicket,
      quantity: event.quantity,
    ));

    try {
      // If ticket is free, skip Stripe entirely
      if (event.selectedTicket.free ||
          (event.selectedTicket.cost?.value ?? 0) == 0) {
        emit(BookingSuccess(
          event: event.event,
          selectedTicket: event.selectedTicket,
          quantity: event.quantity,
        ));
        return;
      }

      final totalCents =
          (event.selectedTicket.cost?.value ?? 0) * event.quantity;
      final currency =
          event.selectedTicket.cost?.currency.toLowerCase() ?? 'usd';

      // Try native Stripe flow first
      try {
        final clientSecret = await _paymentService.createPaymentIntent(
          amountInCents: totalCents,
          currency: currency,
          eventId: event.event.id,
        );

        emit(BookingAwaitingPayment(
          event: event.event,
          selectedTicket: event.selectedTicket,
          quantity: event.quantity,
          clientSecret: clientSecret,
        ));
      } on UnimplementedError {
        // Backend not wired up yet → fall back to Eventbrite checkout URL
        final checkoutUrl = event.event.url;
        emit(BookingExternalCheckout(
          checkoutUrl: checkoutUrl,
          event: event.event,
        ));
      }
    } catch (e) {
      emit(BookingError(message: _friendlyError(e)));
    }
  }

  // ─── Confirm Payment ───────────────────────────────────────────────────────

  Future<void> _onConfirmPayment(
    ConfirmPayment event,
    Emitter<BookingState> emit,
  ) async {
    final current = state;
    if (current is! BookingAwaitingPayment) return;

    emit(BookingProcessing(
      event: current.event,
      selectedTicket: current.selectedTicket,
      quantity: current.quantity,
    ));

    try {
      final result = await _paymentService.confirmPayment(
        clientSecret: event.clientSecret,
        eventName: current.event.name.text,
        amountInCents: current.selectedTicket.cost?.value ?? 0,
        currency: current.selectedTicket.cost?.currency ?? 'USD',
      );

      switch (result) {
        case PaymentResult.success:
          emit(BookingSuccess(
            event: current.event,
            selectedTicket: current.selectedTicket,
            quantity: current.quantity,
          ));
        case PaymentResult.cancelled:
          emit(const BookingInitial());
        case PaymentResult.failed:
          emit(const BookingError(
            message: 'Payment failed. Please check your card details.',
          ));
      }
    } catch (e) {
      emit(BookingError(message: _friendlyError(e)));
    }
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────

  void _onCancelBooking(CancelBooking event, Emitter<BookingState> emit) {
    emit(const BookingInitial());
  }

  // ─── External Checkout ────────────────────────────────────────────────────

  void _onOpenExternalCheckout(
    OpenExternalCheckout event,
    Emitter<BookingState> emit,
  ) {
    final current = state;
    if (current is BookingProcessing) {
      emit(BookingExternalCheckout(
        checkoutUrl: event.checkoutUrl,
        event: current.event,
      ));
    }
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void _onResetBooking(ResetBooking event, Emitter<BookingState> emit) {
    emit(const BookingInitial());
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('card')) return 'Card declined. Please try another card.';
    if (msg.contains('network')) return 'Network error. Please try again.';
    return 'Payment could not be processed. Please try again.';
  }
}
