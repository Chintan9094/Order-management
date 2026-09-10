import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

abstract final class ErrorMapper {
  static Failure mapException(Object error) {
    if (error is Failure) return error;
    if (error is String) {
      return ValidationFailure(_friendlyNetworkMessage(error) ?? error);
    }

    if (error is DioException) {
      final nested = error.error;
      if (nested is AppException) {
        return mapException(nested);
      }
      final msg = error.message ?? nested?.toString() ?? 'Request failed';
      return NetworkFailure(_friendlyNetworkMessage(msg) ?? msg);
    }

    final raw = error.toString();
    final friendly = _friendlyNetworkMessage(raw);
    if (friendly != null &&
        (error is NetworkException ||
            raw.contains('XMLHttpRequest') ||
            raw.contains('CORS') ||
            raw.contains('connection errored') ||
            raw.contains('took longer than') ||
            raw.contains('Timeout'))) {
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
    if (lower.contains('timeout') ||
        lower.contains('took longer than') ||
        lower.contains('timed out')) {
      return 'Server is waking up (common on free hosting). '
          'Wait a few seconds and tap Sign in again.';
    }
    if (lower.contains('xmlhttprequest') ||
        lower.contains('cors') ||
        lower.contains('connection errored') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception')) {
      return 'Unable to reach the server. Check your internet connection '
          'and that the API URL in .env points to your live Render backend.';
    }
    return null;
  }

  static String userMessage(Object error) => mapException(error).message;
}
