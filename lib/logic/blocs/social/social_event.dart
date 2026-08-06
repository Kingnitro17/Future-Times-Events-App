import 'package:equatable/equatable.dart';
import '../../../data/models/attendee_model.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

/// Start watching Firestore attendees for an event (real-time stream).
class WatchAttendees extends SocialEvent {
  const WatchAttendees({required this.eventId});

  final String eventId;

  @override
  List<Object?> get props => [eventId];
}

/// Internal: emitted when the Firestore stream emits new data.
class AttendeesUpdated extends SocialEvent {
  const AttendeesUpdated({required this.attendees});

  final List<AttendeeModel> attendees;

  @override
  List<Object?> get props => [attendees];
}

/// User taps "I'm Going" — checks in to an event.
class CheckInToEvent extends SocialEvent {
  const CheckInToEvent({
    required this.eventId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String eventId;
  final String userId;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [eventId, userId, displayName, avatarUrl];
}

/// User removes their check-in.
class CheckOutFromEvent extends SocialEvent {
  const CheckOutFromEvent({
    required this.eventId,
    required this.userId,
  });

  final String eventId;
  final String userId;

  @override
  List<Object?> get props => [eventId, userId];
}
