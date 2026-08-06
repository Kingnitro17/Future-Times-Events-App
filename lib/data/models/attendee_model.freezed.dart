// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendee_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendeeModel _$AttendeeModelFromJson(Map<String, dynamic> json) {
  return _AttendeeModel.fromJson(json);
}

/// @nodoc
mixin _$AttendeeModel {
  String get userId => throw _privateConstructorUsedError;
  String get eventId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'checkedInAt')
  DateTime? get checkedInAt => throw _privateConstructorUsedError;

  /// Serializes this AttendeeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttendeeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendeeModelCopyWith<AttendeeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendeeModelCopyWith<$Res> {
  factory $AttendeeModelCopyWith(
          AttendeeModel value, $Res Function(AttendeeModel) then) =
      _$AttendeeModelCopyWithImpl<$Res, AttendeeModel>;
  @useResult
  $Res call(
      {String userId,
      String eventId,
      String displayName,
      String? avatarUrl,
      @JsonKey(name: 'checkedInAt') DateTime? checkedInAt});
}

/// @nodoc
class _$AttendeeModelCopyWithImpl<$Res, $Val extends AttendeeModel>
    implements $AttendeeModelCopyWith<$Res> {
  _$AttendeeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendeeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? eventId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? checkedInAt = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedInAt: freezed == checkedInAt
          ? _value.checkedInAt
          : checkedInAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendeeModelImplCopyWith<$Res>
    implements $AttendeeModelCopyWith<$Res> {
  factory _$$AttendeeModelImplCopyWith(
          _$AttendeeModelImpl value, $Res Function(_$AttendeeModelImpl) then) =
      __$$AttendeeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String eventId,
      String displayName,
      String? avatarUrl,
      @JsonKey(name: 'checkedInAt') DateTime? checkedInAt});
}

/// @nodoc
class __$$AttendeeModelImplCopyWithImpl<$Res>
    extends _$AttendeeModelCopyWithImpl<$Res, _$AttendeeModelImpl>
    implements _$$AttendeeModelImplCopyWith<$Res> {
  __$$AttendeeModelImplCopyWithImpl(
      _$AttendeeModelImpl _value, $Res Function(_$AttendeeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendeeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? eventId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? checkedInAt = freezed,
  }) {
    return _then(_$AttendeeModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      checkedInAt: freezed == checkedInAt
          ? _value.checkedInAt
          : checkedInAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendeeModelImpl extends _AttendeeModel {
  const _$AttendeeModelImpl(
      {required this.userId,
      required this.eventId,
      required this.displayName,
      this.avatarUrl,
      @JsonKey(name: 'checkedInAt') this.checkedInAt})
      : super._();

  factory _$AttendeeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendeeModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String eventId;
  @override
  final String displayName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey(name: 'checkedInAt')
  final DateTime? checkedInAt;

  @override
  String toString() {
    return 'AttendeeModel(userId: $userId, eventId: $eventId, displayName: $displayName, avatarUrl: $avatarUrl, checkedInAt: $checkedInAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendeeModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.checkedInAt, checkedInAt) ||
                other.checkedInAt == checkedInAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, userId, eventId, displayName, avatarUrl, checkedInAt);

  /// Create a copy of AttendeeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendeeModelImplCopyWith<_$AttendeeModelImpl> get copyWith =>
      __$$AttendeeModelImplCopyWithImpl<_$AttendeeModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendeeModelImplToJson(
      this,
    );
  }
}

abstract class _AttendeeModel extends AttendeeModel {
  const factory _AttendeeModel(
          {required final String userId,
          required final String eventId,
          required final String displayName,
          final String? avatarUrl,
          @JsonKey(name: 'checkedInAt') final DateTime? checkedInAt}) =
      _$AttendeeModelImpl;
  const _AttendeeModel._() : super._();

  factory _AttendeeModel.fromJson(Map<String, dynamic> json) =
      _$AttendeeModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get eventId;
  @override
  String get displayName;
  @override
  String? get avatarUrl;
  @override
  @JsonKey(name: 'checkedInAt')
  DateTime? get checkedInAt;

  /// Create a copy of AttendeeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendeeModelImplCopyWith<_$AttendeeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
