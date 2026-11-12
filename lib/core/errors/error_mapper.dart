import '../exceptions/app_exception.dart';
import '../logging/app_logger.dart';
import 'failure.dart';
import 'result.dart';

/// Central place that turns exceptions into user-safe [Failure]s.
abstract final class ErrorMapper {
  static Failure map(Object error, [StackTrace? stackTrace]) {
    AppLogger.error('Mapped error', error: error, stackTrace: stackTrace, tag: 'ErrorMapper');
    return switch (error) {
      NetworkException() => const NetworkFailure(),
      RequestTimeoutException() => const TimeoutFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      NotFoundException() => const NotFoundFailure(),
      CacheException() => const CacheFailure(),
      ServerException(serverMessage: final String serverMessage, :final statusCode) =>
        ServerFailure(serverMessage, statusCode),
      ServerException(:final statusCode) => ServerFailure(
          const ServerFailure().message,
          statusCode,
        ),
      ParsingException() => const ServerFailure(),
      _ => const UnexpectedFailure(),
    };
  }

  /// Runs [action] and wraps the outcome in a [Result].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Object catch (error, stackTrace) {
      return Result.failure(map(error, stackTrace));
    }
  }
}
