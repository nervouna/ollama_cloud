import 'package:dio/dio.dart';

import '../client/client_config.dart';

/// Builds configured [Dio] instances for the client.
class DioFactory {
  /// Utility class with static factory methods.
  const DioFactory._();

  /// Creates a configured [Dio] instance from [config].
  ///
  /// This applies base URL, timeouts, default JSON headers, and optional
  /// bearer authentication when an API key is configured.
  static Dio create(OllamaClientConfig config) {
    final options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...config.headers,
      },
      validateStatus: (_) => true,
    );

    final dio = Dio(options);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final apiKey = config.apiKey;
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $apiKey';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
