import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryPreferencesRepository extends ChangeNotifier {
  DiscoveryPreferencesRepository._(this._preferences)
      : _city = _preferences.getString(cityKey) ?? 'Harare',
        _interests = Set.unmodifiable(
            _preferences.getStringList(interestsKey) ?? const []);

  static const completionKey = 'onboarding_complete';
  static const cityKey = 'discovery_city';
  static const interestsKey = 'event_interests';
  static const recentSearchesKey = 'recent_event_searches';

  final SharedPreferences _preferences;
  String _city;
  Set<String> _interests;

  static Future<DiscoveryPreferencesRepository> create() async =>
      DiscoveryPreferencesRepository._(await SharedPreferences.getInstance());

  String get city => _city;
  Set<String> get interests => _interests;
  List<String> get recentSearches =>
      _preferences.getStringList(recentSearchesKey) ?? const [];

  Future<void> save(
      {required String city, required Set<String> interests}) async {
    _city = city;
    _interests = Set.unmodifiable(interests);
    await Future.wait([
      _preferences.setBool(completionKey, true),
      _preferences.setString(cityKey, city),
      _preferences.setStringList(interestsKey, interests.toList()..sort()),
    ]);
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
