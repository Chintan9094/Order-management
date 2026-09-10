import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'auth_token_store.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(authTokenStoreProvider);
  return ApiClient(config: config, tokenStore: tokenStore);
});

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AuthTokenStore tokenStore,
  }) : _tokenStore = tokenStore {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: AppConstants.defaultConnectTimeout,
        receiveTimeout: AppConstants.defaultReceiveTimeout,
        sendTimeout: AppConstants.defaultSendTimeout,
        headers: {
          Headers.contentTypeHeader: Headers.jsonContentType,
          Headers.acceptHeader: Headers.jsonContentType,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final staffToken = await _tokenStore.readStaffAccessToken();
          if (staffToken != null && staffToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $staffToken';
          }

          final customerToken = await _tokenStore.readCustomerSessionToken();
          if (customerToken != null && customerToken.isNotEmpty) {
            options.headers['X-Session-Token'] = customerToken;
          }

          final clientId = await _tokenStore.readOrCreateClientSessionId();
          options.headers['X-Client-Session'] = clientId;

          handler.next(options);
        },
        onError: (error, handler) async {
          // One retry for cold-start / wake timeouts (Render free tier).
          final retried = error.requestOptions.extra['retried'] == true;
          final isTimeout = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError;

          if (!retried && isTimeout) {
            final opts = error.requestOptions;
            opts.extra['retried'] = true;
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(_mapDioError(retryError));
            }
          }

          handler.next(_mapDioError(error));
        },
      ),
    );

    if (config.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (obj) => appLogger.d(obj),
        ),
      );
    }
  }

  late final Dio _dio;
  final AuthTokenStore _tokenStore;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  DioException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final message = _extractMessage(error) ?? error.message ?? 'Request failed';

    final AppException mapped = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        NetworkException(message, error),
      _ => switch (status) {
          401 => UnauthorizedException(message),
          403 => ForbiddenException(message),
          404 => NotFoundException(message),
          409 => ConflictException(message),
          422 => ValidationException(message),
          final code when code != null && code >= 500 =>
            ServerException(message, code),
          _ => AppException(message, statusCode: status, cause: error),
        },
    };

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: mapped,
      message: mapped.message,
    );
  }

  String? _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
