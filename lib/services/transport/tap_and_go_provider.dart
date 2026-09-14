import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/geo/geo_point.dart';
import '../../data/models/ride.dart' hide RideProvider;
import 'ride_provider.dart';

class TapAndGoProvider implements RideProvider {
  TapAndGoProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String get providerId => 'tap_and_go';

  @override
  String get displayName => 'Tap & Go';

  @override
  bool get supportsScheduling => false;

  @override
  bool get supportsRideSharing => false;

  @override
  bool get supportsDeepLink => true;

  @override
  Future<List<RideQuote>> getQuotes({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
    int partySize = 1,
  }) async {
    return [
      RideQuote(
        providerId: providerId,
        providerDisplayName: displayName,
        pickup: pickup,
        dropoff: dropoff,
        fareEstimate: 0,
        currency: 'USD',
        etaMinutes: 0,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        rawPayload: const {
          'requiresConfirmation': true,
          'message': 'Fare shown in Tap & Go app',
        },
      ),
    ];
  }

  @override
  Future<RideBooking> bookRide({
    required String userId,
    required RideQuote quote,
    String? eventId,
    String? groupId,
  }) async {
    final now = DateTime.now().toUtc();
    final row = await _client
        .from('rides')
        .insert({
          'user_id': userId,
          'event_id': eventId,
          'group_id': groupId,
          'provider_id': providerId,
          'provider_ride_id': 'local:${now.microsecondsSinceEpoch}',
          'pickup': quote.pickup.toSupabase(),
          'dropoff': quote.dropoff.toSupabase(),
          'status': RideStatus.booking.name,
          'fare_estimate': quote.fareEstimate,
          'currency': quote.currency,
          'eta_minutes': quote.etaMinutes,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();
    return RideBooking.fromSupabase(row);
  }

  @override
  Stream<RideStatusUpdate> trackRide(String providerRideId) =>
      const Stream<RideStatusUpdate>.empty();

  @override
  Future<void> cancelRide(String providerRideId) async {
    await _client
        .from('rides')
        .update({
          'status': RideStatus.cancelled.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('provider_ride_id', providerRideId)
        .eq('provider_id', providerId);
  }

  @override
  Future<RideReceipt> getReceipt(String providerRideId) =>
      throw UnimplementedError('Tap & Go receipt integration is pending');

  @override
  Uri buildDeepLink({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
  }) {
    // TODO: Replace with the real scheme supplied by Tap & Go.
    return Uri(
      scheme: 'tapandgo',
      host: 'ride',
      queryParameters: {
        'pickup_lat': pickup.lat.toString(),
        'pickup_lng': pickup.lng.toString(),
        'dropoff_lat': dropoff.lat.toString(),
        'dropoff_lng': dropoff.lng.toString(),
      },
    );
  }
}
