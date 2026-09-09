class AppException implements Exception {
  AppException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  NetworkException([
    super.message = 'Network unavailable',
    Object? cause,
  ]) : super(cause: cause);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Unauthorized'])
      : super(statusCode: 401);
}

class ForbiddenException extends AppException {
  ForbiddenException([super.message = 'Forbidden']) : super(statusCode: 403);
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Not found']) : super(statusCode: 404);
}

class ConflictException extends AppException {
  ConflictException(super.message) : super(statusCode: 409);
}

class ValidationException extends AppException {
  ValidationException(super.message) : super(statusCode: 422);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error', int statusCode = 500])
      : super(statusCode: statusCode);
}
