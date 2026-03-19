import 'package:dio/dio.dart';

import '../models/embeddings_models.dart';
import 'base_service.dart';

/// Service wrapper for embeddings endpoints.
class EmbeddingsService extends BaseService {
  /// Creates an embeddings service.
  EmbeddingsService(super.dio);

  /// Sends an embeddings request.
  ///
  /// Throws an [OllamaException] subtype for transport or API failures.
  Future<EmbeddingsResponse> embeddings(EmbeddingsRequest request) async {
    try {
      final response = await dio.post<dynamic>(
        '/api/embeddings',
        data: request.toJson(),
      );
      ensureSuccess(response);
      return EmbeddingsResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }
}
