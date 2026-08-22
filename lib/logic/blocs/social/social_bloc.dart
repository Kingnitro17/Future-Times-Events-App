import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/attendee_model.dart';
import '../../../data/repositories/social_repository.dart';
import 'social_event.dart';
import 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  SocialBloc({required SocialRepository socialRepository})
      : _repository = socialRepository,
        super(const SocialInitial()) {
    on<WatchAttendees>(_onWatchAttendees);
    on<CheckInToEvent>(_onCheckIn);
    on<CheckOutFromEvent>(_onCheckOut);
  }

  final SocialRepository _repository;

  Future<void> _onWatchAttendees(
    WatchAttendees event,
    Emitter<SocialState> emit,
  ) async {
    emit(const SocialLoading());
    try {
      final results = await Future.wait<Object>([
        _repository.getAttendees(event.eventId),
        _repository.getAttendeeCount(event.eventId),
      ]);
      emit(SocialLoaded(
        attendees: results[0] as List<AttendeeModel>,
        eventId: event.eventId,
        goingCount: results[1] as int,
      ));
    } catch (_) {
      emit(const SocialError(
        message: 'Who\'s Going is temporarily unavailable.',
      ));
    }
  }

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
      add(WatchAttendees(eventId: event.eventId));
    } catch (_) {
      emit(
          const SocialError(message: 'Could not update your RSVP. Try again.'));
    }
  }

  Future<void> _onCheckOut(
    CheckOutFromEvent event,
    Emitter<SocialState> emit,
  ) async {
    try {
      await _repository.checkOut(
        eventId: event.eventId,
        userId: event.userId,
      );
      add(WatchAttendees(eventId: event.eventId));
    } catch (_) {
      emit(
          const SocialError(message: 'Could not update your RSVP. Try again.'));
    }
  }
}
