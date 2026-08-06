import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../data/auth_repository.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSessionRestored>(_onSessionRestored);

    // Listen to Supabase auth state changes (token refresh, sign-out from other tabs, etc.)
    _authSubscription = _repository.authStateStream.listen((event) {
      if (event.event == sb.AuthChangeEvent.signedOut) {
        add(const AuthSignOutRequested());
      } else if (event.event == sb.AuthChangeEvent.tokenRefreshed) {
        // Re-load profile silently on token refresh
        _repository.loadCurrentProfile().then((profile) {
          if (profile != null) {
            add(AuthSessionRestored(profile));
          }
        });
      }
    });
  }

  final AuthRepository _repository;
  StreamSubscription<sb.AuthState>? _authSubscription;

  // ── Startup: restore session ───────────────────────────────────────────────
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthInitial());
    try {
      final profile = await _repository.loadCurrentProfile();
      if (profile != null) {
        emit(AuthAuthenticated(profile: profile));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      dev.log('[AuthBloc] startup error: $e', name: 'AuthBloc');
      emit(const AuthUnauthenticated());
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(
        profile: result.profile,
        profileWarning: result.profileError,
      ));
    } on AppFailure catch (f) {
      emit(AuthFailureState(f));
    } catch (e) {
      emit(AuthFailureState(mapSupabaseError(e)));
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      if (result.needsConfirmation) {
        emit(AuthEmailConfirmationRequired(event.email));
      } else if (result.profile != null) {
        emit(AuthAuthenticated(profile: result.profile!));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on AppFailure catch (f) {
      emit(AuthFailureState(f));
    } catch (e) {
      emit(AuthFailureState(mapSupabaseError(e)));
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  Future<void> _onPasswordReset(
      AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent(event.email));
    } on AppFailure catch (f) {
      emit(AuthFailureState(f));
    } catch (e) {
      emit(AuthFailureState(mapSupabaseError(e)));
    }
  }

  // ── Session Restored (from Supabase listener) ──────────────────────────────
  Future<void> _onSessionRestored(
      AuthSessionRestored event, Emitter<AuthState> emit) async {
    if (event.profile != null) {
      emit(AuthAuthenticated(profile: event.profile!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
