/// Typed application failures — every network/business error maps here.
///
/// Never expose raw Supabase exceptions or stack traces to users.
/// Map every failure to a user-facing [message] via [AppFailure.message].
sealed class AppFailure {
  const AppFailure();

  /// Human-readable message safe to show in the UI.
  String get message;

  /// Optional diagnostic code for logging (never shown to users).
  String? get code => null;
}

// ── Authentication ─────────────────────────────────────────────────────────

final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure();
  @override
  String get message => 'Incorrect email or password. Please try again.';
  @override
  String get code => 'invalid_credentials';
}

final class EmailNotConfirmedFailure extends AppFailure {
  const EmailNotConfirmedFailure();
  @override
  String get message =>
      'Please confirm your email address before signing in. '
      'Check your inbox for the confirmation link.';
  @override
  String get code => 'email_not_confirmed';
}

final class AccountSuspendedFailure extends AppFailure {
  const AccountSuspendedFailure();
  @override
  String get message =>
      'This account has been suspended. Please contact support.';
  @override
  String get code => 'account_suspended';
}

final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();
  @override
  String get message =>
      'Your session has expired. Please sign in again.';
  @override
  String get code => 'session_expired';
}

final class ProfileLoadFailure extends AppFailure {
  const ProfileLoadFailure();
  @override
  String get message =>
      'We could not load your profile. Please try again.';
  @override
  String get code => 'profile_load_failed';
}

final class NotAuthenticatedFailure extends AppFailure {
  const NotAuthenticatedFailure();
  @override
  String get message => 'Please sign in to continue.';
  @override
  String get code => 'not_authenticated';
}

// ── Network ────────────────────────────────────────────────────────────────

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
  @override
  String get message =>
      'Your connection appears offline. Please check your network and try again.';
  @override
  String get code => 'network_error';
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
  @override
  String get message =>
      'The request timed out. Please try again.';
  @override
  String get code => 'timeout';
}

// ── Authorization ──────────────────────────────────────────────────────────

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
  @override
  String get message =>
      'You do not have permission to perform this action.';
  @override
  String get code => 'unauthorized';
}

// ── Ticket / Inventory ─────────────────────────────────────────────────────

final class TicketSoldOutFailure extends AppFailure {
  const TicketSoldOutFailure();
  @override
  String get message => 'Sorry, this ticket type is now sold out.';
  @override
  String get code => 'sold_out';
}

final class TicketLimitExceededFailure extends AppFailure {
  const TicketLimitExceededFailure();
  @override
  String get message =>
      'You have reached the maximum number of tickets for this event.';
  @override
  String get code => 'limit_exceeded';
}

final class TicketSalesClosedFailure extends AppFailure {
  const TicketSalesClosedFailure();
  @override
  String get message => 'Ticket sales for this event are currently closed.';
  @override
  String get code => 'sales_closed';
}

final class DuplicateClaimFailure extends AppFailure {
  const DuplicateClaimFailure();
  @override
  String get message =>
      'You have already claimed a ticket for this event.';
  @override
  String get code => 'duplicate_claim';
}

// ── Payment ────────────────────────────────────────────────────────────────

final class PaymentInitFailure extends AppFailure {
  const PaymentInitFailure();
  @override
  String get message =>
      'We could not start the payment process. Please try again.';
  @override
  String get code => 'payment_init_failed';
}

final class PaymentExpiredFailure extends AppFailure {
  const PaymentExpiredFailure();
  @override
  String get message =>
      'This payment request has expired. Please start a new checkout.';
  @override
  String get code => 'payment_expired';
}

final class PaymentFailedFailure extends AppFailure {
  const PaymentFailedFailure([this._detail]);
  final String? _detail;
  @override
  String get message =>
      'The payment was not completed. Please try again or use a different EcoCash number.';
  @override
  String get code => 'payment_failed';
}

// ── Scanner ────────────────────────────────────────────────────────────────

final class CameraPermissionFailure extends AppFailure {
  const CameraPermissionFailure();
  @override
  String get message =>
      'Camera access is required to scan tickets. '
      'Please enable it in your device settings.';
  @override
  String get code => 'camera_permission_denied';
}

// ── Generic ────────────────────────────────────────────────────────────────

final class ServerFailure extends AppFailure {
  const ServerFailure([this._code]);
  final String? _code;
  @override
  String get message =>
      'Something went wrong on our end. Please try again shortly.';
  @override
  String? get code => _code ?? 'server_error';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(this._message);
  final String _message;
  @override
  String get message => _message;
  @override
  String get code => 'validation_error';
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this._code]);
  final String? _code;
  @override
  String get message =>
      'An unexpected error occurred. Please try again.';
  @override
  String? get code => _code ?? 'unknown';
}

// ── Helper: map Supabase error codes → AppFailure ─────────────────────────

AppFailure mapSupabaseError(Object error) {
  final msg = error.toString().toLowerCase();

  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid_credentials')) {
    return const InvalidCredentialsFailure();
  }
  if (msg.contains('email not confirmed')) {
    return const EmailNotConfirmedFailure();
  }
  if (msg.contains('jwt expired') || msg.contains('session_expired')) {
    return const SessionExpiredFailure();
  }
  if (msg.contains('networkerror') ||
      msg.contains('socketexception') ||
      msg.contains('connection refused')) {
    return const NetworkFailure();
  }
  if (msg.contains('timeout')) return const TimeoutFailure();
  if (msg.contains('row-level security') || msg.contains('42501')) {
    return const UnauthorizedFailure();
  }

  return UnknownFailure(error.runtimeType.toString());
}
