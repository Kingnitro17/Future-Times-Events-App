sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause});
  final String message;
  final String? code;
  final Object? cause;
  @override
  String toString() => message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

final class DataFailure extends AppFailure {
  const DataFailure(super.message, {super.code, super.cause});
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code, super.cause});
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure(super.message, {super.code, super.cause});
}
