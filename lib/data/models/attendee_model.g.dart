// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendeeModelImpl _$$AttendeeModelImplFromJson(Map<String, dynamic> json) =>
    _$AttendeeModelImpl(
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      checkedInAt: json['checkedInAt'] == null
          ? null
          : DateTime.parse(json['checkedInAt'] as String),
    );

Map<String, dynamic> _$$AttendeeModelImplToJson(_$AttendeeModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'eventId': instance.eventId,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'checkedInAt': instance.checkedInAt?.toIso8601String(),
    };
