import '../../core/geo/geo_point.dart';
import '../../data/models/ride.dart' hide RideProvider;
import 'ride_provider.dart';

class RideAggregator {
  const RideAggregator({required this.providers});

  final List<RideProvider> providers;

  Future<List<RideQuote>> getAllQuotes({
    required GeoPoint pickup,
    required GeoPoint dropoff,
    DateTime? scheduledFor,
    int partySize = 1,
  }) async {
    final quoteLists = await Future.wait(
      providers.map(
        (provider) => provider.getQuotes(
          pickup: pickup,
          dropoff: dropoff,
          scheduledFor: scheduledFor,
          partySize: partySize,
        ),
      ),
    );
    final quotes = quoteLists.expand((items) => items).toList()
      ..sort((a, b) {
        final fareComparison = a.fareEstimate.compareTo(b.fareEstimate);
        return fareComparison == 0
            ? a.etaMinutes.compareTo(b.etaMinutes)
            : fareComparison;
      });
    return quotes;
  }
}
