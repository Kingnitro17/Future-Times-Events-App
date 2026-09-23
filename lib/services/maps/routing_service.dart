import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, _CachedRoute> _cache = {};

  Future<RouteResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final key = _key(fromLat, fromLng, toLat, toLng);
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) <
            const Duration(minutes: 5)) {
      return cached.result;
    }
    final result = await _fetch(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (result != null) _cache[key] = _CachedRoute(result);
    return result;
  }

  Future<RouteResult?> reroute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) =>
      _fetch(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

  Future<RouteResult?> _fetch({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat'
      '?overview=full&geometries=geojson&steps=true&alternatives=false',
    );
    try {
      final response = await _client.get(uri, headers: const {
        'User-Agent': 'FutureTimesEvents/1.0 (contact@futuretimesevents.com)',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _logFailure('OSRM returned ${response.statusCode}');
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>? ?? [];
      final polyline = coordinates
          .whereType<List<dynamic>>()
          .where((point) => point.length >= 2)
          .map((point) => LatLng(
                (point[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ))
          .toList();
      final legs = route['legs'] as List<dynamic>? ?? [];
      final rawSteps = legs
          .expand((leg) => (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>();
      return RouteResult(
        polyline: polyline,
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
        steps: rawSteps.map(RouteStep.fromJson).toList(),
      );
    } on Object catch (error) {
      _logFailure('OSRM request failed: $error');
      return null;
    }
  }

  String _key(double fromLat, double fromLng, double toLat, double toLng) =>
      '$fromLat,$fromLng|$toLat,$toLng';

  void _logFailure(String message) {
    developer.log(message, name: 'RoutingService');
  }
}

class RouteResult {
  const RouteResult({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  final List<LatLng> polyline;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
    required this.maneuverType,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final type = maneuver['type'] as String? ?? 'continue';
    final modifier = maneuver['modifier'] as String?;
    final name = (json['name'] as String? ?? '').trim();
    final readableType = type == 'turn'
        ? 'Turn${modifier == null ? '' : ' $modifier'}'
        : type[0].toUpperCase() + type.substring(1);
    return RouteStep(
      instruction: name.isEmpty ? readableType : '$readableType onto $name',
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
      maneuver: LatLng(
        (maneuver['location']?[1] as num?)?.toDouble() ?? 0,
        (maneuver['location']?[0] as num?)?.toDouble() ?? 0,
      ),
      maneuverType: type,
    );
  }

  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng maneuver;
  final String maneuverType;
}

class _CachedRoute {
  _CachedRoute(this.result) : createdAt = DateTime.now();
  final RouteResult result;
  final DateTime createdAt;
}
