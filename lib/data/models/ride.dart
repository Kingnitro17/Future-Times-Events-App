// Database status values intentionally use snake_case identifiers.
// ignore_for_file: constant_identifier_names

import '../../core/geo/geo_point.dart';

enum RideStatus {
  quoted,
  booking,
  booked,
  driver_assigned,
  in_progress,
  completed,
  cancelled,
  failed,
}

enum RideProvider { tapAndGo, inDrive, bolt, manual }

class RideQuote {
  const RideQuote({
    required this.providerId,
    required this.providerDisplayName,
    required this.pickup,
    required this.dropoff,
    required this.fareEstimate,
    required this.currency,
    required this.etaMinutes,
    this.vehicleClass,
    required this.expiresAt,
    required this.rawPayload,
  });

  final String providerId;
  final String providerDisplayName;
  final GeoPoint pickup;
  final GeoPoint dropoff;
  final double fareEstimate;
  final String currency;
  final int etaMinutes;
  final String? vehicleClass;
  final DateTime expiresAt;
  final Map<String, dynamic> rawPayload;

  factory RideQuote.fromSupabase(Map<String, dynamic> row) => RideQuote(
        providerId: row['provider_id']?.toString() ?? '',
        providerDisplayName: row['provider_display_name']?.toString() ?? '',
        pickup: GeoPoint.fromSupabase(row['pickup']),
        dropoff: GeoPoint.fromSupabase(row['dropoff']),
        fareEstimate: _double(row['fare_estimate']),
        currency: row['currency']?.toString() ?? 'USD',
        etaMinutes: _int(row['eta_minutes']),
        vehicleClass: _string(row['vehicle_class']),
        expiresAt: _date(row['expires_at']),
        rawPayload: _map(row['raw_payload']),
      );

  Map<String, dynamic> toSupabase() => {
        'provider_id': providerId,
        'provider_display_name': providerDisplayName,
        'pickup': pickup.toSupabase(),
        'dropoff': dropoff.toSupabase(),
        'fare_estimate': fareEstimate,
        'currency': currency,
        'eta_minutes': etaMinutes,
        'vehicle_class': vehicleClass,
        'expires_at': expiresAt.toIso8601String(),
        'raw_payload': rawPayload,
      };

  RideQuote copyWith({
    String? providerId,
    String? providerDisplayName,
    GeoPoint? pickup,
    GeoPoint? dropoff,
    double? fareEstimate,
    String? currency,
    int? etaMinutes,
    String? vehicleClass,
    DateTime? expiresAt,
    Map<String, dynamic>? rawPayload,
  }) =>
      RideQuote(
        providerId: providerId ?? this.providerId,
        providerDisplayName: providerDisplayName ?? this.providerDisplayName,
        pickup: pickup ?? this.pickup,
        dropoff: dropoff ?? this.dropoff,
        fareEstimate: fareEstimate ?? this.fareEstimate,
        currency: currency ?? this.currency,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        vehicleClass: vehicleClass ?? this.vehicleClass,
        expiresAt: expiresAt ?? this.expiresAt,
        rawPayload: rawPayload ?? this.rawPayload,
      );
}

class RideBooking {
  const RideBooking({
    required this.id,
    required this.userId,
    this.eventId,
    this.groupId,
    required this.providerId,
    required this.providerRideId,
    required this.pickup,
    required this.dropoff,
    required this.status,
    required this.fareEstimate,
    this.fareFinal,
    required this.currency,
    required this.etaMinutes,
    this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? eventId;
  final String? groupId;
  final String providerId;
  final String providerRideId;
  final GeoPoint pickup;
  final GeoPoint dropoff;
  final RideStatus status;
  final double fareEstimate;
  final double? fareFinal;
  final String currency;
  final int etaMinutes;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RideBooking.fromSupabase(Map<String, dynamic> row) => RideBooking(
        id: row['id']?.toString() ?? '',
        userId: row['user_id']?.toString() ?? '',
        eventId: _string(row['event_id']),
        groupId: _string(row['group_id']),
        providerId: row['provider_id']?.toString() ?? '',
        providerRideId: row['provider_ride_id']?.toString() ?? '',
        pickup: GeoPoint.fromSupabase(row['pickup']),
        dropoff: GeoPoint.fromSupabase(row['dropoff']),
        status: _enum(row['status'], RideStatus.values, RideStatus.quoted),
        fareEstimate: _double(row['fare_estimate']),
        fareFinal:
            row['fare_final'] == null ? null : _double(row['fare_final']),
        currency: row['currency']?.toString() ?? 'USD',
        etaMinutes: _int(row['eta_minutes']),
        scheduledFor: _optionalDate(row['scheduled_for']),
        createdAt: _date(row['created_at']),
        updatedAt: _date(row['updated_at']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'group_id': groupId,
        'provider_id': providerId,
        'provider_ride_id': providerRideId,
        'pickup': pickup.toSupabase(),
        'dropoff': dropoff.toSupabase(),
        'status': _statusName(status),
        'fare_estimate': fareEstimate,
        'fare_final': fareFinal,
        'currency': currency,
        'eta_minutes': etaMinutes,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  RideBooking copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? groupId,
    String? providerId,
    String? providerRideId,
    GeoPoint? pickup,
    GeoPoint? dropoff,
    RideStatus? status,
    double? fareEstimate,
    double? fareFinal,
    String? currency,
    int? etaMinutes,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      RideBooking(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        eventId: eventId ?? this.eventId,
        groupId: groupId ?? this.groupId,
        providerId: providerId ?? this.providerId,
        providerRideId: providerRideId ?? this.providerRideId,
        pickup: pickup ?? this.pickup,
        dropoff: dropoff ?? this.dropoff,
        status: status ?? this.status,
        fareEstimate: fareEstimate ?? this.fareEstimate,
        fareFinal: fareFinal ?? this.fareFinal,
        currency: currency ?? this.currency,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class RideStatusUpdate {
  const RideStatusUpdate({
    required this.rideId,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.vehicleModel,
    this.etaMinutes,
    required this.updatedAt,
  });

  final String rideId;
  final RideStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final String? vehicleModel;
  final int? etaMinutes;
  final DateTime updatedAt;

  factory RideStatusUpdate.fromSupabase(Map<String, dynamic> row) =>
      RideStatusUpdate(
        rideId: row['ride_id']?.toString() ?? '',
        status: _enum(row['status'], RideStatus.values, RideStatus.quoted),
        driverName: _string(row['driver_name']),
        driverPhone: _string(row['driver_phone']),
        vehiclePlate: _string(row['vehicle_plate']),
        vehicleModel: _string(row['vehicle_model']),
        etaMinutes:
            row['eta_minutes'] == null ? null : _int(row['eta_minutes']),
        updatedAt: _date(row['updated_at']),
      );

  Map<String, dynamic> toSupabase() => {
        'ride_id': rideId,
        'status': _statusName(status),
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_plate': vehiclePlate,
        'vehicle_model': vehicleModel,
        'eta_minutes': etaMinutes,
        'updated_at': updatedAt.toIso8601String(),
      };

  RideStatusUpdate copyWith({
    String? rideId,
    RideStatus? status,
    String? driverName,
    String? driverPhone,
    String? vehiclePlate,
    String? vehicleModel,
    int? etaMinutes,
    DateTime? updatedAt,
  }) =>
      RideStatusUpdate(
        rideId: rideId ?? this.rideId,
        status: status ?? this.status,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        vehiclePlate: vehiclePlate ?? this.vehiclePlate,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class RideReceipt {
  const RideReceipt({
    required this.rideId,
    required this.fareFinal,
    required this.currency,
    required this.paidAt,
    required this.providerReference,
  });

  final String rideId;
  final double fareFinal;
  final String currency;
  final DateTime paidAt;
  final String providerReference;

  factory RideReceipt.fromSupabase(Map<String, dynamic> row) => RideReceipt(
        rideId: row['ride_id']?.toString() ?? '',
        fareFinal: _double(row['fare_final']),
        currency: row['currency']?.toString() ?? 'USD',
        paidAt: _date(row['paid_at']),
        providerReference: row['provider_reference']?.toString() ?? '',
      );

  Map<String, dynamic> toSupabase() => {
        'ride_id': rideId,
        'fare_final': fareFinal,
        'currency': currency,
        'paid_at': paidAt.toIso8601String(),
        'provider_reference': providerReference,
      };

  RideReceipt copyWith({
    String? rideId,
    double? fareFinal,
    String? currency,
    DateTime? paidAt,
    String? providerReference,
  }) =>
      RideReceipt(
        rideId: rideId ?? this.rideId,
        fareFinal: fareFinal ?? this.fareFinal,
        currency: currency ?? this.currency,
        paidAt: paidAt ?? this.paidAt,
        providerReference: providerReference ?? this.providerReference,
      );
}

String _statusName(RideStatus status) => status.name;

T _enum<T extends Enum>(Object? value, List<T> values, T fallback) {
  final normalized = value?.toString().replaceAll('-', '_');
  return values.firstWhere(
    (item) => _statusNameForEnum(item) == normalized,
    orElse: () => fallback,
  );
}

String _statusNameForEnum(Enum value) => value.name;

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String? _string(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
