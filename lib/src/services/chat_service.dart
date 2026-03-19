import 'package:dio/dio.dart';

import '../models/chat_models.dart';
import 'base_service.dart';

/// Service wrapper for chat completion endpoints.
class ChatService extends BaseService {
  /// Creates a chat service.
  ChatService(super.dio);

  /// Sends a non-streaming chat request.
  ///
  /// Throws an [OllamaException] subtype for transport or API failures.
  Future<ChatResponse> chat(ChatRequest request) async {
    final payload = request.toJson()..['stream'] = false;

    try {
      final response = await dio.post<dynamic>('/api/chat', data: payload);
      ensureSuccess(response);
      return ChatResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Sends a streaming chat request and emits incremental chunks.
  ///
  /// Throws an [OllamaException] subtype for transport or API failures.
  Stream<ChatChunk> chatStream(ChatRequest request) async* {
    final payload = request.toJson()..['stream'] = true;

    Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/api/chat',
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );
      ensureSuccess(response);
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }

    final chunks = parseResponseStream(response).map(ChatChunk.fromJson);
    yield* requireDoneStream(
      chunks,
      isDone: (chunk) => chunk.done,
      endpoint: '/api/chat',
    );
  }
}
