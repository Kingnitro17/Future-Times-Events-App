// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendee_model.freezed.dart';
part 'attendee_model.g.dart';

/// Firestore-native attendee — not from Eventbrite API.
/// Stored in: /attendees/{eventId}/checkins/{userId}
@freezed
class AttendeeModel with _$AttendeeModel {
  const AttendeeModel._();

  const factory AttendeeModel({
    required String userId,
    required String eventId,
    required String displayName,
    String? avatarUrl,
    @JsonKey(name: 'checkedInAt') DateTime? checkedInAt,
  }) = _AttendeeModel;

  factory AttendeeModel.fromJson(Map<String, dynamic> json) =>
      _$AttendeeModelFromJson(json);

  factory AttendeeModel.fromFirestore(
    Map<String, dynamic> data,
    String userId,
  ) {
    return AttendeeModel(
      userId: userId,
      eventId: data['eventId'] as String,
      displayName: data['displayName'] as String? ?? 'Anonymous',
      avatarUrl: data['avatarUrl'] as String?,
      checkedInAt:
          data['checkedInAt'] != null
              ? DateTime.parse(data['checkedInAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'eventId': eventId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'checkedInAt': checkedInAt?.toIso8601String(),
      };
}
