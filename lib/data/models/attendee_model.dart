// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendee_model.freezed.dart';
part 'attendee_model.g.dart';

/// Public Future Times attendee card backed by Supabase RSVP data.
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
}
