import 'package:dio/dio.dart';
import 'package:troona/core/network/api_endpoints.dart';
import 'package:troona/core/utils/app_logger.dart';

/// Centralized HTTP client wrapper around Dio for Troona.
/// Configured with strict timeouts to ensure offline-first responsiveness.
class ApiClient {
  final Dio dio;

  ApiClient({Dio? customDio})
    : dio =
          customDio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.lastFmBaseUrl,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 4),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'TroonaMusic/1.0.0 (troona.music.app)',
              },
              responseType: ResponseType.json,
            ),
          ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          appLogger.w(
            'ApiClient: Request failed (${error.requestOptions.uri}): ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
