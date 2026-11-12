/// Data-layer exceptions. Thrown by data sources, caught by repositories
/// and converted into [Failure]s by `ErrorMapper`.
sealed class AppException implements Exception {
  const AppException(this.debugMessage);

  /// Developer-facing detail. Never shown to users.
  final String debugMessage;

  @override
  String toString() => '$runtimeType: $debugMessage';
}

final class NetworkException extends AppException {
  const NetworkException([super.debugMessage = 'No connection']);
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.debugMessage = 'Timeout']);
}

final class ServerException extends AppException {
  const ServerException(super.debugMessage, {this.statusCode, this.serverMessage});

  final int? statusCode;

  /// Message returned by the API (already safe for display), if any.
  final String? serverMessage;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.debugMessage = 'Unauthorized']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.debugMessage = 'Not found']);
}

final class CacheException extends AppException {
  const CacheException([super.debugMessage = 'Cache error']);
}

final class ParsingException extends AppException {
  const ParsingException([super.debugMessage = 'Invalid response format']);
}
