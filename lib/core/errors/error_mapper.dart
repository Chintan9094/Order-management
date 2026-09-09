import 'exceptions.dart';
import 'failures.dart';

abstract final class ErrorMapper {
  static Failure mapException(Object error) {
    if (error is Failure) return error;
    if (error is String) {
      return ValidationFailure(_friendlyNetworkMessage(error) ?? error);
    }

    final raw = error.toString();
    final friendly = _friendlyNetworkMessage(raw);
    if (friendly != null &&
        (error is NetworkException ||
            raw.contains('XMLHttpRequest') ||
            raw.contains('CORS') ||
            raw.contains('connection errored'))) {
      return NetworkFailure(friendly);
    }

    if (error is NetworkException) {
      return NetworkFailure(
        _friendlyNetworkMessage(error.message) ?? error.message,
      );
    }
    if (error is UnauthorizedException || error is ForbiddenException) {
      final message = error is AppException
          ? error.message
          : "You don't have permission to perform this action.";
      return UnauthorizedFailure(message);
    }
    if (error is NotFoundException) {
      return NotFoundFailure(error.message);
    }
    if (error is ConflictException) {
      return ConflictFailure(error.message);
    }
    if (error is ValidationException) {
      return ValidationFailure(error.message);
    }
    if (error is ServerException) {
      return ServerFailure(error.message);
    }
    if (error is AppException) {
      return ServerFailure(
        _friendlyNetworkMessage(error.message) ?? error.message,
      );
    }
    return const UnknownFailure();
  }

  static String? _friendlyNetworkMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('xmlhttprequest') ||
        lower.contains('cors') ||
        lower.contains('connection errored') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception')) {
      return 'Unable to reach the server. On a phone, localhost will not work — '
          'use your PC LAN IP in .env (example: http://192.168.1.10:8000/api/v1), '
          'run `php artisan serve --host=0.0.0.0 --port=8000`, and keep phone + PC '
          'on the same Wi‑Fi.';
    }
    return null;
  }

  static String userMessage(Object error) => mapException(error).message;
}
