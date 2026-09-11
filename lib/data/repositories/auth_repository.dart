import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _profileLoading = false;
  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  String? get profileError => _profileError;
  bool get isLoading => _isLoading;
  bool get profileLoading => _profileLoading;
  bool get isSignedIn => _user != null;
  String get displayEmail => _user?.email ?? '';

  Future<void> initialize() async {
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
    _profileLoading = _user != null;
    // Immediately make the UI renderable — never leave isLoading=true
    // for a user that is already known to be signed in or signed out.
    _isLoading = false;
    notifyListeners();

    if (_user == null) return;

    // Profile enrichment in the background — UI already shows signed-in state.
    try {
      // 1. Try RPC get_my_profile
      final result = await _client
          .rpc('get_my_profile')
          .timeout(const Duration(seconds: 5));
      if (result is Map<String, dynamic>) {
        _profile = result;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[profile] RPC get_my_profile fallback: $error');
      }
    }

    // 2. Direct table fallback if RPC did not populate profile
    if (_profile == null) {
      try {
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', _user!.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));
        if (row != null) {
          _profile = row;
        } else {
          // 3. Auto-bootstrap profile if missing
          final fallbackName = _user!.userMetadata?['display_name']?.toString() ??
              _user!.userMetadata?['full_name']?.toString() ??
              (_user!.email != null ? _user!.email!.split('@').first : 'User');
          final bootstrap = {
            'id': _user!.id,
            'email': _user!.email,
            'display_name': fallbackName,
            'phone': _user!.phone ??
                _user!.userMetadata?['phone']?.toString(),
            'city': 'Harare',
          };
          await _client.from('profiles').upsert(bootstrap);
          _profile = bootstrap;
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[profile] direct query/bootstrap failed: $error');
        }
        _profileError =
            'Your profile could not be loaded from the server right now.';
        // Ensure UI always has at least a fallback map
        _profile = {
          'id': _user!.id,
          'email': _user!.email,
          'display_name': _user!.userMetadata?['display_name']?.toString() ??
              (_user!.email != null ? _user!.email!.split('@').first : 'User'),
          'phone': _user!.phone ??
              _user!.userMetadata?['phone']?.toString(),
          'city': 'Harare',
        };
      }
    }

    // Profile enrichment has settled, so release the Profile screen loading state
    // and let it paint the signed-in profile instead of the shimmer.
    _profileLoading = false;
    notifyListeners();
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

  /// Signs the user in with their Google account using Supabase OAuth.
  ///
  /// The platform uses the PKCE auth flow, so this launches the Google OAuth
  /// consent screen and hands the session back through the deep-link callback.
  /// Success is observed via the [onAuthStateChanged] listener inside
  /// [initialize], which calls [_synchronize].
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      // If a session token arrived synchronously (web), reflect it now.
      // On native deep-link flows the auth-state listener completes the sync.
      await _synchronize(_client.auth.currentSession);
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } catch (error) {
      throw AuthFailure(
          'Could not start Google sign-in. Check your connection and try again.',
          cause: error);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    try {
      final metadata = <String, dynamic>{};
      if (displayName != null && displayName.trim().isNotEmpty) {
        metadata['display_name'] = displayName.trim();
        metadata['full_name'] = displayName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        metadata['phone'] = phone.trim();
      }
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata.isEmpty ? null : metadata,
      );
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

  Future<void> updateDisplayName(String displayName) async {
    final user = _user;
    final value = displayName.trim();
    if (user == null || value.length < 2) {
      throw const AuthFailure('Enter a name with at least two characters.');
    }
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'display_name': value,
      });
      _profile = {...?_profile, 'display_name': value};
      notifyListeners();
    } on PostgrestException catch (error) {
      if (kDebugMode) debugPrint('[profile] update failed: ${error.code}');
      throw const AuthFailure('Your profile could not be updated. Try again.');
    }
  }

  AuthFailure _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return AuthFailure('Incorrect email or password.',
          code: error.code, cause: error);
    }
    if (message.contains('user already registered') ||
        message.contains('already in use') ||
        message.contains('already registered')) {
      return AuthFailure(
          'An account with this email already exists. Try signing in.',
          code: error.code,
          cause: error);
    }
    if (message.contains('password') &&
        (message.contains('short') ||
            message.contains('6') ||
            message.contains('weak'))) {
      return AuthFailure('Password must be at least 6 characters long.',
          code: error.code, cause: error);
    }
    if (message.contains('email not confirmed')) {
      return AuthFailure('Confirm your email before signing in.',
          code: error.code, cause: error);
    }
    if (message.contains('rate') || error.statusCode == '429') {
      return AuthFailure('Too many attempts. Please wait and try again.',
          code: error.code, cause: error);
    }
    return AuthFailure(
        error.message.isNotEmpty
            ? error.message
            : 'Authentication could not be completed. Please try again.',
        code: error.code,
        cause: error);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
