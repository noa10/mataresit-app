/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Server related exceptions
class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

/// Cache related exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// File processing related exceptions
class FileException extends AppException {
  const FileException(super.message, {super.code, super.details});
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});
}

/// Payment related exceptions
class PaymentException extends AppException {
  const PaymentException(super.message, {super.code, super.details});
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.details});
}

/// Unknown or unexpected exceptions
class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.details});
}
