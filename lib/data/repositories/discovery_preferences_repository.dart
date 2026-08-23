import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryPreferencesRepository extends ChangeNotifier {
  DiscoveryPreferencesRepository._(this._preferences)
      : _city = _preferences.getString(cityKey) ?? 'Harare',
        _latitude = _preferences.getDouble(latKey),
        _longitude = _preferences.getDouble(lngKey),
        _interests = Set.unmodifiable(
            _preferences.getStringList(interestsKey) ?? const []);

  static const completionKey = 'onboarding_complete';
  static const cityKey = 'discovery_city';
  static const latKey = 'discovery_lat';
  static const lngKey = 'discovery_lng';
  static const interestsKey = 'event_interests';
  static const recentSearchesKey = 'recent_event_searches';

  final SharedPreferences _preferences;
  String _city;
  double? _latitude;
  double? _longitude;
  Set<String> _interests;

  static Future<DiscoveryPreferencesRepository> create() async =>
      DiscoveryPreferencesRepository._(await SharedPreferences.getInstance());

  String get city => _city;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  Set<String> get interests => _interests;
  List<String> get recentSearches =>
      _preferences.getStringList(recentSearchesKey) ?? const [];

  Future<void> save({
    required String city,
    required Set<String> interests,
    double? latitude,
    double? longitude,
  }) async {
    _city = city;
    _interests = Set.unmodifiable(interests);
    _latitude = latitude;
    _longitude = longitude;

    final futures = <Future<bool>>[
      _preferences.setBool(completionKey, true),
      _preferences.setString(cityKey, city),
      _preferences.setStringList(interestsKey, interests.toList()..sort()),
    ];

    if (latitude != null) {
      futures.add(_preferences.setDouble(latKey, latitude));
    } else {
      futures.add(_preferences.remove(latKey));
    }

    if (longitude != null) {
      futures.add(_preferences.setDouble(lngKey, longitude));
    } else {
      futures.add(_preferences.remove(lngKey));
    }

    await Future.wait(futures);
    notifyListeners();
  }

  Future<void> rememberSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final searches = recentSearches.where((item) => item != value).toList();
    searches.insert(0, value);
    await _preferences.setStringList(
      recentSearchesKey,
      searches.take(5).toList(),
    );
    notifyListeners();
  }
}
