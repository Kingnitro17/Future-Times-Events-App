// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EventModel _$EventModelFromJson(Map<String, dynamic> json) {
  return _EventModel.fromJson(json);
}

/// @nodoc
mixin _$EventModel {
  String get id => throw _privateConstructorUsedError;
  EventText get name => throw _privateConstructorUsedError;
  EventText? get description => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  EventDateTime get start => throw _privateConstructorUsedError;
  EventDateTime get end => throw _privateConstructorUsedError;
  EventImage? get logo => throw _privateConstructorUsedError;
  VenueModel? get venue => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get subcategoryId => throw _privateConstructorUsedError;
  bool get isFree => throw _privateConstructorUsedError;
  bool get isOnlineEvent => throw _privateConstructorUsedError;
  int? get capacity => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get currency => throw _privateConstructorUsedError;
  List<TicketClass> get ticketClasses => throw _privateConstructorUsedError;

  /// Serializes this EventModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventModelCopyWith<EventModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventModelCopyWith<$Res> {
  factory $EventModelCopyWith(
          EventModel value, $Res Function(EventModel) then) =
      _$EventModelCopyWithImpl<$Res, EventModel>;
  @useResult
  $Res call(
      {String id,
      EventText name,
      EventText? description,
      String url,
      EventDateTime start,
      EventDateTime end,
      EventImage? logo,
      VenueModel? venue,
      String? categoryId,
      String? subcategoryId,
      bool isFree,
      bool isOnlineEvent,
      int? capacity,
      String? status,
      String? currency,
      List<TicketClass> ticketClasses});

  $EventTextCopyWith<$Res> get name;
  $EventTextCopyWith<$Res>? get description;
  $EventDateTimeCopyWith<$Res> get start;
  $EventDateTimeCopyWith<$Res> get end;
  $EventImageCopyWith<$Res>? get logo;
  $VenueModelCopyWith<$Res>? get venue;
}

/// @nodoc
class _$EventModelCopyWithImpl<$Res, $Val extends EventModel>
    implements $EventModelCopyWith<$Res> {
  _$EventModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? url = null,
    Object? start = null,
    Object? end = null,
    Object? logo = freezed,
    Object? venue = freezed,
    Object? categoryId = freezed,
    Object? subcategoryId = freezed,
    Object? isFree = null,
    Object? isOnlineEvent = null,
    Object? capacity = freezed,
    Object? status = freezed,
    Object? currency = freezed,
    Object? ticketClasses = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as EventText,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as EventText?,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as EventDateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as EventDateTime,
      logo: freezed == logo
          ? _value.logo
          : logo // ignore: cast_nullable_to_non_nullable
              as EventImage?,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as VenueModel?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      subcategoryId: freezed == subcategoryId
          ? _value.subcategoryId
          : subcategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFree: null == isFree
          ? _value.isFree
          : isFree // ignore: cast_nullable_to_non_nullable
              as bool,
      isOnlineEvent: null == isOnlineEvent
          ? _value.isOnlineEvent
          : isOnlineEvent // ignore: cast_nullable_to_non_nullable
              as bool,
      capacity: freezed == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      currency: freezed == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String?,
      ticketClasses: null == ticketClasses
          ? _value.ticketClasses
          : ticketClasses // ignore: cast_nullable_to_non_nullable
              as List<TicketClass>,
    ) as $Val);
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventTextCopyWith<$Res> get name {
    return $EventTextCopyWith<$Res>(_value.name, (value) {
      return _then(_value.copyWith(name: value) as $Val);
    });
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventTextCopyWith<$Res>? get description {
    if (_value.description == null) {
      return null;
    }

    return $EventTextCopyWith<$Res>(_value.description!, (value) {
      return _then(_value.copyWith(description: value) as $Val);
    });
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventDateTimeCopyWith<$Res> get start {
    return $EventDateTimeCopyWith<$Res>(_value.start, (value) {
      return _then(_value.copyWith(start: value) as $Val);
    });
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventDateTimeCopyWith<$Res> get end {
    return $EventDateTimeCopyWith<$Res>(_value.end, (value) {
      return _then(_value.copyWith(end: value) as $Val);
    });
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventImageCopyWith<$Res>? get logo {
    if (_value.logo == null) {
      return null;
    }

    return $EventImageCopyWith<$Res>(_value.logo!, (value) {
      return _then(_value.copyWith(logo: value) as $Val);
    });
  }

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VenueModelCopyWith<$Res>? get venue {
    if (_value.venue == null) {
      return null;
    }

    return $VenueModelCopyWith<$Res>(_value.venue!, (value) {
      return _then(_value.copyWith(venue: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EventModelImplCopyWith<$Res>
    implements $EventModelCopyWith<$Res> {
  factory _$$EventModelImplCopyWith(
          _$EventModelImpl value, $Res Function(_$EventModelImpl) then) =
      __$$EventModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      EventText name,
      EventText? description,
      String url,
      EventDateTime start,
      EventDateTime end,
      EventImage? logo,
      VenueModel? venue,
      String? categoryId,
      String? subcategoryId,
      bool isFree,
      bool isOnlineEvent,
      int? capacity,
      String? status,
      String? currency,
      List<TicketClass> ticketClasses});

  @override
  $EventTextCopyWith<$Res> get name;
  @override
  $EventTextCopyWith<$Res>? get description;
  @override
  $EventDateTimeCopyWith<$Res> get start;
  @override
  $EventDateTimeCopyWith<$Res> get end;
  @override
  $EventImageCopyWith<$Res>? get logo;
  @override
  $VenueModelCopyWith<$Res>? get venue;
}

/// @nodoc
class __$$EventModelImplCopyWithImpl<$Res>
    extends _$EventModelCopyWithImpl<$Res, _$EventModelImpl>
    implements _$$EventModelImplCopyWith<$Res> {
  __$$EventModelImplCopyWithImpl(
      _$EventModelImpl _value, $Res Function(_$EventModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? url = null,
    Object? start = null,
    Object? end = null,
    Object? logo = freezed,
    Object? venue = freezed,
    Object? categoryId = freezed,
    Object? subcategoryId = freezed,
    Object? isFree = null,
    Object? isOnlineEvent = null,
    Object? capacity = freezed,
    Object? status = freezed,
    Object? currency = freezed,
    Object? ticketClasses = null,
  }) {
    return _then(_$EventModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as EventText,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as EventText?,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as EventDateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as EventDateTime,
      logo: freezed == logo
          ? _value.logo
          : logo // ignore: cast_nullable_to_non_nullable
              as EventImage?,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as VenueModel?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      subcategoryId: freezed == subcategoryId
          ? _value.subcategoryId
          : subcategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFree: null == isFree
          ? _value.isFree
          : isFree // ignore: cast_nullable_to_non_nullable
              as bool,
      isOnlineEvent: null == isOnlineEvent
          ? _value.isOnlineEvent
          : isOnlineEvent // ignore: cast_nullable_to_non_nullable
              as bool,
      capacity: freezed == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      currency: freezed == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String?,
      ticketClasses: null == ticketClasses
          ? _value._ticketClasses
          : ticketClasses // ignore: cast_nullable_to_non_nullable
              as List<TicketClass>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventModelImpl implements _EventModel {
  const _$EventModelImpl(
      {required this.id,
      required this.name,
      this.description,
      required this.url,
      required this.start,
      required this.end,
      this.logo,
      this.venue,
      this.categoryId,
      this.subcategoryId,
      this.isFree = false,
      this.isOnlineEvent = false,
      this.capacity,
      this.status,
      this.currency,
      final List<TicketClass> ticketClasses = const []})
      : _ticketClasses = ticketClasses;

  factory _$EventModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventModelImplFromJson(json);

  @override
  final String id;
  @override
  final EventText name;
  @override
  final EventText? description;
  @override
  final String url;
  @override
  final EventDateTime start;
  @override
  final EventDateTime end;
  @override
  final EventImage? logo;
  @override
  final VenueModel? venue;
  @override
  final String? categoryId;
  @override
  final String? subcategoryId;
  @override
  @JsonKey()
  final bool isFree;
  @override
  @JsonKey()
  final bool isOnlineEvent;
  @override
  final int? capacity;
  @override
  final String? status;
  @override
  final String? currency;
  final List<TicketClass> _ticketClasses;
  @override
  @JsonKey()
  List<TicketClass> get ticketClasses {
    if (_ticketClasses is EqualUnmodifiableListView) return _ticketClasses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ticketClasses);
  }

  @override
  String toString() {
    return 'EventModel(id: $id, name: $name, description: $description, url: $url, start: $start, end: $end, logo: $logo, venue: $venue, categoryId: $categoryId, subcategoryId: $subcategoryId, isFree: $isFree, isOnlineEvent: $isOnlineEvent, capacity: $capacity, status: $status, currency: $currency, ticketClasses: $ticketClasses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.logo, logo) || other.logo == logo) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.subcategoryId, subcategoryId) ||
                other.subcategoryId == subcategoryId) &&
            (identical(other.isFree, isFree) || other.isFree == isFree) &&
            (identical(other.isOnlineEvent, isOnlineEvent) ||
                other.isOnlineEvent == isOnlineEvent) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            const DeepCollectionEquality()
                .equals(other._ticketClasses, _ticketClasses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      url,
      start,
      end,
      logo,
      venue,
      categoryId,
      subcategoryId,
      isFree,
      isOnlineEvent,
      capacity,
      status,
      currency,
      const DeepCollectionEquality().hash(_ticketClasses));

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventModelImplCopyWith<_$EventModelImpl> get copyWith =>
      __$$EventModelImplCopyWithImpl<_$EventModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventModelImplToJson(
      this,
    );
  }
}

abstract class _EventModel implements EventModel {
  const factory _EventModel(
      {required final String id,
      required final EventText name,
      final EventText? description,
      required final String url,
      required final EventDateTime start,
      required final EventDateTime end,
      final EventImage? logo,
      final VenueModel? venue,
      final String? categoryId,
      final String? subcategoryId,
      final bool isFree,
      final bool isOnlineEvent,
      final int? capacity,
      final String? status,
      final String? currency,
      final List<TicketClass> ticketClasses}) = _$EventModelImpl;

  factory _EventModel.fromJson(Map<String, dynamic> json) =
      _$EventModelImpl.fromJson;

  @override
  String get id;
  @override
  EventText get name;
  @override
  EventText? get description;
  @override
  String get url;
  @override
  EventDateTime get start;
  @override
  EventDateTime get end;
  @override
  EventImage? get logo;
  @override
  VenueModel? get venue;
  @override
  String? get categoryId;
  @override
  String? get subcategoryId;
  @override
  bool get isFree;
  @override
  bool get isOnlineEvent;
  @override
  int? get capacity;
  @override
  String? get status;
  @override
  String? get currency;
  @override
  List<TicketClass> get ticketClasses;

  /// Create a copy of EventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventModelImplCopyWith<_$EventModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventText _$EventTextFromJson(Map<String, dynamic> json) {
  return _EventText.fromJson(json);
}

/// @nodoc
mixin _$EventText {
  String get text => throw _privateConstructorUsedError;
  String get html => throw _privateConstructorUsedError;

  /// Serializes this EventText to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventText
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventTextCopyWith<EventText> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventTextCopyWith<$Res> {
  factory $EventTextCopyWith(EventText value, $Res Function(EventText) then) =
      _$EventTextCopyWithImpl<$Res, EventText>;
  @useResult
  $Res call({String text, String html});
}

/// @nodoc
class _$EventTextCopyWithImpl<$Res, $Val extends EventText>
    implements $EventTextCopyWith<$Res> {
  _$EventTextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventText
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? html = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      html: null == html
          ? _value.html
          : html // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventTextImplCopyWith<$Res>
    implements $EventTextCopyWith<$Res> {
  factory _$$EventTextImplCopyWith(
          _$EventTextImpl value, $Res Function(_$EventTextImpl) then) =
      __$$EventTextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, String html});
}

/// @nodoc
class __$$EventTextImplCopyWithImpl<$Res>
    extends _$EventTextCopyWithImpl<$Res, _$EventTextImpl>
    implements _$$EventTextImplCopyWith<$Res> {
  __$$EventTextImplCopyWithImpl(
      _$EventTextImpl _value, $Res Function(_$EventTextImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventText
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? html = null,
  }) {
    return _then(_$EventTextImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      html: null == html
          ? _value.html
          : html // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventTextImpl implements _EventText {
  const _$EventTextImpl({required this.text, required this.html});

  factory _$EventTextImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventTextImplFromJson(json);

  @override
  final String text;
  @override
  final String html;

  @override
  String toString() {
    return 'EventText(text: $text, html: $html)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventTextImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.html, html) || other.html == html));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, html);

  /// Create a copy of EventText
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventTextImplCopyWith<_$EventTextImpl> get copyWith =>
      __$$EventTextImplCopyWithImpl<_$EventTextImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventTextImplToJson(
      this,
    );
  }
}

abstract class _EventText implements EventText {
  const factory _EventText(
      {required final String text,
      required final String html}) = _$EventTextImpl;

  factory _EventText.fromJson(Map<String, dynamic> json) =
      _$EventTextImpl.fromJson;

  @override
  String get text;
  @override
  String get html;

  /// Create a copy of EventText
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventTextImplCopyWith<_$EventTextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventDateTime _$EventDateTimeFromJson(Map<String, dynamic> json) {
  return _EventDateTime.fromJson(json);
}

/// @nodoc
mixin _$EventDateTime {
  String get timezone => throw _privateConstructorUsedError;
  String get utc => throw _privateConstructorUsedError;
  String get local => throw _privateConstructorUsedError;

  /// Serializes this EventDateTime to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventDateTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventDateTimeCopyWith<EventDateTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventDateTimeCopyWith<$Res> {
  factory $EventDateTimeCopyWith(
          EventDateTime value, $Res Function(EventDateTime) then) =
      _$EventDateTimeCopyWithImpl<$Res, EventDateTime>;
  @useResult
  $Res call({String timezone, String utc, String local});
}

/// @nodoc
class _$EventDateTimeCopyWithImpl<$Res, $Val extends EventDateTime>
    implements $EventDateTimeCopyWith<$Res> {
  _$EventDateTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventDateTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timezone = null,
    Object? utc = null,
    Object? local = null,
  }) {
    return _then(_value.copyWith(
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      utc: null == utc
          ? _value.utc
          : utc // ignore: cast_nullable_to_non_nullable
              as String,
      local: null == local
          ? _value.local
          : local // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventDateTimeImplCopyWith<$Res>
    implements $EventDateTimeCopyWith<$Res> {
  factory _$$EventDateTimeImplCopyWith(
          _$EventDateTimeImpl value, $Res Function(_$EventDateTimeImpl) then) =
      __$$EventDateTimeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timezone, String utc, String local});
}

/// @nodoc
class __$$EventDateTimeImplCopyWithImpl<$Res>
    extends _$EventDateTimeCopyWithImpl<$Res, _$EventDateTimeImpl>
    implements _$$EventDateTimeImplCopyWith<$Res> {
  __$$EventDateTimeImplCopyWithImpl(
      _$EventDateTimeImpl _value, $Res Function(_$EventDateTimeImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventDateTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timezone = null,
    Object? utc = null,
    Object? local = null,
  }) {
    return _then(_$EventDateTimeImpl(
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      utc: null == utc
          ? _value.utc
          : utc // ignore: cast_nullable_to_non_nullable
              as String,
      local: null == local
          ? _value.local
          : local // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventDateTimeImpl implements _EventDateTime {
  const _$EventDateTimeImpl(
      {required this.timezone, required this.utc, required this.local});

  factory _$EventDateTimeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventDateTimeImplFromJson(json);

  @override
  final String timezone;
  @override
  final String utc;
  @override
  final String local;

  @override
  String toString() {
    return 'EventDateTime(timezone: $timezone, utc: $utc, local: $local)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventDateTimeImpl &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.utc, utc) || other.utc == utc) &&
            (identical(other.local, local) || other.local == local));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timezone, utc, local);

  /// Create a copy of EventDateTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventDateTimeImplCopyWith<_$EventDateTimeImpl> get copyWith =>
      __$$EventDateTimeImplCopyWithImpl<_$EventDateTimeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventDateTimeImplToJson(
      this,
    );
  }
}

abstract class _EventDateTime implements EventDateTime {
  const factory _EventDateTime(
      {required final String timezone,
      required final String utc,
      required final String local}) = _$EventDateTimeImpl;

  factory _EventDateTime.fromJson(Map<String, dynamic> json) =
      _$EventDateTimeImpl.fromJson;

  @override
  String get timezone;
  @override
  String get utc;
  @override
  String get local;

  /// Create a copy of EventDateTime
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventDateTimeImplCopyWith<_$EventDateTimeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventImage _$EventImageFromJson(Map<String, dynamic> json) {
  return _EventImage.fromJson(json);
}

/// @nodoc
mixin _$EventImage {
  String get id => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  EventImageDimensions? get original => throw _privateConstructorUsedError;
  EventImageDimensions? get crop => throw _privateConstructorUsedError;

  /// Serializes this EventImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventImageCopyWith<EventImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventImageCopyWith<$Res> {
  factory $EventImageCopyWith(
          EventImage value, $Res Function(EventImage) then) =
      _$EventImageCopyWithImpl<$Res, EventImage>;
  @useResult
  $Res call(
      {String id,
      String? url,
      EventImageDimensions? original,
      EventImageDimensions? crop});

  $EventImageDimensionsCopyWith<$Res>? get original;
  $EventImageDimensionsCopyWith<$Res>? get crop;
}

/// @nodoc
class _$EventImageCopyWithImpl<$Res, $Val extends EventImage>
    implements $EventImageCopyWith<$Res> {
  _$EventImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = freezed,
    Object? original = freezed,
    Object? crop = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      original: freezed == original
          ? _value.original
          : original // ignore: cast_nullable_to_non_nullable
              as EventImageDimensions?,
      crop: freezed == crop
          ? _value.crop
          : crop // ignore: cast_nullable_to_non_nullable
              as EventImageDimensions?,
    ) as $Val);
  }

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventImageDimensionsCopyWith<$Res>? get original {
    if (_value.original == null) {
      return null;
    }

    return $EventImageDimensionsCopyWith<$Res>(_value.original!, (value) {
      return _then(_value.copyWith(original: value) as $Val);
    });
  }

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventImageDimensionsCopyWith<$Res>? get crop {
    if (_value.crop == null) {
      return null;
    }

    return $EventImageDimensionsCopyWith<$Res>(_value.crop!, (value) {
      return _then(_value.copyWith(crop: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EventImageImplCopyWith<$Res>
    implements $EventImageCopyWith<$Res> {
  factory _$$EventImageImplCopyWith(
          _$EventImageImpl value, $Res Function(_$EventImageImpl) then) =
      __$$EventImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? url,
      EventImageDimensions? original,
      EventImageDimensions? crop});

  @override
  $EventImageDimensionsCopyWith<$Res>? get original;
  @override
  $EventImageDimensionsCopyWith<$Res>? get crop;
}

/// @nodoc
class __$$EventImageImplCopyWithImpl<$Res>
    extends _$EventImageCopyWithImpl<$Res, _$EventImageImpl>
    implements _$$EventImageImplCopyWith<$Res> {
  __$$EventImageImplCopyWithImpl(
      _$EventImageImpl _value, $Res Function(_$EventImageImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = freezed,
    Object? original = freezed,
    Object? crop = freezed,
  }) {
    return _then(_$EventImageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      original: freezed == original
          ? _value.original
          : original // ignore: cast_nullable_to_non_nullable
              as EventImageDimensions?,
      crop: freezed == crop
          ? _value.crop
          : crop // ignore: cast_nullable_to_non_nullable
              as EventImageDimensions?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventImageImpl implements _EventImage {
  const _$EventImageImpl(
      {required this.id, this.url, this.original, this.crop});

  factory _$EventImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventImageImplFromJson(json);

  @override
  final String id;
  @override
  final String? url;
  @override
  final EventImageDimensions? original;
  @override
  final EventImageDimensions? crop;

  @override
  String toString() {
    return 'EventImage(id: $id, url: $url, original: $original, crop: $crop)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventImageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.original, original) ||
                other.original == original) &&
            (identical(other.crop, crop) || other.crop == crop));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, original, crop);

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventImageImplCopyWith<_$EventImageImpl> get copyWith =>
      __$$EventImageImplCopyWithImpl<_$EventImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventImageImplToJson(
      this,
    );
  }
}

abstract class _EventImage implements EventImage {
  const factory _EventImage(
      {required final String id,
      final String? url,
      final EventImageDimensions? original,
      final EventImageDimensions? crop}) = _$EventImageImpl;

  factory _EventImage.fromJson(Map<String, dynamic> json) =
      _$EventImageImpl.fromJson;

  @override
  String get id;
  @override
  String? get url;
  @override
  EventImageDimensions? get original;
  @override
  EventImageDimensions? get crop;

  /// Create a copy of EventImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventImageImplCopyWith<_$EventImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventImageDimensions _$EventImageDimensionsFromJson(Map<String, dynamic> json) {
  return _EventImageDimensions.fromJson(json);
}

/// @nodoc
mixin _$EventImageDimensions {
  String get url => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;

  /// Serializes this EventImageDimensions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventImageDimensions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventImageDimensionsCopyWith<EventImageDimensions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventImageDimensionsCopyWith<$Res> {
  factory $EventImageDimensionsCopyWith(EventImageDimensions value,
          $Res Function(EventImageDimensions) then) =
      _$EventImageDimensionsCopyWithImpl<$Res, EventImageDimensions>;
  @useResult
  $Res call({String url, int? width, int? height});
}

/// @nodoc
class _$EventImageDimensionsCopyWithImpl<$Res,
        $Val extends EventImageDimensions>
    implements $EventImageDimensionsCopyWith<$Res> {
  _$EventImageDimensionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventImageDimensions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
  }) {
    return _then(_value.copyWith(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventImageDimensionsImplCopyWith<$Res>
    implements $EventImageDimensionsCopyWith<$Res> {
  factory _$$EventImageDimensionsImplCopyWith(_$EventImageDimensionsImpl value,
          $Res Function(_$EventImageDimensionsImpl) then) =
      __$$EventImageDimensionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String url, int? width, int? height});
}

/// @nodoc
class __$$EventImageDimensionsImplCopyWithImpl<$Res>
    extends _$EventImageDimensionsCopyWithImpl<$Res, _$EventImageDimensionsImpl>
    implements _$$EventImageDimensionsImplCopyWith<$Res> {
  __$$EventImageDimensionsImplCopyWithImpl(_$EventImageDimensionsImpl _value,
      $Res Function(_$EventImageDimensionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventImageDimensions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
  }) {
    return _then(_$EventImageDimensionsImpl(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventImageDimensionsImpl implements _EventImageDimensions {
  const _$EventImageDimensionsImpl(
      {required this.url, this.width, this.height});

  factory _$EventImageDimensionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventImageDimensionsImplFromJson(json);

  @override
  final String url;
  @override
  final int? width;
  @override
  final int? height;

  @override
  String toString() {
    return 'EventImageDimensions(url: $url, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventImageDimensionsImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url, width, height);

  /// Create a copy of EventImageDimensions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventImageDimensionsImplCopyWith<_$EventImageDimensionsImpl>
      get copyWith =>
          __$$EventImageDimensionsImplCopyWithImpl<_$EventImageDimensionsImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventImageDimensionsImplToJson(
      this,
    );
  }
}

abstract class _EventImageDimensions implements EventImageDimensions {
  const factory _EventImageDimensions(
      {required final String url,
      final int? width,
      final int? height}) = _$EventImageDimensionsImpl;

  factory _EventImageDimensions.fromJson(Map<String, dynamic> json) =
      _$EventImageDimensionsImpl.fromJson;

  @override
  String get url;
  @override
  int? get width;
  @override
  int? get height;

  /// Create a copy of EventImageDimensions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventImageDimensionsImplCopyWith<_$EventImageDimensionsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TicketClass _$TicketClassFromJson(Map<String, dynamic> json) {
  return _TicketClass.fromJson(json);
}

/// @nodoc
mixin _$TicketClass {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get free => throw _privateConstructorUsedError;
  EventCost? get cost => throw _privateConstructorUsedError;
  int? get quantityTotal => throw _privateConstructorUsedError;
  int? get quantitySold => throw _privateConstructorUsedError;
  String? get salesStart => throw _privateConstructorUsedError;
  String? get salesEnd => throw _privateConstructorUsedError;
  bool get hidden => throw _privateConstructorUsedError;

  /// Serializes this TicketClass to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketClassCopyWith<TicketClass> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketClassCopyWith<$Res> {
  factory $TicketClassCopyWith(
          TicketClass value, $Res Function(TicketClass) then) =
      _$TicketClassCopyWithImpl<$Res, TicketClass>;
  @useResult
  $Res call(
      {String id,
      String name,
      bool free,
      EventCost? cost,
      int? quantityTotal,
      int? quantitySold,
      String? salesStart,
      String? salesEnd,
      bool hidden});

  $EventCostCopyWith<$Res>? get cost;
}

/// @nodoc
class _$TicketClassCopyWithImpl<$Res, $Val extends TicketClass>
    implements $TicketClassCopyWith<$Res> {
  _$TicketClassCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? free = null,
    Object? cost = freezed,
    Object? quantityTotal = freezed,
    Object? quantitySold = freezed,
    Object? salesStart = freezed,
    Object? salesEnd = freezed,
    Object? hidden = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      free: null == free
          ? _value.free
          : free // ignore: cast_nullable_to_non_nullable
              as bool,
      cost: freezed == cost
          ? _value.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as EventCost?,
      quantityTotal: freezed == quantityTotal
          ? _value.quantityTotal
          : quantityTotal // ignore: cast_nullable_to_non_nullable
              as int?,
      quantitySold: freezed == quantitySold
          ? _value.quantitySold
          : quantitySold // ignore: cast_nullable_to_non_nullable
              as int?,
      salesStart: freezed == salesStart
          ? _value.salesStart
          : salesStart // ignore: cast_nullable_to_non_nullable
              as String?,
      salesEnd: freezed == salesEnd
          ? _value.salesEnd
          : salesEnd // ignore: cast_nullable_to_non_nullable
              as String?,
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventCostCopyWith<$Res>? get cost {
    if (_value.cost == null) {
      return null;
    }

    return $EventCostCopyWith<$Res>(_value.cost!, (value) {
      return _then(_value.copyWith(cost: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TicketClassImplCopyWith<$Res>
    implements $TicketClassCopyWith<$Res> {
  factory _$$TicketClassImplCopyWith(
          _$TicketClassImpl value, $Res Function(_$TicketClassImpl) then) =
      __$$TicketClassImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      bool free,
      EventCost? cost,
      int? quantityTotal,
      int? quantitySold,
      String? salesStart,
      String? salesEnd,
      bool hidden});

  @override
  $EventCostCopyWith<$Res>? get cost;
}

/// @nodoc
class __$$TicketClassImplCopyWithImpl<$Res>
    extends _$TicketClassCopyWithImpl<$Res, _$TicketClassImpl>
    implements _$$TicketClassImplCopyWith<$Res> {
  __$$TicketClassImplCopyWithImpl(
      _$TicketClassImpl _value, $Res Function(_$TicketClassImpl) _then)
      : super(_value, _then);

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? free = null,
    Object? cost = freezed,
    Object? quantityTotal = freezed,
    Object? quantitySold = freezed,
    Object? salesStart = freezed,
    Object? salesEnd = freezed,
    Object? hidden = null,
  }) {
    return _then(_$TicketClassImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      free: null == free
          ? _value.free
          : free // ignore: cast_nullable_to_non_nullable
              as bool,
      cost: freezed == cost
          ? _value.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as EventCost?,
      quantityTotal: freezed == quantityTotal
          ? _value.quantityTotal
          : quantityTotal // ignore: cast_nullable_to_non_nullable
              as int?,
      quantitySold: freezed == quantitySold
          ? _value.quantitySold
          : quantitySold // ignore: cast_nullable_to_non_nullable
              as int?,
      salesStart: freezed == salesStart
          ? _value.salesStart
          : salesStart // ignore: cast_nullable_to_non_nullable
              as String?,
      salesEnd: freezed == salesEnd
          ? _value.salesEnd
          : salesEnd // ignore: cast_nullable_to_non_nullable
              as String?,
      hidden: null == hidden
          ? _value.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketClassImpl implements _TicketClass {
  const _$TicketClassImpl(
      {required this.id,
      required this.name,
      this.free = true,
      this.cost,
      this.quantityTotal,
      this.quantitySold,
      this.salesStart,
      this.salesEnd,
      this.hidden = false});

  factory _$TicketClassImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketClassImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool free;
  @override
  final EventCost? cost;
  @override
  final int? quantityTotal;
  @override
  final int? quantitySold;
  @override
  final String? salesStart;
  @override
  final String? salesEnd;
  @override
  @JsonKey()
  final bool hidden;

  @override
  String toString() {
    return 'TicketClass(id: $id, name: $name, free: $free, cost: $cost, quantityTotal: $quantityTotal, quantitySold: $quantitySold, salesStart: $salesStart, salesEnd: $salesEnd, hidden: $hidden)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketClassImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.free, free) || other.free == free) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.quantityTotal, quantityTotal) ||
                other.quantityTotal == quantityTotal) &&
            (identical(other.quantitySold, quantitySold) ||
                other.quantitySold == quantitySold) &&
            (identical(other.salesStart, salesStart) ||
                other.salesStart == salesStart) &&
            (identical(other.salesEnd, salesEnd) ||
                other.salesEnd == salesEnd) &&
            (identical(other.hidden, hidden) || other.hidden == hidden));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, free, cost,
      quantityTotal, quantitySold, salesStart, salesEnd, hidden);

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketClassImplCopyWith<_$TicketClassImpl> get copyWith =>
      __$$TicketClassImplCopyWithImpl<_$TicketClassImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketClassImplToJson(
      this,
    );
  }
}

abstract class _TicketClass implements TicketClass {
  const factory _TicketClass(
      {required final String id,
      required final String name,
      final bool free,
      final EventCost? cost,
      final int? quantityTotal,
      final int? quantitySold,
      final String? salesStart,
      final String? salesEnd,
      final bool hidden}) = _$TicketClassImpl;

  factory _TicketClass.fromJson(Map<String, dynamic> json) =
      _$TicketClassImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get free;
  @override
  EventCost? get cost;
  @override
  int? get quantityTotal;
  @override
  int? get quantitySold;
  @override
  String? get salesStart;
  @override
  String? get salesEnd;
  @override
  bool get hidden;

  /// Create a copy of TicketClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketClassImplCopyWith<_$TicketClassImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventCost _$EventCostFromJson(Map<String, dynamic> json) {
  return _EventCost.fromJson(json);
}

/// @nodoc
mixin _$EventCost {
  String get currency => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  String get display => throw _privateConstructorUsedError;

  /// Serializes this EventCost to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventCost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventCostCopyWith<EventCost> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventCostCopyWith<$Res> {
  factory $EventCostCopyWith(EventCost value, $Res Function(EventCost) then) =
      _$EventCostCopyWithImpl<$Res, EventCost>;
  @useResult
  $Res call({String currency, int value, String display});
}

/// @nodoc
class _$EventCostCopyWithImpl<$Res, $Val extends EventCost>
    implements $EventCostCopyWith<$Res> {
  _$EventCostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventCost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? value = null,
    Object? display = null,
  }) {
    return _then(_value.copyWith(
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
      display: null == display
          ? _value.display
          : display // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventCostImplCopyWith<$Res>
    implements $EventCostCopyWith<$Res> {
  factory _$$EventCostImplCopyWith(
          _$EventCostImpl value, $Res Function(_$EventCostImpl) then) =
      __$$EventCostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String currency, int value, String display});
}

/// @nodoc
class __$$EventCostImplCopyWithImpl<$Res>
    extends _$EventCostCopyWithImpl<$Res, _$EventCostImpl>
    implements _$$EventCostImplCopyWith<$Res> {
  __$$EventCostImplCopyWithImpl(
      _$EventCostImpl _value, $Res Function(_$EventCostImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventCost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? value = null,
    Object? display = null,
  }) {
    return _then(_$EventCostImpl(
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
      display: null == display
          ? _value.display
          : display // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventCostImpl implements _EventCost {
  const _$EventCostImpl(
      {required this.currency, required this.value, required this.display});

  factory _$EventCostImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventCostImplFromJson(json);

  @override
  final String currency;
  @override
  final int value;
  @override
  final String display;

  @override
  String toString() {
    return 'EventCost(currency: $currency, value: $value, display: $display)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventCostImpl &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.display, display) || other.display == display));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, currency, value, display);

  /// Create a copy of EventCost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventCostImplCopyWith<_$EventCostImpl> get copyWith =>
      __$$EventCostImplCopyWithImpl<_$EventCostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventCostImplToJson(
      this,
    );
  }
}

abstract class _EventCost implements EventCost {
  const factory _EventCost(
      {required final String currency,
      required final int value,
      required final String display}) = _$EventCostImpl;

  factory _EventCost.fromJson(Map<String, dynamic> json) =
      _$EventCostImpl.fromJson;

  @override
  String get currency;
  @override
  int get value;
  @override
  String get display;

  /// Create a copy of EventCost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventCostImplCopyWith<_$EventCostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
