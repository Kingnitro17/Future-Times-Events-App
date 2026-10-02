import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart' as launcher;
import 'package:url_launcher/url_launcher.dart';

enum TravelMode { driving, walking, bicycling, transit }

class MapApp {
  const MapApp({
    required this.name,
    required this.isInstalled,
    required this.id,
  });

  final String name;
  final bool isInstalled;
  final String id;
}

class MapLauncherService {
  static const List<launcher.MapApp> _androidMaps = [
    launcher.MapApp.petal,
    launcher.MapApp.google,
    launcher.MapApp.waze,
    launcher.MapApp.here,
    launcher.MapApp.osmand,
  ];

  static const List<launcher.MapApp> _iosMaps = [
    launcher.MapApp.apple,
    launcher.MapApp.google,
    launcher.MapApp.waze,
    launcher.MapApp.here,
    launcher.MapApp.osmand,
  ];

  static const List<launcher.MapApp> _otherMaps = [
    launcher.MapApp.google,
    launcher.MapApp.waze,
    launcher.MapApp.here,
    launcher.MapApp.osmand,
  ];

  static List<launcher.MapApp> get _preferredMaps {
    if (kIsWeb) return _otherMaps;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidMaps,
      TargetPlatform.iOS => _iosMaps,
      _ => _otherMaps,
    };
  }

  static Future<List<MapApp>> availableApps() async {
    final available = await launcher.MapLauncher.getAvailableMaps(
      _preferredMaps,
    );
    return available
        .map(
          (supported) => MapApp(
            name: supported.name,
            isInstalled: supported.isInstalled,
            id: supported.map.id,
          ),
        )
        .toList(growable: false);
  }

  static Future<bool> navigateTo({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String destinationTitle,
    double? originLatitude,
    double? originLongitude,
    String? originTitle,
    TravelMode mode = TravelMode.driving,
  }) async {
    if (!_validCoordinates(latitude, longitude) ||
        !_validOptionalCoordinates(originLatitude, originLongitude)) {
      _showFailure(context, 'The destination coordinates are invalid.');
      return false;
    }

    final destination = launcher.Location.coords(
      latitude,
      longitude,
      title: destinationTitle,
    );
    final origin = originLatitude == null
        ? null
        : launcher.Location.coords(
            originLatitude,
            originLongitude!,
            title: originTitle,
          );
    final request = launcher.MapLauncher.directions(
      destination,
      from: origin,
      mode: _launcherMode(mode),
    );

    try {
      final app = await _preferredAvailableApp();
      await request.show(map: app?.map);
      return true;
    } catch (_) {
      try {
        final launched = await launchUrl(
          _googleDirectionsUri(
            latitude: latitude,
            longitude: longitude,
            originLatitude: originLatitude,
            originLongitude: originLongitude,
            mode: mode,
          ),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {
        // Report the failure below; the fallback is best-effort.
      }
      if (!context.mounted) return false;
      _showFailure(
        context,
        'Could not open directions. Try installing Petal Maps or Google Maps.',
      );
      return false;
    }
  }

  static Future<bool> showOnMap({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    if (!_validCoordinates(latitude, longitude)) {
      _showFailure(context, 'The location coordinates are invalid.');
      return false;
    }

    final request = launcher.MapLauncher.marker(
      launcher.Location.coords(latitude, longitude, title: title),
    );
    try {
      final app = await _preferredAvailableApp();
      await request.show(map: app?.map);
      return true;
    } catch (_) {
      try {
        final launched = await launchUrl(
          Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '$title $latitude,$longitude',
          }),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {
        // Report the failure below; the fallback is best-effort.
      }
      if (!context.mounted) return false;
      _showFailure(
        context,
        'Could not open a map. Try installing Petal Maps or Google Maps.',
      );
      return false;
    }
  }

  static Future<launcher.SupportedMap?> _preferredAvailableApp() async {
    final available = await launcher.MapLauncher.getAvailableMaps(
      _preferredMaps,
    );
    for (final map in available) {
      if (map.isInstalled) return map;
    }
    return available.isEmpty ? null : available.first;
  }

  static launcher.TravelMode _launcherMode(TravelMode mode) => switch (mode) {
        TravelMode.driving => launcher.TravelMode.driving,
        TravelMode.walking => launcher.TravelMode.walking,
        TravelMode.bicycling => launcher.TravelMode.bicycling,
        TravelMode.transit => launcher.TravelMode.transit,
      };

  static Uri _googleDirectionsUri({
    required double latitude,
    required double longitude,
    required double? originLatitude,
    required double? originLongitude,
    required TravelMode mode,
  }) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
        if (originLatitude != null && originLongitude != null)
          'origin': '$originLatitude,$originLongitude',
        'travelmode': switch (mode) {
          TravelMode.driving => 'driving',
          TravelMode.walking => 'walking',
          TravelMode.bicycling => 'bicycling',
          TravelMode.transit => 'transit',
        },
      });

  static bool _validOptionalCoordinates(double? latitude, double? longitude) {
    if (latitude == null && longitude == null) return true;
    return latitude != null &&
        longitude != null &&
        _validCoordinates(latitude, longitude);
  }

  static bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static void _showFailure(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
