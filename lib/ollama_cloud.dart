/// A Dart client library for interacting with Ollama-compatible APIs.
///
/// This library exports the public API surface for configuring the client,
/// sending generation and chat requests, requesting embeddings, handling model
/// management operations, and working with typed error classes.

library;

/// Client configuration and entry points.
export 'src/client/client_config.dart';

/// Main high-level client used to call Ollama endpoints.
export 'src/client/ollama_cloud_client.dart';

/// Typed exceptions that represent transport and API failures.
export 'src/errors/ollama_exception.dart';

/// Chat request/response and streaming chunk models.
export 'src/models/chat_models.dart';

/// Logprob models shared by chat and generate responses.
export 'src/models/logprob_models.dart';

/// Embeddings request/response models.
export 'src/models/embeddings_models.dart';

/// Text generation request/response and streaming chunk models.
export 'src/models/generate_models.dart';

/// Model management request/response and operation status models.
export 'src/models/model_management_models.dart';
