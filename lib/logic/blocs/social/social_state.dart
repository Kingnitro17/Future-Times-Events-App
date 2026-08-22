import 'package:equatable/equatable.dart';
import '../../../data/models/attendee_model.dart';

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {
  const SocialInitial();
}

class SocialLoading extends SocialState {
  const SocialLoading();
}

class SocialLoaded extends SocialState {
  const SocialLoaded({
    required this.attendees,
    required this.eventId,
    required this.goingCount,
    this.currentUserId,
  });

  final List<AttendeeModel> attendees;
  final String eventId;
  final int goingCount;
  final String? currentUserId;

  bool get isCurrentUserCheckedIn =>
      currentUserId != null && attendees.any((a) => a.userId == currentUserId);

  int get attendeeCount => goingCount;

  SocialLoaded copyWith({
    List<AttendeeModel>? attendees,
    String? eventId,
    int? goingCount,
    String? currentUserId,
  }) {
    return SocialLoaded(
      attendees: attendees ?? this.attendees,
      eventId: eventId ?? this.eventId,
      goingCount: goingCount ?? this.goingCount,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [attendees, eventId, goingCount, currentUserId];
}

class SocialError extends SocialState {
  const SocialError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
