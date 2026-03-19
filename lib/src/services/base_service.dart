import 'package:dio/dio.dart';

import '../errors/error_mapper.dart';
import '../errors/ollama_exception.dart';
import '../transport/ndjson_stream_parser.dart';

/// Shared service utilities for request validation and stream handling.
abstract class BaseService {
  /// Creates a base service with [dio] and an optional custom [mapper].
  BaseService(this.dio, [OllamaErrorMapper? mapper])
      : errorMapper = mapper ?? const OllamaErrorMapper();

  /// HTTP client used for API calls.
  final Dio dio;

  /// Maps transport and API failures into typed exceptions.
  final OllamaErrorMapper errorMapper;

  /// Ensures the response has a successful 2xx status code.
  ///
  /// Throws an [OllamaException] when the status indicates failure.
  Response<T> ensureSuccess<T>(Response<T> response) {
    final code = response.statusCode;
    if (code != null && code >= 200 && code < 300) {
      return response;
    }
    throw errorMapper.mapHttpStatus(response.statusCode, response.data);
  }

  /// Ensures response [data] is a JSON object.
  ///
  /// Throws [OllamaInvalidResponseException] for non-object payloads.
  Map<String, dynamic> ensureJsonMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw errorMapper.invalidResponse(data ?? 'null');
  }

  /// Parses an NDJSON response stream into JSON object chunks.
  ///
  /// Throws [OllamaInvalidResponseException] when response body is not a
  /// stream.
  Stream<Map<String, dynamic>> parseResponseStream(Response<dynamic> response) {
    final body = response.data;
    if (body is! ResponseBody) {
      throw OllamaInvalidResponseException(
        'Expected stream response body.',
        details: body,
      );
    }
    return parseNdjson(body.stream);
  }

  /// Requires at least one `done=true` chunk before the stream closes.
  ///
  /// Throws [OllamaInvalidResponseException] when the stream closes without a
  /// terminal chunk for [endpoint].
  Stream<T> requireDoneStream<T>(
    Stream<T> source, {
    required bool Function(T chunk) isDone,
    required String endpoint,
  }) async* {
    var completed = false;
    await for (final chunk in source) {
      if (isDone(chunk)) {
        completed = true;
      }
      yield chunk;
    }

    if (!completed) {
      throw OllamaInvalidResponseException(
        'Stream closed before done=true for $endpoint.',
      );
    }
  }
}
