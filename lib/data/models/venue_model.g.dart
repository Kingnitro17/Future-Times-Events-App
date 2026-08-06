// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueModelImpl _$$VenueModelImplFromJson(Map<String, dynamic> json) =>
    _$VenueModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] == null
          ? null
          : VenueAddress.fromJson(json['address'] as Map<String, dynamic>),
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      capacity: json['capacity'] as String?,
    );

Map<String, dynamic> _$$VenueModelImplToJson(_$VenueModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'capacity': instance.capacity,
    };

_$VenueAddressImpl _$$VenueAddressImplFromJson(Map<String, dynamic> json) =>
    _$VenueAddressImpl(
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      localizedDisplay: json['localized_address_display'] as String?,
      multiLineDisplay:
          (json['localized_multi_line_address_display'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$$VenueAddressImplToJson(_$VenueAddressImpl instance) =>
    <String, dynamic>{
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'region': instance.region,
      'postalCode': instance.postalCode,
      'country': instance.country,
      'localized_address_display': instance.localizedDisplay,
      'localized_multi_line_address_display': instance.multiLineDisplay,
    };
