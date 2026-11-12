import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Development-only request logging. Headers and bodies are never logged,
/// so tokens and personal data cannot leak into logs.
final class LoggingInterceptor extends Interceptor {
  static const _tag = 'HTTP';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${options.path}', tag: _tag);
    handler.next(options);
  }

  @override
  void onResponse(Response<Object?> response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '← ${response.statusCode} ${response.requestOptions.path}',
      tag: _tag,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.debug(
      '✕ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.path}',
      tag: _tag,
    );
    handler.next(err);
  }
}
