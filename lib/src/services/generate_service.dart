import 'package:dio/dio.dart';

import '../models/generate_models.dart';
import 'base_service.dart';

/// Service wrapper for text generation endpoints.
class GenerateService extends BaseService {
  /// Creates a generation service.
  GenerateService(super.dio);

  /// Sends a non-streaming generation request.
  ///
  /// Throws an [OllamaException] subtype for transport or API failures.
  Future<GenerateResponse> generate(GenerateRequest request) async {
    final payload = request.toJson()..['stream'] = false;

    try {
      final response = await dio.post<dynamic>('/api/generate', data: payload);
      ensureSuccess(response);
      return GenerateResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Sends a streaming generation request and emits incremental chunks.
  ///
  /// Throws an [OllamaException] subtype for transport or API failures.
  Stream<GenerateChunk> generateStream(GenerateRequest request) async* {
    final payload = request.toJson()..['stream'] = true;

    Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/api/generate',
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );
      ensureSuccess(response);
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }

    final chunks = parseResponseStream(response).map(GenerateChunk.fromJson);
    yield* requireDoneStream(
      chunks,
      isDone: (chunk) => chunk.done,
      endpoint: '/api/generate',
    );
  }
}
