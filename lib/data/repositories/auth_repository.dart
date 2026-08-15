import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  StreamSubscription<AuthState>? _subscription;
  User? _user;
  Map<String, dynamic>? _profile;
  String? _profileError;
  bool _isLoading = true;
  bool _qaMockSession = false;
  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  String? get profileError => _profileError;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _qaMockSession || _user != null;
  bool get isQaMockSession => _qaMockSession;
  String get displayEmail =>
      _qaMockSession ? 'qa.mobile@futuretimes.test' : (_user?.email ?? '');

  Future<void> initialize() async {
    if (kDebugMode && AppConfig.qaMockAuth) {
      _qaMockSession = true;
      _profile = const {
        'id': 'local-qa-mobile',
        'display_name': 'Future Times QA',
        'email': 'qa.mobile@futuretimes.test',
        'role': 'attendee',
        'account_status': 'active',
      };
      _isLoading = false;
      notifyListeners();
      return;
    }
    _subscription = _client.auth.onAuthStateChange.listen(
      (state) => _synchronize(state.session),
      onError: (Object error, StackTrace stack) {
        if (kDebugMode) debugPrint('[auth] stream error: ${error.runtimeType}');
        _profileError =
            'Your session could not be refreshed. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );
    await _synchronize(_client.auth.currentSession);
  }

  Future<void> _synchronize(Session? session) async {
    _user = session?.user;
    _profile = null;
    _profileError = null;
    if (_user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    notifyListeners();
    try {
      final result = await _client.rpc('get_my_profile');
      if (result is Map<String, dynamic>) _profile = result;
    } on PostgrestException catch (error) {
      _profileError =
          'Your session is active, but profile details are unavailable.';
      if (kDebugMode) debugPrint('[profile] query failed: ${error.code}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
      await _synchronize(response.session);
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } catch (error) {
      throw AuthFailure(
          'Unable to reach Future Times. Check your connection and try again.',
          cause: error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    }
    await _synchronize(null);
  }

  AuthFailure _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials'))
      return AuthFailure('Incorrect email or password.',
          code: error.code, cause: error);
    if (message.contains('email not confirmed'))
      return AuthFailure('Confirm your email before signing in.',
          code: error.code, cause: error);
    if (message.contains('rate') || error.statusCode == '429')
      return AuthFailure('Too many attempts. Please wait and try again.',
          code: error.code, cause: error);
    return AuthFailure('Sign in could not be completed. Please try again.',
        code: error.code, cause: error);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
