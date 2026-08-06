import 'package:equatable/equatable.dart';
import '../../../shared/models/user_profile.dart';
import '../../../core/errors/app_failure.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  final String email;
  final String password;
  final String displayName;
  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthSessionRestored extends AuthEvent {
  const AuthSessionRestored(this.profile);
  final UserProfile? profile;
  @override
  List<Object?> get props => [profile];
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial / checking session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Actively loading (sign-in / sign-up in progress).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated with a valid profile.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.profile,
    this.profileWarning,
  });
  final UserProfile profile;
  /// Non-null if profile loaded but with a degraded state.
  final String? profileWarning;
  @override
  List<Object?> get props => [profile, profileWarning];
}

/// Fully signed out.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Sign-up succeeded but email confirmation is required.
class AuthEmailConfirmationRequired extends AuthState {
  const AuthEmailConfirmationRequired(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

/// Password reset email sent.
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

/// Auth operation failed.
class AuthFailureState extends AuthState {
  const AuthFailureState(this.failure);
  final AppFailure failure;
  @override
  List<Object?> get props => [failure];
}
