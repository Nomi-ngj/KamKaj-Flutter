import 'package:equatable/equatable.dart';

/// Domain-level error. Every repository returns a [Failure] instead of
/// throwing, and the UI maps it to a user-friendly message.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Safe, user-facing message. Never contains technical details.
  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your connection and try again.',
  ]);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request took too long. Please try again.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again later.',
    this.statusCode,
  ]);

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'We couldn\'t find what you were looking for.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read saved data.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something unexpected happened. Please try again.',
  ]);
}
