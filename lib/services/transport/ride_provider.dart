import '../../core/geo/geo_point.dart';
import '../../data/models/ride.dart' hide RideProvider;

abstract class RideProvider {
  String get providerId;
  String get displayName;
  bool get supportsScheduling;
  bool get supportsRideSharing;
  bool get supportsDeepLink;

  Future<List<RideQuote>> getQuotes({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
    int partySize = 1,
  });

  Future<RideBooking> bookRide({
    required String userId,
    required RideQuote quote,
    String? eventId,
    String? groupId,
  });

  Stream<RideStatusUpdate> trackRide(String providerRideId);

  Future<void> cancelRide(String providerRideId);

  Future<RideReceipt> getReceipt(String providerRideId);

  Uri buildDeepLink({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
  });
}
