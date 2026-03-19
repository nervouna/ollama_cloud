import 'package:dio/dio.dart';

import 'ollama_exception.dart';

/// Maps transport and HTTP failures to typed [OllamaException] instances.
class OllamaErrorMapper {
  /// Creates an error mapper.
  const OllamaErrorMapper();

  /// Converts a [DioException] to a typed [OllamaException].
  ///
  /// Timeout, connectivity, cancellation, and certificate failures map to
  /// specialized exception types. HTTP error responses are delegated to
  /// [mapHttpStatus].
  OllamaException mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return OllamaTimeoutException(
          'Request timed out. Please retry.',
          details: error,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return OllamaNetworkException(
          'Network error while connecting to Ollama.',
          details: error,
        );
      case DioExceptionType.badResponse:
        return mapHttpStatus(
          error.response?.statusCode,
          error.response?.data,
        );
      case DioExceptionType.cancel:
        return OllamaNetworkException(
          'Request was cancelled.',
          details: error,
        );
      case DioExceptionType.badCertificate:
        return OllamaNetworkException(
          'TLS certificate validation failed.',
          details: error,
        );
    }
  }

  /// Converts an HTTP [statusCode] and response [data] to an exception.
  ///
  /// Returns [OllamaUnauthorizedException] for 401, [OllamaServerException]
  /// for 5xx responses, and [OllamaException] otherwise.
  OllamaException mapHttpStatus(int? statusCode, Object? data) {
    final message = _extractMessage(data);
    if (statusCode == 401) {
      return OllamaUnauthorizedException(
        message.isEmpty ? 'Unauthorized request.' : message,
        details: data,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return OllamaServerException(
        message.isEmpty ? 'Ollama server error.' : message,
        statusCode: statusCode,
        details: data,
      );
    }
    return OllamaException(
      message.isEmpty ? 'Request failed.' : message,
      statusCode: statusCode,
      details: data,
    );
  }

  /// Builds an [OllamaInvalidResponseException] for malformed payload data.
  OllamaInvalidResponseException invalidResponse(Object data) {
    return OllamaInvalidResponseException(
      'Unable to parse response from Ollama.',
      details: data,
    );
  }

  String _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final value = data['error'] ?? data['message'];
      if (value is String) {
        return value;
      }
    }
    if (data is String) {
      return data;
    }
    return '';
  }
}
