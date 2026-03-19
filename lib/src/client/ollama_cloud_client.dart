import 'package:dio/dio.dart';

import '../models/chat_models.dart';
import '../models/embeddings_models.dart';
import '../models/generate_models.dart';
import '../models/model_management_models.dart';
import '../services/chat_service.dart';
import '../services/embeddings_service.dart';
import '../services/generate_service.dart';
import '../services/models_service.dart';
import '../transport/dio_factory.dart';
import 'client_config.dart';

/// High-level client for interacting with Ollama APIs.
///
/// This client exposes synchronous and streaming APIs for generation, chat,
/// embeddings, and model management.
class OllamaCloudClient {
  /// Creates a client from a prepared [Dio] instance.
  OllamaCloudClient._(this._dio)
      : _generateService = GenerateService(_dio),
        _chatService = ChatService(_dio),
        _embeddingsService = EmbeddingsService(_dio),
        _modelsService = ModelsService(_dio);

  /// Creates a client using [config] and a default `Dio` configuration.
  factory OllamaCloudClient({required OllamaClientConfig config}) {
    final dio = DioFactory.create(config);
    return OllamaCloudClient._(dio);
  }

  /// Creates a client using an externally managed [dio] instance.
  factory OllamaCloudClient.withDio(Dio dio) {
    return OllamaCloudClient._(dio);
  }

  final Dio _dio;
  final GenerateService _generateService;
  final ChatService _chatService;
  final EmbeddingsService _embeddingsService;
  final ModelsService _modelsService;

  /// Generates text from a prompt and model configuration.
  ///
  /// Returns a single completion response.
  ///
  /// Throws an [OllamaException] subtype when network, timeout, or server
  /// errors occur.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.generate(
  ///   GenerateRequest(model: 'qwen2.5:7b', prompt: 'Hello'),
  /// );
  /// print(response.response);
  /// ```
  Future<GenerateResponse> generate(GenerateRequest request) {
    return _generateService.generate(request);
  }

  /// Streams incremental generation chunks for a prompt.
  ///
  /// Useful for token-by-token or partial output rendering.
  ///
  /// Throws an [OllamaException] subtype when network, timeout, or server
  /// errors occur.
  Stream<GenerateChunk> generateStream(GenerateRequest request) {
    return _generateService.generateStream(request);
  }

  /// Sends a chat completion request and returns a single response.
  ///
  /// Throws an [OllamaException] subtype when network, timeout, or server
  /// errors occur.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.chat(
  ///   ChatRequest(
  ///     model: 'qwen2.5:7b',
  ///     messages: [ChatMessage(role: 'user', content: 'Hi there')],
  ///   ),
  /// );
  /// print(response.message.content);
  /// ```
  Future<ChatResponse> chat(ChatRequest request) {
    return _chatService.chat(request);
  }

  /// Streams incremental chat completion chunks.
  ///
  /// Each emitted [ChatChunk] contains partial assistant output.
  ///
  /// Throws an [OllamaException] subtype when network, timeout, or server
  /// errors occur.
  Stream<ChatChunk> chatStream(ChatRequest request) {
    return _chatService.chatStream(request);
  }

  /// Requests embedding vectors for input text.
  ///
  /// Throws an [OllamaException] subtype when network, timeout, or server
  /// errors occur.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.embeddings(
  ///   EmbeddingsRequest(model: 'nomic-embed-text', input: 'hello world'),
  /// );
  /// print(response.embeddings.length);
  /// ```
  Future<EmbeddingsResponse> embeddings(EmbeddingsRequest request) {
    return _embeddingsService.embeddings(request);
  }

  /// Lists locally available models.
  Future<TagsResponse> listLocalModels() {
    return _modelsService.listLocalModels();
  }

  /// Lists models currently loaded and running.
  Future<TagsResponse> listRunningModels() {
    return _modelsService.listRunningModels();
  }

  /// Retrieves detailed metadata for a specific model.
  Future<ShowModelResponse> showModel(ShowModelRequest request) {
    return _modelsService.showModel(request);
  }

  /// Deletes a model by its [model] name.
  Future<void> deleteModel(String model) {
    return _modelsService.deleteModel(model);
  }

  /// Pulls a model and waits for the final operation status.
  Future<ModelOperationStatus> pullModel(PullModelRequest request) {
    return _modelsService.pullModel(request);
  }

  /// Pulls a model and emits progress updates as a stream.
  ///
  /// Example:
  /// ```dart
  /// await for (final status in client.pullModelStream(
  ///   PullModelRequest(model: 'qwen2.5:7b'),
  /// )) {
  ///   print(status.status);
  /// }
  /// ```
  Stream<ModelOperationStatus> pullModelStream(PullModelRequest request) {
    return _modelsService.pullModelStream(request);
  }

  /// Pushes a model and waits for the final operation status.
  Future<ModelOperationStatus> pushModel(PushModelRequest request) {
    return _modelsService.pushModel(request);
  }

  /// Pushes a model and emits progress updates as a stream.
  ///
  /// Example:
  /// ```dart
  /// await for (final status in client.pushModelStream(
  ///   PushModelRequest(model: 'qwen2.5:7b'),
  /// )) {
  ///   print(status.status);
  /// }
  /// ```
  Stream<ModelOperationStatus> pushModelStream(PushModelRequest request) {
    return _modelsService.pushModelStream(request);
  }

  /// Closes the underlying HTTP client.
  ///
  /// When [force] is true, in-flight requests are aborted immediately.
  void close({bool force = true}) {
    _dio.close(force: force);
  }
}
