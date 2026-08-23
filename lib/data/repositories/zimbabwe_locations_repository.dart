import 'dart:math' as math;
import '../models/zimbabwe_location.dart';

class ZimbabweLocationsRepository {
  const ZimbabweLocationsRepository();

  static const List<ZimbabweLocation> allLocations = [
    // Curated major locations first
    ZimbabweLocation(
      displayName: 'Harare',
      normalizedName: 'harare',
      province: 'Harare',
      latitude: -17.8286,
      longitude: 31.0534,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Bulawayo',
      normalizedName: 'bulawayo',
      province: 'Bulawayo',
      latitude: -20.1500,
      longitude: 28.5833,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Bindura',
      normalizedName: 'bindura',
      province: 'Mashonaland Central',
      latitude: -17.3019,
      longitude: 31.3306,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Shamva',
      normalizedName: 'shamva',
      province: 'Mashonaland Central',
      latitude: -17.0971,
      longitude: 31.6389,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Victoria Falls',
      normalizedName: 'victoria falls',
      province: 'Matabeleland North',
      latitude: -17.9329,
      longitude: 25.8307,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Mutare',
      normalizedName: 'mutare',
      province: 'Manicaland',
      latitude: -18.9707,
      longitude: 32.6710,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Gweru',
      normalizedName: 'gweru',
      province: 'Midlands',
      latitude: -19.4500,
      longitude: 29.8167,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Masvingo',
      normalizedName: 'masvingo',
      province: 'Masvingo',
      latitude: -20.0637,
      longitude: 30.8277,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Chitungwiza',
      normalizedName: 'chitungwiza',
      province: 'Harare',
      latitude: -18.0128,
      longitude: 31.0756,
      isMajor: true,
    ),
    ZimbabweLocation(
      displayName: 'Kwekwe',
      normalizedName: 'kwekwe',
      province: 'Midlands',
      latitude: -18.9281,
      longitude: 29.8153,
      isMajor: true,
    ),

    // Priority towns & urban centers
    ZimbabweLocation(
      displayName: 'Kadoma',
      normalizedName: 'kadoma',
      province: 'Mashonaland West',
      latitude: -18.3333,
      longitude: 29.9150,
    ),
    ZimbabweLocation(
      displayName: 'Chinhoyi',
      normalizedName: 'chinhoyi',
      province: 'Mashonaland West',
      latitude: -17.3667,
      longitude: 30.2000,
    ),
    ZimbabweLocation(
      displayName: 'Ruwa',
      normalizedName: 'ruwa',
      province: 'Mashonaland East',
      latitude: -17.8897,
      longitude: 31.2447,
    ),
    ZimbabweLocation(
      displayName: 'Norton',
      normalizedName: 'norton',
      province: 'Mashonaland West',
      latitude: -17.8833,
      longitude: 30.7000,
    ),
    ZimbabweLocation(
      displayName: 'Marondera',
      normalizedName: 'marondera',
      province: 'Mashonaland East',
      latitude: -18.1853,
      longitude: 31.5519,
    ),
    ZimbabweLocation(
      displayName: 'Hwange',
      normalizedName: 'hwange',
      province: 'Matabeleland North',
      latitude: -18.3667,
      longitude: 26.4833,
    ),
    ZimbabweLocation(
      displayName: 'Kariba',
      normalizedName: 'kariba',
      province: 'Mashonaland West',
      latitude: -16.5167,
      longitude: 28.8000,
    ),
    ZimbabweLocation(
      displayName: 'Beitbridge',
      normalizedName: 'beitbridge',
      province: 'Matabeleland South',
      latitude: -22.2167,
      longitude: 30.0000,
    ),
    ZimbabweLocation(
      displayName: 'Gwanda',
      normalizedName: 'gwanda',
      province: 'Matabeleland South',
      latitude: -20.9389,
      longitude: 29.0186,
    ),
    ZimbabweLocation(
      displayName: 'Zvishavane',
      normalizedName: 'zvishavane',
      province: 'Midlands',
      latitude: -20.3267,
      longitude: 30.0665,
    ),
    ZimbabweLocation(
      displayName: 'Chiredzi',
      normalizedName: 'chiredzi',
      province: 'Masvingo',
      latitude: -21.0500,
      longitude: 31.6667,
    ),
    ZimbabweLocation(
      displayName: 'Chipinge',
      normalizedName: 'chipinge',
      province: 'Manicaland',
      latitude: -20.2000,
      longitude: 32.6200,
    ),
    ZimbabweLocation(
      displayName: 'Rusape',
      normalizedName: 'rusape',
      province: 'Manicaland',
      latitude: -18.5279,
      longitude: 32.1284,
    ),
    ZimbabweLocation(
      displayName: 'Chegutu',
      normalizedName: 'chegutu',
      province: 'Mashonaland West',
      latitude: -18.1302,
      longitude: 30.1407,
    ),
    ZimbabweLocation(
      displayName: 'Karoi',
      normalizedName: 'karoi',
      province: 'Mashonaland West',
      latitude: -16.8100,
      longitude: 29.7000,
    ),
    ZimbabweLocation(
      displayName: 'Shurugwi',
      normalizedName: 'shurugwi',
      province: 'Midlands',
      latitude: -19.6667,
      longitude: 30.0000,
    ),
    ZimbabweLocation(
      displayName: 'Redcliff',
      normalizedName: 'redcliff',
      province: 'Midlands',
      latitude: -19.0333,
      longitude: 29.7833,
    ),
    ZimbabweLocation(
      displayName: 'Lupane',
      normalizedName: 'lupane',
      province: 'Matabeleland North',
      latitude: -18.9333,
      longitude: 27.7667,
    ),
    ZimbabweLocation(
      displayName: 'Plumtree',
      normalizedName: 'plumtree',
      province: 'Matabeleland South',
      latitude: -20.4781,
      longitude: 27.7972,
    ),

    // Additional legitimate urban centers
    ZimbabweLocation(
      displayName: 'Gokwe',
      normalizedName: 'gokwe',
      province: 'Midlands',
      latitude: -18.2167,
      longitude: 28.9470,
    ),
    ZimbabweLocation(
      displayName: 'Epworth',
      normalizedName: 'epworth',
      province: 'Harare',
      latitude: -17.8900,
      longitude: 31.1475,
    ),
    ZimbabweLocation(
      displayName: 'Nyanga',
      normalizedName: 'nyanga',
      province: 'Manicaland',
      latitude: -18.2167,
      longitude: 32.7500,
    ),
    ZimbabweLocation(
      displayName: 'Murewa',
      normalizedName: 'murewa',
      province: 'Mashonaland East',
      latitude: -17.6500,
      longitude: 31.7833,
    ),
    ZimbabweLocation(
      displayName: 'Mutoko',
      normalizedName: 'mutoko',
      province: 'Mashonaland East',
      latitude: -17.4000,
      longitude: 32.2167,
    ),
    ZimbabweLocation(
      displayName: 'Mazowe',
      normalizedName: 'mazowe',
      province: 'Mashonaland Central',
      latitude: -17.5040,
      longitude: 30.9739,
    ),
    ZimbabweLocation(
      displayName: 'Glendale',
      normalizedName: 'glendale',
      province: 'Mashonaland Central',
      latitude: -17.3551,
      longitude: 31.0672,
    ),
    ZimbabweLocation(
      displayName: 'Mvuma',
      normalizedName: 'mvuma',
      province: 'Midlands',
      latitude: -19.2792,
      longitude: 30.5283,
    ),
    ZimbabweLocation(
      displayName: 'Triangle',
      normalizedName: 'triangle',
      province: 'Masvingo',
      latitude: -21.0272,
      longitude: 31.4513,
    ),
    ZimbabweLocation(
      displayName: 'Esigodini',
      normalizedName: 'esigodini',
      province: 'Matabeleland South',
      latitude: -20.2925,
      longitude: 28.9381,
    ),
    ZimbabweLocation(
      displayName: 'Binga',
      normalizedName: 'binga',
      province: 'Matabeleland North',
      latitude: -17.6203,
      longitude: 27.3414,
    ),
    ZimbabweLocation(
      displayName: 'Chirundu',
      normalizedName: 'chirundu',
      province: 'Mashonaland West',
      latitude: -16.0333,
      longitude: 28.8500,
    ),
    ZimbabweLocation(
      displayName: 'Centenary',
      normalizedName: 'centenary',
      province: 'Mashonaland Central',
      latitude: -16.7229,
      longitude: 31.1146,
    ),
    ZimbabweLocation(
      displayName: 'Banket',
      normalizedName: 'banket',
      province: 'Mashonaland West',
      latitude: -17.3833,
      longitude: 30.4000,
    ),
    ZimbabweLocation(
      displayName: 'Mhangura',
      normalizedName: 'mhangura',
      province: 'Mashonaland West',
      latitude: -16.8833,
      longitude: 30.1500,
    ),
    ZimbabweLocation(
      displayName: 'Filabusi',
      normalizedName: 'filabusi',
      province: 'Matabeleland South',
      latitude: -20.5333,
      longitude: 29.2833,
    ),
  ];

  /// Initial curated major locations view (10 towns)
  static List<ZimbabweLocation> get curatedMajorLocations =>
      allLocations.where((loc) => loc.isMajor).toList();

  /// Search locations with instant partial matching
  List<ZimbabweLocation> searchLocations(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getSortedLocations();
    return allLocations.where((loc) {
      return loc.normalizedName.contains(clean) ||
          loc.province.toLowerCase().contains(clean);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Sort locations according to intelligent priority rules:
  /// 1. Current preferred location if set
  /// 2. Major cities/towns
  /// 3. Locations with active events
  /// 4. Remaining locations alphabetically
  List<ZimbabweLocation> getSortedLocations({
    String? preferredCity,
    Set<String> activeEventCities = const {},
  }) {
    final preferredClean = preferredCity?.trim().toLowerCase() ?? '';
    final activeClean =
        activeEventCities.map((c) => c.trim().toLowerCase()).toSet();

    final copy = List<ZimbabweLocation>.from(allLocations);
    copy.sort((a, b) {
      int rank(ZimbabweLocation loc) {
        if (preferredClean.isNotEmpty && loc.normalizedName == preferredClean) {
          return 1;
        }
        if (activeClean.contains(loc.normalizedName)) {
          return 2;
        }
        if (loc.isMajor) {
          return 3;
        }
        return 4;
      }

      final rankA = rank(a);
      final rankB = rank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.displayName.compareTo(b.displayName);
    });

    return copy;
  }

  /// Resolve closest Zimbabwe city using Haversine distance formula
  ZimbabweLocation findNearestLocation(double lat, double lng) {
    ZimbabweLocation nearest = allLocations.first;
    double minDistance = double.infinity;

    for (final loc in allLocations) {
      final distance =
          _haversineDistance(lat, lng, loc.latitude, loc.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = loc;
      }
    }
    return nearest;
  }

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}
