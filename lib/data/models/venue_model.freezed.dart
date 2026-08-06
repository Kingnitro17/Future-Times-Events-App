// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VenueModel _$VenueModelFromJson(Map<String, dynamic> json) {
  return _VenueModel.fromJson(json);
}

/// @nodoc
mixin _$VenueModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  VenueAddress? get address => throw _privateConstructorUsedError;
  String? get latitude => throw _privateConstructorUsedError;
  String? get longitude => throw _privateConstructorUsedError;
  String? get capacity => throw _privateConstructorUsedError;

  /// Serializes this VenueModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueModelCopyWith<VenueModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueModelCopyWith<$Res> {
  factory $VenueModelCopyWith(
          VenueModel value, $Res Function(VenueModel) then) =
      _$VenueModelCopyWithImpl<$Res, VenueModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      VenueAddress? address,
      String? latitude,
      String? longitude,
      String? capacity});

  $VenueAddressCopyWith<$Res>? get address;
}

/// @nodoc
class _$VenueModelCopyWithImpl<$Res, $Val extends VenueModel>
    implements $VenueModelCopyWith<$Res> {
  _$VenueModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? capacity = freezed,
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
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as VenueAddress?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as String?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as String?,
      capacity: freezed == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VenueAddressCopyWith<$Res>? get address {
    if (_value.address == null) {
      return null;
    }

    return $VenueAddressCopyWith<$Res>(_value.address!, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VenueModelImplCopyWith<$Res>
    implements $VenueModelCopyWith<$Res> {
  factory _$$VenueModelImplCopyWith(
          _$VenueModelImpl value, $Res Function(_$VenueModelImpl) then) =
      __$$VenueModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      VenueAddress? address,
      String? latitude,
      String? longitude,
      String? capacity});

  @override
  $VenueAddressCopyWith<$Res>? get address;
}

/// @nodoc
class __$$VenueModelImplCopyWithImpl<$Res>
    extends _$VenueModelCopyWithImpl<$Res, _$VenueModelImpl>
    implements _$$VenueModelImplCopyWith<$Res> {
  __$$VenueModelImplCopyWithImpl(
      _$VenueModelImpl _value, $Res Function(_$VenueModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? capacity = freezed,
  }) {
    return _then(_$VenueModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as VenueAddress?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as String?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as String?,
      capacity: freezed == capacity
          ? _value.capacity
          : capacity // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueModelImpl implements _VenueModel {
  const _$VenueModelImpl(
      {required this.id,
      required this.name,
      this.address,
      this.latitude,
      this.longitude,
      this.capacity});

  factory _$VenueModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final VenueAddress? address;
  @override
  final String? latitude;
  @override
  final String? longitude;
  @override
  final String? capacity;

  @override
  String toString() {
    return 'VenueModel(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, capacity: $capacity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, address, latitude, longitude, capacity);

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueModelImplCopyWith<_$VenueModelImpl> get copyWith =>
      __$$VenueModelImplCopyWithImpl<_$VenueModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueModelImplToJson(
      this,
    );
  }
}

abstract class _VenueModel implements VenueModel {
  const factory _VenueModel(
      {required final String id,
      required final String name,
      final VenueAddress? address,
      final String? latitude,
      final String? longitude,
      final String? capacity}) = _$VenueModelImpl;

  factory _VenueModel.fromJson(Map<String, dynamic> json) =
      _$VenueModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  VenueAddress? get address;
  @override
  String? get latitude;
  @override
  String? get longitude;
  @override
  String? get capacity;

  /// Create a copy of VenueModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueModelImplCopyWith<_$VenueModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VenueAddress _$VenueAddressFromJson(Map<String, dynamic> json) {
  return _VenueAddress.fromJson(json);
}

/// @nodoc
mixin _$VenueAddress {
  String? get address1 => throw _privateConstructorUsedError;
  String? get address2 => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;
  String? get postalCode => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'localized_address_display')
  String? get localizedDisplay => throw _privateConstructorUsedError;
  @JsonKey(name: 'localized_multi_line_address_display')
  List<String>? get multiLineDisplay => throw _privateConstructorUsedError;

  /// Serializes this VenueAddress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueAddressCopyWith<VenueAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueAddressCopyWith<$Res> {
  factory $VenueAddressCopyWith(
          VenueAddress value, $Res Function(VenueAddress) then) =
      _$VenueAddressCopyWithImpl<$Res, VenueAddress>;
  @useResult
  $Res call(
      {String? address1,
      String? address2,
      String? city,
      String? region,
      String? postalCode,
      String? country,
      @JsonKey(name: 'localized_address_display') String? localizedDisplay,
      @JsonKey(name: 'localized_multi_line_address_display')
      List<String>? multiLineDisplay});
}

/// @nodoc
class _$VenueAddressCopyWithImpl<$Res, $Val extends VenueAddress>
    implements $VenueAddressCopyWith<$Res> {
  _$VenueAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address1 = freezed,
    Object? address2 = freezed,
    Object? city = freezed,
    Object? region = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
    Object? localizedDisplay = freezed,
    Object? multiLineDisplay = freezed,
  }) {
    return _then(_value.copyWith(
      address1: freezed == address1
          ? _value.address1
          : address1 // ignore: cast_nullable_to_non_nullable
              as String?,
      address2: freezed == address2
          ? _value.address2
          : address2 // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      localizedDisplay: freezed == localizedDisplay
          ? _value.localizedDisplay
          : localizedDisplay // ignore: cast_nullable_to_non_nullable
              as String?,
      multiLineDisplay: freezed == multiLineDisplay
          ? _value.multiLineDisplay
          : multiLineDisplay // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VenueAddressImplCopyWith<$Res>
    implements $VenueAddressCopyWith<$Res> {
  factory _$$VenueAddressImplCopyWith(
          _$VenueAddressImpl value, $Res Function(_$VenueAddressImpl) then) =
      __$$VenueAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? address1,
      String? address2,
      String? city,
      String? region,
      String? postalCode,
      String? country,
      @JsonKey(name: 'localized_address_display') String? localizedDisplay,
      @JsonKey(name: 'localized_multi_line_address_display')
      List<String>? multiLineDisplay});
}

/// @nodoc
class __$$VenueAddressImplCopyWithImpl<$Res>
    extends _$VenueAddressCopyWithImpl<$Res, _$VenueAddressImpl>
    implements _$$VenueAddressImplCopyWith<$Res> {
  __$$VenueAddressImplCopyWithImpl(
      _$VenueAddressImpl _value, $Res Function(_$VenueAddressImpl) _then)
      : super(_value, _then);

  /// Create a copy of VenueAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address1 = freezed,
    Object? address2 = freezed,
    Object? city = freezed,
    Object? region = freezed,
    Object? postalCode = freezed,
    Object? country = freezed,
    Object? localizedDisplay = freezed,
    Object? multiLineDisplay = freezed,
  }) {
    return _then(_$VenueAddressImpl(
      address1: freezed == address1
          ? _value.address1
          : address1 // ignore: cast_nullable_to_non_nullable
              as String?,
      address2: freezed == address2
          ? _value.address2
          : address2 // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      localizedDisplay: freezed == localizedDisplay
          ? _value.localizedDisplay
          : localizedDisplay // ignore: cast_nullable_to_non_nullable
              as String?,
      multiLineDisplay: freezed == multiLineDisplay
          ? _value._multiLineDisplay
          : multiLineDisplay // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueAddressImpl implements _VenueAddress {
  const _$VenueAddressImpl(
      {this.address1,
      this.address2,
      this.city,
      this.region,
      this.postalCode,
      this.country,
      @JsonKey(name: 'localized_address_display') this.localizedDisplay,
      @JsonKey(name: 'localized_multi_line_address_display')
      final List<String>? multiLineDisplay})
      : _multiLineDisplay = multiLineDisplay;

  factory _$VenueAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueAddressImplFromJson(json);

  @override
  final String? address1;
  @override
  final String? address2;
  @override
  final String? city;
  @override
  final String? region;
  @override
  final String? postalCode;
  @override
  final String? country;
  @override
  @JsonKey(name: 'localized_address_display')
  final String? localizedDisplay;
  final List<String>? _multiLineDisplay;
  @override
  @JsonKey(name: 'localized_multi_line_address_display')
  List<String>? get multiLineDisplay {
    final value = _multiLineDisplay;
    if (value == null) return null;
    if (_multiLineDisplay is EqualUnmodifiableListView)
      return _multiLineDisplay;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'VenueAddress(address1: $address1, address2: $address2, city: $city, region: $region, postalCode: $postalCode, country: $country, localizedDisplay: $localizedDisplay, multiLineDisplay: $multiLineDisplay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueAddressImpl &&
            (identical(other.address1, address1) ||
                other.address1 == address1) &&
            (identical(other.address2, address2) ||
                other.address2 == address2) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.localizedDisplay, localizedDisplay) ||
                other.localizedDisplay == localizedDisplay) &&
            const DeepCollectionEquality()
                .equals(other._multiLineDisplay, _multiLineDisplay));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      address1,
      address2,
      city,
      region,
      postalCode,
      country,
      localizedDisplay,
      const DeepCollectionEquality().hash(_multiLineDisplay));

  /// Create a copy of VenueAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueAddressImplCopyWith<_$VenueAddressImpl> get copyWith =>
      __$$VenueAddressImplCopyWithImpl<_$VenueAddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueAddressImplToJson(
      this,
    );
  }
}

abstract class _VenueAddress implements VenueAddress {
  const factory _VenueAddress(
      {final String? address1,
      final String? address2,
      final String? city,
      final String? region,
      final String? postalCode,
      final String? country,
      @JsonKey(name: 'localized_address_display')
      final String? localizedDisplay,
      @JsonKey(name: 'localized_multi_line_address_display')
      final List<String>? multiLineDisplay}) = _$VenueAddressImpl;

  factory _VenueAddress.fromJson(Map<String, dynamic> json) =
      _$VenueAddressImpl.fromJson;

  @override
  String? get address1;
  @override
  String? get address2;
  @override
  String? get city;
  @override
  String? get region;
  @override
  String? get postalCode;
  @override
  String? get country;
  @override
  @JsonKey(name: 'localized_address_display')
  String? get localizedDisplay;
  @override
  @JsonKey(name: 'localized_multi_line_address_display')
  List<String>? get multiLineDisplay;

  /// Create a copy of VenueAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueAddressImplCopyWith<_$VenueAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
