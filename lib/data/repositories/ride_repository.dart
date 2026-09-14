import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/geo/geo_point.dart';
import '../../data/models/ride.dart' hide RideProvider;
import '../../services/transport/ride_aggregator.dart';
import '../../services/transport/tap_and_go_provider.dart';

class RideRepository {
  RideRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _provider =
            TapAndGoProvider(client: client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final TapAndGoProvider _provider;

  RideAggregator get _aggregator => RideAggregator(providers: [_provider]);

  Future<List<RideQuote>> getQuotes({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
    int partySize = 1,
  }) =>
      _aggregator.getAllQuotes(
        pickup: pickup,
        dropoff: dropoff,
        scheduledFor: scheduledFor,
        partySize: partySize,
      );

  Future<RideBooking> createBooking({
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
          'provider_id': quote.providerId,
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

  Future<void> markAsBooked({
    required String rideId,
    String? providerRideId,
  }) async {
    final updates = <String, dynamic>{
      'status': RideStatus.booked.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (providerRideId != null) updates['provider_ride_id'] = providerRideId;
    await _client.from('rides').update(updates).eq('id', rideId);
  }

  Future<void> markAsCancelled(String rideId) async {
    await _client.from('rides').update({
      'status': RideStatus.cancelled.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', rideId);
  }

  Future<void> markAsCompleted({
    required String rideId,
    double? fareFinal,
  }) async {
    final updates = <String, dynamic>{
      'status': RideStatus.completed.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (fareFinal != null) updates['fare_final'] = fareFinal;
    await _client.from('rides').update(updates).eq('id', rideId);
  }

  Future<List<RideBooking>> getMyRides({int limit = 20}) async {
    final rows = await _client
        .from('rides')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(RideBooking.fromSupabase).toList(growable: false);
  }

  Future<RideBooking?> getActiveRide(String userId) async {
    final row = await _client
        .from('rides')
        .select()
        .eq('user_id', userId)
        .inFilter('status', [
          RideStatus.booking.name,
          RideStatus.booked.name,
          RideStatus.driver_assigned.name,
          RideStatus.in_progress.name,
        ])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : RideBooking.fromSupabase(row);
  }

  Stream<List<RideBooking>> watchMyRides(String userId) {
    late StreamController<List<RideBooking>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final rides = await _getRidesForUser(userId);
        if (!disposed && !controller.isClosed) controller.add(rides);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    Future<void> cancel() async {
      disposed = true;
      if (channel != null) {
        await _client.removeChannel(channel!);
        channel = null;
      }
    }

    controller = StreamController<List<RideBooking>>(
      onListen: () {
        refresh();
        channel = _client.channel('public:rides:$userId').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'rides',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => refresh(),
            );
        channel?.subscribe();
      },
      onCancel: cancel,
    );
    return controller.stream;
  }

  Future<List<RideBooking>> _getRidesForUser(String userId) async {
    final rows = await _client
        .from('rides')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(RideBooking.fromSupabase).toList(growable: false);
  }
}
