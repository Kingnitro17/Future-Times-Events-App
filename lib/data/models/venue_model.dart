// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue_model.freezed.dart';
part 'venue_model.g.dart';

/// Mapped to Eventbrite's `venue` object returned via `expand=venue`.
@freezed
class VenueModel with _$VenueModel {
  const factory VenueModel({
    required String id,
    required String name,
    VenueAddress? address,
    String? latitude,
    String? longitude,
    String? capacity,
  }) = _VenueModel;

  factory VenueModel.fromJson(Map<String, dynamic> json) =>
      _$VenueModelFromJson(json);
}

@freezed
class VenueAddress with _$VenueAddress {
  const factory VenueAddress({
    String? address1,
    String? address2,
    String? city,
    String? region,
    String? postalCode,
    String? country,
    @JsonKey(name: 'localized_address_display')
    String? localizedDisplay,
    @JsonKey(name: 'localized_multi_line_address_display')
    List<String>? multiLineDisplay,
  }) = _VenueAddress;

  factory VenueAddress.fromJson(Map<String, dynamic> json) =>
      _$VenueAddressFromJson(json);
}
