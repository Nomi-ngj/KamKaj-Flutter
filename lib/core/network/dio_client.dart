import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../exceptions/app_exception.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

typedef JsonMap = Map<String, Object?>;

/// The only class that talks to Dio. Data sources depend on this and get
/// typed JSON back or an [AppException] — never a raw [DioException].
final class DioClient {
  DioClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
    Dio? dio,
  }) : _dio = dio ?? Dio(_options(config)) {
    final refreshClient = Dio(_options(config));
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      ),
    );
    if (config.enableNetworkLogs) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio _dio;

  static BaseOptions _options(AppConfig config) => BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      );

  Future<JsonMap> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: query));

  Future<List<JsonMap>> getList(String path, {Map<String, Object?>? query}) async {
    final response = await _guard(() => _dio.get<Object?>(path, queryParameters: query));
    final data = response.data;
    final list = data is Map<String, Object?> ? data['data'] : data;
    if (list is! List<Object?>) throw const ParsingException('Expected a list');
    return list.whereType<Map<String, Object?>>().toList(growable: false);
  }

  Future<JsonMap> post(String path, {Object? body}) =>
      _send(() => _dio.post<Object?>(path, data: body));

  Future<JsonMap> put(String path, {Object? body}) =>
      _send(() => _dio.put<Object?>(path, data: body));

  Future<JsonMap> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<Object?>(path, data: body));

  Future<void> delete(String path) => _guard(() => _dio.delete<Object?>(path));

  /// Multipart upload, e.g. profile photos.
  Future<JsonMap> upload(
    String path, {
    required String filePath,
    String field = 'file',
    Map<String, Object?> fields = const {},
    ProgressCallback? onProgress,
  }) async {
    final form = FormData.fromMap({
      ...fields,
      field: await MultipartFile.fromFile(filePath),
    });
    return _send(() => _dio.post<Object?>(path, data: form, onSendProgress: onProgress));
  }

  /// Downloads a file to [savePath].
  Future<void> download(String url, String savePath, {ProgressCallback? onProgress}) =>
      _guard(() => _dio.download(url, savePath, onReceiveProgress: onProgress));

  Future<JsonMap> _send(Future<Response<Object?>> Function() request) async {
    final response = await _guard(request);
    final data = response.data;
    if (data == null || data == '') return const {};
    if (data is! Map<String, Object?>) throw const ParsingException('Expected an object');
    final inner = data['data'];
    return inner is Map<String, Object?> ? inner : data;
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  static AppException _toAppException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const ServerException('Bad certificate');
      case DioExceptionType.cancel:
        return const ServerException('Request cancelled');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = error.response?.statusCode;
        if (status == 401) return const UnauthorizedException();
        if (status == 404) return const NotFoundException();
        if (status == null) return const NetworkException();
        return ServerException(
          'HTTP $status',
          statusCode: status,
          serverMessage: _serverMessage(error.response?.data),
        );
    }
  }

  static String? _serverMessage(Object? body) {
    if (body is Map<String, Object?>) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
