import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';
import '../api_endpoints.dart';

/// Attaches the bearer token and transparently refreshes it once on 401.
///
/// Concurrent 401s share a single refresh request.
final class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
    required void Function() onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _refreshClient = refreshClient,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _tokenStorage;

  /// Separate client without this interceptor to avoid refresh loops.
  final Dio _refreshClient;
  final void Function() _onSessionExpired;

  static const _retriedFlag = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    final isRefreshCall = err.requestOptions.path == ApiEndpoints.refreshToken;

    if (!isUnauthorized || alreadyRetried || isRefreshCall) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();
    if (!refreshed) {
      await _tokenStorage.clear();
      _onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      final options = err.requestOptions
        ..extra[_retriedFlag] = true
        ..headers['Authorization'] = 'Bearer ${await _tokenStorage.accessToken}';
      final response = await _refreshClient.fetch<Object?>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _refreshClient.post<Map<String, Object?>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      final access = data?['accessToken'];
      final refresh = data?['refreshToken'];
      if (access is! String || refresh is! String) return false;
      await _tokenStorage.save(accessToken: access, refreshToken: refresh);
      return true;
    } on DioException {
      return false;
    }
  }
}
