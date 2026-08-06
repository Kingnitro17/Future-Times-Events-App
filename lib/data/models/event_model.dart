import 'package:freezed_annotation/freezed_annotation.dart';
import 'venue_model.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

/// Mapped to Eventbrite's `event` object.
/// API Docs: https://www.eventbrite.com/platform/api#/reference/event
@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    required EventText name,
    EventText? description,
    required String url,
    required EventDateTime start,
    required EventDateTime end,
    EventImage? logo,
    VenueModel? venue,
    String? categoryId,
    String? subcategoryId,
    @Default(false) bool isFree,
    @Default(false) bool isOnlineEvent,
    int? capacity,
    String? status,
    String? currency,
    @Default([]) List<TicketClass> ticketClasses,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);
}

// ─── Supporting Types ──────────────────────────────────────────────────────

@freezed
class EventText with _$EventText {
  const factory EventText({
    required String text,
    required String html,
  }) = _EventText;

  factory EventText.fromJson(Map<String, dynamic> json) =>
      _$EventTextFromJson(json);
}

@freezed
class EventDateTime with _$EventDateTime {
  const factory EventDateTime({
    required String timezone,
    required String utc,
    required String local,
  }) = _EventDateTime;

  factory EventDateTime.fromJson(Map<String, dynamic> json) =>
      _$EventDateTimeFromJson(json);

  /// Parse to [DateTime] in local timezone
  static DateTime toDateTime(EventDateTime dt) => DateTime.parse(dt.local);
}

@freezed
class EventImage with _$EventImage {
  const factory EventImage({
    required String id,
    String? url,
    EventImageDimensions? original,
    EventImageDimensions? crop,
  }) = _EventImage;

  factory EventImage.fromJson(Map<String, dynamic> json) =>
      _$EventImageFromJson(json);
}

@freezed
class EventImageDimensions with _$EventImageDimensions {
  const factory EventImageDimensions({
    required String url,
    int? width,
    int? height,
  }) = _EventImageDimensions;

  factory EventImageDimensions.fromJson(Map<String, dynamic> json) =>
      _$EventImageDimensionsFromJson(json);
}

@freezed
class TicketClass with _$TicketClass {
  const factory TicketClass({
    required String id,
    required String name,
    @Default(true) bool free,
    EventCost? cost,
    int? quantityTotal,
    int? quantitySold,
    String? salesStart,
    String? salesEnd,
    @Default(false) bool hidden,
  }) = _TicketClass;

  factory TicketClass.fromJson(Map<String, dynamic> json) =>
      _$TicketClassFromJson(json);
}

@freezed
class EventCost with _$EventCost {
  const factory EventCost({
    required String currency,
    required int value,
    required String display,
  }) = _EventCost;

  factory EventCost.fromJson(Map<String, dynamic> json) =>
      _$EventCostFromJson(json);
}
