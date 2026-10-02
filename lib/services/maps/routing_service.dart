import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  static const String _osrmBase =
      'https://router.project-osrm.org/route/v1/driving';
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static final Map<String, _CachedRoute> _cache = {};

  final http.Client _client;

  Future<RouteResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (!_validCoordinates(fromLat, fromLng) ||
        !_validCoordinates(toLat, toLng)) {
      return null;
    }

    final key = _key(fromLat, fromLng, toLat, toLng);
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return cached.result;
    }
    if (cached != null) _cache.remove(key);
    return _fetchAndCache(
      key,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  Future<RouteResult?> refreshRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (!_validCoordinates(fromLat, fromLng) ||
        !_validCoordinates(toLat, toLng)) {
      return null;
    }
    final key = _key(fromLat, fromLng, toLat, toLng);
    return _fetchAndCache(
      key,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  Future<RouteResult?> reroute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) =>
      refreshRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

  static void clearCache() => _cache.clear();

  Future<RouteResult?> _fetchAndCache(
    String key, {
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final result = await _fetch(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    if (result != null) _cache[key] = _CachedRoute(result);
    return result;
  }

  Future<RouteResult?> _fetch({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final uri = Uri.parse(
      '$_osrmBase/$fromLng,$fromLat;$toLng,$toLat'
      '?overview=full&geometries=geojson&steps=true&alternatives=false',
    );
    try {
      final response = await _client.get(uri, headers: const {
        'User-Agent': 'FutureTimesEvents/1.0 (contact@futuretimesevents.com)',
      }).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        _logFailure('OSRM returned HTTP ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['code'] != 'Ok') {
        _logFailure('OSRM returned an invalid route response');
        return null;
      }
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        _logFailure('OSRM response did not include a route');
        return null;
      }
      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = route['geometry'];
      final rawCoordinates = geometry is Map ? geometry['coordinates'] : null;
      final coordinates = rawCoordinates is List ? rawCoordinates : const [];
      final polyline = coordinates
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map(_pointFromGeoJson)
          .whereType<LatLng>()
          .toList(growable: false);
      if (polyline.isEmpty) {
        _logFailure('OSRM route did not include valid geometry');
        return null;
      }

      final rawLegs = route['legs'];
      final steps = <RouteStep>[];
      if (rawLegs is List) {
        for (final leg in rawLegs.whereType<Map>()) {
          final rawSteps = leg['steps'];
          if (rawSteps is! List) continue;
          for (final step in rawSteps.whereType<Map>()) {
            final parsed = RouteStep.fromJson(
              Map<String, dynamic>.from(step),
            );
            if (parsed != null) steps.add(parsed);
          }
        }
      }
      final distance = route['distance'];
      final duration = route['duration'];
      if (distance is! num || duration is! num) {
        _logFailure('OSRM route omitted distance or duration');
        return null;
      }

      return RouteResult(
        polyline: polyline,
        distanceMeters: distance.toDouble(),
        durationSeconds: duration.toDouble(),
        steps: List.unmodifiable(steps),
      );
    } on TimeoutException {
      _logFailure('OSRM request timed out');
      return null;
    } on FormatException catch (error) {
      _logFailure('OSRM returned invalid JSON: $error');
      return null;
    } on Object catch (error) {
      _logFailure('OSRM request failed: $error');
      return null;
    }
  }

  static LatLng? _pointFromGeoJson(List<dynamic> coordinates) {
    final longitude = coordinates[0];
    final latitude = coordinates[1];
    if (longitude is! num || latitude is! num) return null;
    final lat = latitude.toDouble();
    final lng = longitude.toDouble();
    if (!_validCoordinates(lat, lng)) return null;
    return LatLng(lat, lng);
  }

  static bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180;

  static String _key(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) =>
      '${fromLat.toStringAsFixed(5)},${fromLng.toStringAsFixed(5)}|'
      '${toLat.toStringAsFixed(5)},${toLng.toStringAsFixed(5)}';

  static void _logFailure(String message) {
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

  String get distanceText => _formatDistance(distanceMeters);

  String get durationText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '$hours hr'
        : '$hours hr $remainingMinutes min';
  }
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
    required this.maneuverType,
    this.roadName,
  });

  static RouteStep? fromJson(Map<String, dynamic> json) {
    final rawManeuver = json['maneuver'];
    if (rawManeuver is! Map) return null;
    final maneuver = Map<String, dynamic>.from(rawManeuver);
    final rawLocation = maneuver['location'];
    if (rawLocation is! List || rawLocation.length < 2) return null;
    final longitude = rawLocation[0];
    final latitude = rawLocation[1];
    if (longitude is! num || latitude is! num) return null;
    final point = LatLng(latitude.toDouble(), longitude.toDouble());
    if (!_isValidPoint(point)) return null;

    final type = maneuver['type'] as String? ?? 'continue';
    final modifier = maneuver['modifier'] as String?;
    final roadName = (json['name'] as String? ?? '').trim();
    final exit = maneuver['exit'];
    final instruction = _instruction(
      type: type,
      modifier: modifier,
      roadName: roadName,
      exit: exit is num ? exit.toInt() : null,
    );
    final distance = json['distance'];
    final duration = json['duration'];
    return RouteStep(
      instruction: instruction,
      distanceMeters: distance is num ? distance.toDouble() : 0,
      durationSeconds: duration is num ? duration.toDouble() : 0,
      maneuver: point,
      maneuverType: type,
      roadName: roadName.isEmpty ? null : roadName,
    );
  }

  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng maneuver;
  final String maneuverType;
  final String? roadName;

  static String _instruction({
    required String type,
    required String? modifier,
    required String roadName,
    required int? exit,
  }) {
    final road = roadName.isEmpty ? '' : ' onto $roadName';
    switch (type) {
      case 'depart':
        final direction = modifier == null ? '' : ' $modifier';
        return 'Head$direction$road';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        final direction = switch (modifier) {
          'slight left' => 'Bear left',
          'slight right' => 'Bear right',
          'sharp left' => 'Turn sharp left',
          'sharp right' => 'Turn sharp right',
          'left' => 'Turn left',
          'right' => 'Turn right',
          'uturn' => 'Make a U-turn',
          _ => 'Continue',
        };
        return '$direction$road';
      case 'roundabout':
      case 'rotary':
        return exit == null
            ? 'Enter the roundabout$road'
            : 'Take the ${_ordinal(exit)} exit at the roundabout$road';
      case 'merge':
        return roadName.isEmpty ? 'Merge' : 'Merge onto $roadName';
      case 'fork':
        return modifier == null
            ? 'Keep at the fork$road'
            : 'Keep $modifier at the fork$road';
      default:
        return type == 'continue'
            ? 'Continue$road'
            : '${_capitalize(type)}$road';
    }
  }

  static String _ordinal(int value) {
    final suffix = value % 100 >= 11 && value % 100 <= 13
        ? 'th'
        : switch (value % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$value$suffix';
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  static bool _isValidPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude.isFinite &&
      point.longitude >= -180 &&
      point.longitude <= 180;
}

String _formatDistance(double meters) {
  if (!meters.isFinite || meters < 0) return 'Distance unavailable';
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

class _CachedRoute {
  _CachedRoute(this.result) : createdAt = DateTime.now();

  final RouteResult result;
  final DateTime createdAt;
}
