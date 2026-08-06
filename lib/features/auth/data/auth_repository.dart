import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_failure.dart';
import '../../core/supabase/supabase_service.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/enums.dart';

/// Auth data repository — all Supabase auth interactions.
///
/// Mirrors the auth-context.tsx pattern from the website:
/// - get_my_profile RPC for profile loading
/// - Fallback direct profile query if RPC fails
/// - Role normalization matching the website
class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => SupabaseService.client;

  // ── Sign In ────────────────────────────────────────────────────────────────

  Future<({UserProfile profile, String? profileError})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) throw const InvalidCredentialsFailure();
      return await _loadProfile(response.user!);
    } on AppFailure {
      rethrow;
    } on AuthException catch (e) {
      throw mapSupabaseError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  Future<({UserProfile? profile, bool needsConfirmation})> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': displayName,
          // Role is deliberately locked to attendee for public sign-up.
          // Elevated roles are granted in DB by an administrator.
          'role': 'attendee',
        },
      );

      // Session null means email confirmation required.
      if (response.session == null) {
        return (profile: null, needsConfirmation: true);
      }

      final result = await _loadProfile(response.user!);
      return (profile: result.profile, needsConfirmation: false);
    } on AppFailure {
      rethrow;
    } on AuthException catch (e) {
      throw mapSupabaseError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      dev.log('[AuthRepository] signOut error: $e', name: 'AuthRepository');
    }
  }

  // ── Password Recovery ──────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.futuretimes.events://reset-password',
      );
    } on AuthException catch (e) {
      throw mapSupabaseError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw mapSupabaseError(e.message);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // ── Session / Profile ──────────────────────────────────────────────────────

  /// Load profile for the current session (called on app start).
  Future<UserProfile?> loadCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final result = await _loadProfile(user);
      return result.profile;
    } catch (_) {
      return null;
    }
  }

  /// Internal: load profile via get_my_profile RPC with fallback.
  Future<({UserProfile profile, String? profileError})> _loadProfile(
    User authUser,
  ) async {
    // 1. Try the RPC (same as website's loadProfile function)
    try {
      final rpcResult = await _client.rpc('get_my_profile');
      if (rpcResult != null && rpcResult is Map<String, dynamic>) {
        final json = rpcResult;
        if (json['id'] != authUser.id) {
          throw const ProfileLoadFailure();
        }
        final status = AccountStatus.fromString(json['account_status'] as String?);
        if (status != AccountStatus.active) {
          return (
            profile: _profileFromAuth(authUser),
            profileError:
                'This account is not active. Contact a platform administrator.',
          );
        }
        return (profile: UserProfile.fromJson(json), profileError: null);
      }
    } catch (e) {
      dev.log(
        '[AuthRepository] get_my_profile RPC failed: $e — trying direct query',
        name: 'AuthRepository',
      );
    }

    // 2. Fallback: direct profiles query (mirrors website's fallback)
    try {
      final directResult = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (directResult != null) {
        return (
          profile: UserProfile.fromJson(directResult as Map<String, dynamic>),
          profileError: null,
        );
      }
    } catch (e) {
      dev.log(
        '[AuthRepository] direct profile query also failed: $e',
        name: 'AuthRepository',
      );
    }

    // 3. Last resort: build minimal profile from auth metadata
    return (
      profile: _profileFromAuth(authUser),
      profileError:
          'Your account is signed in, but its permissions could not be verified.',
    );
  }

  /// Bootstrap: ensure profile row exists (same as ensureProfile in website).
  Future<void> ensureProfile(User authUser) async {
    try {
      final existing = await _client.rpc('get_my_profile');
      if (existing != null) return;
    } catch (_) {}

    try {
      final meta = authUser.userMetadata ?? {};
      final displayName = (meta['name'] as String?) ??
          (meta['full_name'] as String?) ??
          authUser.email?.split('@').first ??
          'User';

      await _client.from('profiles').insert({
        'id': authUser.id,
        'email': authUser.email ?? '',
        'display_name': displayName,
        'initials': displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase(),
        'avatar_url': '',
        'avatar_color': '#7B61FF',
      });
    } catch (e) {
      // Ignore 23505 (unique violation — profile already exists)
      dev.log('[AuthRepository] ensureProfile: $e', name: 'AuthRepository');
    }
  }

  /// Build a minimal UserProfile from Supabase auth metadata.
  UserProfile _profileFromAuth(User authUser) {
    final meta = authUser.userMetadata ?? {};
    final name = (meta['name'] as String?) ??
        (meta['full_name'] as String?) ??
        authUser.email?.split('@').first ??
        'User';
    return UserProfile(
      id: authUser.id,
      email: authUser.email ?? '',
      displayName: name,
      initials: name.substring(0, name.length.clamp(0, 2)).toUpperCase(),
      role: UserRole.fromString(meta['role'] as String?),
    );
  }

  /// Auth state stream for the app to listen to.
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;
}
