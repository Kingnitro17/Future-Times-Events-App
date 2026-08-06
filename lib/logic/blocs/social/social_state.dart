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
    this.currentUserId,
  });

  final List<AttendeeModel> attendees;
  final String eventId;
  final String? currentUserId;

  bool get isCurrentUserCheckedIn =>
      currentUserId != null &&
      attendees.any((a) => a.userId == currentUserId);

  int get attendeeCount => attendees.length;

  SocialLoaded copyWith({
    List<AttendeeModel>? attendees,
    String? eventId,
    String? currentUserId,
  }) {
    return SocialLoaded(
      attendees: attendees ?? this.attendees,
      eventId: eventId ?? this.eventId,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [attendees, eventId, currentUserId];
}

class SocialError extends SocialState {
  const SocialError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
