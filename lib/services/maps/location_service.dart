import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();

  factory LocationService() => instance;
  LocationService._internal();

  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } on PlatformException {
      return false;
    } on LocationServiceDisabledException {
      return false;
    } on Object {
      return false;
    }
  }

  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } on PlatformException {
      return LocationPermission.denied;
    } on Object {
      return LocationPermission.denied;
    }
  }

  Future<bool> requestPermission() async {
    try {
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } on PlatformException {
      return false;
    } on Object {
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      if (!await isServiceEnabled() || !await requestPermission()) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      return null;
    } on LocationServiceDisabledException {
      return null;
    } on PlatformException {
      return null;
    } on Object {
      return null;
    }
  }

  Stream<Position> positionStream() async* {
    final settings = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            intervalDuration: const Duration(seconds: 5),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          );
    try {
      if (!await isServiceEnabled() || !await requestPermission()) return;
      await for (final position
          in Geolocator.getPositionStream(locationSettings: settings)) {
        yield position;
      }
    } on TimeoutException {
      return;
    } on LocationServiceDisabledException {
      return;
    } on PlatformException {
      return;
    } on Object {
      return;
    }
  }

  double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return const Distance().as(
      LengthUnit.Meter,
      LatLng(lat1, lng1),
      LatLng(lat2, lng2),
    );
  }

  String formatDistance(double meters) {
    if (!meters.isFinite || meters < 0) return 'Distance unavailable';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<bool> isLocationServiceEnabled() => isServiceEnabled();
}
