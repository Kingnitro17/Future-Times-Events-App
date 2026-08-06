import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

/// Singleton Dio client with:
/// - OAuth2 Bearer token injection
/// - Retry logic (3 attempts)
/// - Pretty logging in debug mode
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.kEventbriteBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(dio: _dio),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }
}

// ─── Auth Interceptor ──────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] =
        'Bearer ${AppConstants.kEventbriteToken}';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — surface a clear error
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: 'Eventbrite token expired or invalid. '
              'Update kEventbriteToken in AppConstants.',
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }
    handler.next(err);
  }
}

// ─── Retry Interceptor ─────────────────────────────────────────────────────

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({required this.dio});

  final Dio dio;
  static const int _maxRetries = 3;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['retryCount'] as int? ?? 0;

    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isNetworkError && attempt < _maxRetries) {
      err.requestOptions.extra['retryCount'] = attempt + 1;
      await Future.delayed(Duration(seconds: attempt + 1));
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Falls through to handler.next
      }
    }
    handler.next(err);
  }
}
