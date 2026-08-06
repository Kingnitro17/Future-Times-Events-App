// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventModelImpl _$$EventModelImplFromJson(Map<String, dynamic> json) =>
    _$EventModelImpl(
      id: json['id'] as String,
      name: EventText.fromJson(json['name'] as Map<String, dynamic>),
      description: json['description'] == null
          ? null
          : EventText.fromJson(json['description'] as Map<String, dynamic>),
      url: json['url'] as String,
      start: EventDateTime.fromJson(json['start'] as Map<String, dynamic>),
      end: EventDateTime.fromJson(json['end'] as Map<String, dynamic>),
      logo: json['logo'] == null
          ? null
          : EventImage.fromJson(json['logo'] as Map<String, dynamic>),
      venue: json['venue'] == null
          ? null
          : VenueModel.fromJson(json['venue'] as Map<String, dynamic>),
      categoryId: json['categoryId'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
      isFree: json['isFree'] as bool? ?? false,
      isOnlineEvent: json['isOnlineEvent'] as bool? ?? false,
      capacity: (json['capacity'] as num?)?.toInt(),
      status: json['status'] as String?,
      currency: json['currency'] as String?,
      ticketClasses: (json['ticketClasses'] as List<dynamic>?)
              ?.map((e) => TicketClass.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$EventModelImplToJson(_$EventModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'start': instance.start,
      'end': instance.end,
      'logo': instance.logo,
      'venue': instance.venue,
      'categoryId': instance.categoryId,
      'subcategoryId': instance.subcategoryId,
      'isFree': instance.isFree,
      'isOnlineEvent': instance.isOnlineEvent,
      'capacity': instance.capacity,
      'status': instance.status,
      'currency': instance.currency,
      'ticketClasses': instance.ticketClasses,
    };

_$EventTextImpl _$$EventTextImplFromJson(Map<String, dynamic> json) =>
    _$EventTextImpl(
      text: json['text'] as String,
      html: json['html'] as String,
    );

Map<String, dynamic> _$$EventTextImplToJson(_$EventTextImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'html': instance.html,
    };

_$EventDateTimeImpl _$$EventDateTimeImplFromJson(Map<String, dynamic> json) =>
    _$EventDateTimeImpl(
      timezone: json['timezone'] as String,
      utc: json['utc'] as String,
      local: json['local'] as String,
    );

Map<String, dynamic> _$$EventDateTimeImplToJson(_$EventDateTimeImpl instance) =>
    <String, dynamic>{
      'timezone': instance.timezone,
      'utc': instance.utc,
      'local': instance.local,
    };

_$EventImageImpl _$$EventImageImplFromJson(Map<String, dynamic> json) =>
    _$EventImageImpl(
      id: json['id'] as String,
      url: json['url'] as String?,
      original: json['original'] == null
          ? null
          : EventImageDimensions.fromJson(
              json['original'] as Map<String, dynamic>),
      crop: json['crop'] == null
          ? null
          : EventImageDimensions.fromJson(json['crop'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$EventImageImplToJson(_$EventImageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'original': instance.original,
      'crop': instance.crop,
    };

_$EventImageDimensionsImpl _$$EventImageDimensionsImplFromJson(
        Map<String, dynamic> json) =>
    _$EventImageDimensionsImpl(
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EventImageDimensionsImplToJson(
        _$EventImageDimensionsImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

_$TicketClassImpl _$$TicketClassImplFromJson(Map<String, dynamic> json) =>
    _$TicketClassImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      free: json['free'] as bool? ?? true,
      cost: json['cost'] == null
          ? null
          : EventCost.fromJson(json['cost'] as Map<String, dynamic>),
      quantityTotal: (json['quantityTotal'] as num?)?.toInt(),
      quantitySold: (json['quantitySold'] as num?)?.toInt(),
      salesStart: json['salesStart'] as String?,
      salesEnd: json['salesEnd'] as String?,
      hidden: json['hidden'] as bool? ?? false,
    );

Map<String, dynamic> _$$TicketClassImplToJson(_$TicketClassImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'free': instance.free,
      'cost': instance.cost,
      'quantityTotal': instance.quantityTotal,
      'quantitySold': instance.quantitySold,
      'salesStart': instance.salesStart,
      'salesEnd': instance.salesEnd,
      'hidden': instance.hidden,
    };

_$EventCostImpl _$$EventCostImplFromJson(Map<String, dynamic> json) =>
    _$EventCostImpl(
      currency: json['currency'] as String,
      value: (json['value'] as num).toInt(),
      display: json['display'] as String,
    );

Map<String, dynamic> _$$EventCostImplToJson(_$EventCostImpl instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'value': instance.value,
      'display': instance.display,
    };
