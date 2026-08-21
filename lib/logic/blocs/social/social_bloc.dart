import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/social_repository.dart';
import 'social_event.dart';
import 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  SocialBloc({required SocialRepository socialRepository})
      : _repository = socialRepository,
        super(const SocialInitial()) {
    on<WatchAttendees>(_onWatchAttendees);
    on<AttendeesUpdated>(_onAttendeesUpdated);
    on<CheckInToEvent>(_onCheckIn);
    on<CheckOutFromEvent>(_onCheckOut);
  }

  final SocialRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  // ─── Watch Attendees ───────────────────────────────────────────────────────

  Future<void> _onWatchAttendees(
    WatchAttendees event,
    Emitter<SocialState> emit,
  ) async {
    await _subscription?.cancel();
    emit(const SocialLoading());

    _subscription = _repository.watchAttendees(event.eventId).listen(
          (attendees) => add(AttendeesUpdated(attendees: attendees)),
          onError: (_) => emit(const SocialError(
            message: 'Who\'s Going is temporarily unavailable.',
          )),
        );

    // Keep the event handler alive for the lifetime of the stream
    await emit.forEach<SocialState>(
      const Stream<SocialState>.empty(),
      onData: (s) => s,
    );
  }

  // ─── Attendees Updated (internal stream event) ─────────────────────────────

  void _onAttendeesUpdated(
    AttendeesUpdated event,
    Emitter<SocialState> emit,
  ) {
    final current = state;
    final currentUserId =
        current is SocialLoaded ? current.currentUserId : null;

    // Preserve current eventId if already loaded
    final eventId = current is SocialLoaded ? current.eventId : '';

    emit(SocialLoaded(
      attendees: event.attendees,
      eventId: eventId,
      currentUserId: currentUserId,
    ));
  }

  // ─── Check In ─────────────────────────────────────────────────────────────

  Future<void> _onCheckIn(
    CheckInToEvent event,
    Emitter<SocialState> emit,
  ) async {
    try {
      await _repository.checkIn(
        eventId: event.eventId,
        userId: event.userId,
        displayName: event.displayName,
        avatarUrl: event.avatarUrl,
      );
      // Stream will auto-update state via WatchAttendees
    } catch (_) {
      emit(
          const SocialError(message: 'Could not update your RSVP. Try again.'));
    }
  }

  // ─── Check Out ────────────────────────────────────────────────────────────

  Future<void> _onCheckOut(
    CheckOutFromEvent event,
    Emitter<SocialState> emit,
  ) async {
    try {
      await _repository.checkOut(
        eventId: event.eventId,
        userId: event.userId,
      );
      // Stream will auto-update state via WatchAttendees
    } catch (_) {
      emit(
          const SocialError(message: 'Could not update your RSVP. Try again.'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
