import 'package:equatable/equatable.dart';

/// Domain-level failure types mapped from exceptions / network.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Unable to connect. Please try again.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = "You don't have permission to perform this action.",
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested resource was not found.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again.',
  ]);
}
