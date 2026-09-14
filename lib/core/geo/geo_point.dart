import 'package:latlong2/latlong.dart';

class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;

  factory GeoPoint.fromSupabase(Object? value) {
    if (value is GeoPoint) return value;
    if (value is Map) {
      return GeoPoint(
        lat: _double(value['lat'] ?? value['latitude']),
        lng: _double(value['lng'] ?? value['lon'] ?? value['longitude']),
        address: _nullableString(value['address']),
      );
    }
    if (value is List && value.length >= 2) {
      return GeoPoint(
        lat: _double(value[0]),
        lng: _double(value[1]),
      );
    }
    return const GeoPoint(lat: 0, lng: 0);
  }

  factory GeoPoint.fromLatLng(LatLng point, {String? address}) => GeoPoint(
        lat: point.latitude,
        lng: point.longitude,
        address: address,
      );

  Map<String, dynamic> toSupabase() => {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
      };

  GeoPoint copyWith({
    double? lat,
    double? lng,
    String? address,
  }) =>
      GeoPoint(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        address: address ?? this.address,
      );

  static double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
