import '../errors/ollama_exception.dart';
import 'logprob_models.dart';

/// The function specification inside a tool call.
class ToolCallFunction {
  /// Creates a tool call function.
  const ToolCallFunction({
    required this.name,
    this.description,
    this.arguments,
  });

  /// Name of the function to call.
  final String name;

  /// Optional human-readable description of the function.
  final String? description;

  /// Optional map of argument names to values.
  final Map<String, dynamic>? arguments;

  /// Creates a tool call function from API JSON payload.
  factory ToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ToolCallFunction(
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
    );
  }
}

/// A tool call requested by the model.
class ToolCall {
  /// Creates a tool call.
  const ToolCall({required this.function});

  /// The function details for this tool call.
  final ToolCallFunction function;

  /// Creates a tool call from API JSON payload.
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      function: ToolCallFunction.fromJson(
        (json['function'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

/// A single chat message exchanged in a conversation.
class ChatMessage {
  /// Creates a chat message.
  const ChatMessage({
    required this.role,
    required this.content,
    this.thinking,
    this.toolCalls,
    this.images,
  });

  /// Role of the speaker, such as `user`, `assistant`, or `system`.
  final String role;

  /// Message content in plain text.
  final String content;

  /// Optional chain-of-thought reasoning text produced by thinking models.
  final String? thinking;

  /// Optional tool calls requested by the assistant.
  final List<ToolCall>? toolCalls;

  /// Optional base64-encoded images for multimodal prompts.
  final List<String>? images;

  /// Serializes this message to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (thinking != null) 'thinking': thinking,
      if (toolCalls != null)
        'tool_calls': toolCalls!.map((tc) => {
              'function': {
                'name': tc.function.name,
                if (tc.function.description != null)
                  'description': tc.function.description,
                if (tc.function.arguments != null)
                  'arguments': tc.function.arguments,
              },
            }).toList(),
      if (images != null) 'images': images,
    };
  }

  /// Creates a message from API JSON payload.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: (json['role'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      thinking: json['thinking'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(ToolCall.fromJson)
          .toList(),
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Request payload for the chat completion endpoint.
class ChatRequest {
  /// Creates a chat request.
  const ChatRequest({
    required this.model,
    required this.messages,
    this.stream = false,
    this.format,
    this.options,
    this.keepAlive,
  });

  /// Model name to run, for example `qwen2.5:7b`.
  final String model;

  /// Ordered conversation messages sent to the model.
  final List<ChatMessage> messages;

  /// Whether to receive incremental streaming chunks.
  final bool stream;

  /// Optional output format configuration accepted by the server.
  final Object? format;

  /// Optional model runtime options.
  final Map<String, dynamic>? options;

  /// Optional keep-alive policy for model residency.
  final Object? keepAlive;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((value) => value.toJson()).toList(),
      'stream': stream,
      if (format != null) 'format': format,
      if (options != null) 'options': options,
      if (keepAlive != null) 'keep_alive': keepAlive,
    };
  }
}

/// Non-streaming response payload for a chat completion request.
class ChatResponse {
  /// Creates a chat response.
  const ChatResponse({
    required this.model,
    required this.createdAt,
    required this.message,
    required this.done,
    this.doneReason,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.evalCount,
    this.evalDuration,
    this.logprobs,
  });

  /// Model that generated the response.
  final String model;

  /// Timestamp provided by the server for response creation.
  final String createdAt;

  /// Generated assistant message.
  final ChatMessage message;

  /// Whether generation is fully completed.
  final bool done;

  /// Optional completion reason returned by the server.
  final String? doneReason;

  /// End-to-end request time in nanoseconds.
  final int? totalDuration;

  /// Time spent loading model state in nanoseconds.
  final int? loadDuration;

  /// Number of prompt tokens evaluated.
  final int? promptEvalCount;

  /// Prompt evaluation time in nanoseconds.
  final int? promptEvalDuration;

  /// Number of generated tokens evaluated.
  final int? evalCount;

  /// Generation evaluation time in nanoseconds.
  final int? evalDuration;

  /// Optional per-token log-probability information.
  final List<LogprobItem>? logprobs;

  /// Creates a response from API JSON payload.
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      model: (json['model'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      message: ChatMessage.fromJson(_requireMessageMap(json)),
      done: (json['done'] ?? false) as bool,
      doneReason: json['done_reason'] as String?,
      totalDuration: (json['total_duration'] as num?)?.toInt(),
      loadDuration: (json['load_duration'] as num?)?.toInt(),
      promptEvalCount: (json['prompt_eval_count'] as num?)?.toInt(),
      promptEvalDuration: (json['prompt_eval_duration'] as num?)?.toInt(),
      evalCount: (json['eval_count'] as num?)?.toInt(),
      evalDuration: (json['eval_duration'] as num?)?.toInt(),
      logprobs: (json['logprobs'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(LogprobItem.fromJson)
          .toList(),
    );
  }
}

/// Streaming chunk payload for chat completion.
class ChatChunk {
  /// Creates a chat chunk.
  const ChatChunk({
    required this.model,
    required this.createdAt,
    required this.message,
    required this.done,
    this.doneReason,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.evalCount,
    this.evalDuration,
    this.logprobs,
  });

  /// Model that generated this chunk.
  final String model;

  /// Timestamp provided by the server for chunk creation.
  final String createdAt;

  /// Partial assistant message content in this chunk.
  final ChatMessage message;

  /// Whether this is the terminal chunk.
  final bool done;

  /// Optional completion reason for the terminal chunk.
  final String? doneReason;

  /// End-to-end request time in nanoseconds (present on terminal chunk).
  final int? totalDuration;

  /// Time spent loading model state in nanoseconds (present on terminal chunk).
  final int? loadDuration;

  /// Number of prompt tokens evaluated (present on terminal chunk).
  final int? promptEvalCount;

  /// Prompt evaluation time in nanoseconds (present on terminal chunk).
  final int? promptEvalDuration;

  /// Number of generated tokens evaluated (present on terminal chunk).
  final int? evalCount;

  /// Generation evaluation time in nanoseconds (present on terminal chunk).
  final int? evalDuration;

  /// Optional per-token log-probability information.
  final List<LogprobItem>? logprobs;

  /// Creates a chunk from API JSON payload.
  factory ChatChunk.fromJson(Map<String, dynamic> json) {
    return ChatChunk(
      model: (json['model'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      message: ChatMessage.fromJson(_requireMessageMap(json)),
      done: (json['done'] ?? false) as bool,
      doneReason: json['done_reason'] as String?,
      totalDuration: (json['total_duration'] as num?)?.toInt(),
      loadDuration: (json['load_duration'] as num?)?.toInt(),
      promptEvalCount: (json['prompt_eval_count'] as num?)?.toInt(),
      promptEvalDuration: (json['prompt_eval_duration'] as num?)?.toInt(),
      evalCount: (json['eval_count'] as num?)?.toInt(),
      evalDuration: (json['eval_duration'] as num?)?.toInt(),
      logprobs: (json['logprobs'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(LogprobItem.fromJson)
          .toList(),
    );
  }
}

Map<String, dynamic> _requireMessageMap(Map<String, dynamic> json) {
  final message = json['message'];
  if (message is Map<String, dynamic>) {
    return message;
  }

  throw OllamaInvalidResponseException(
    'Missing or invalid "message" field in chat payload.',
    details: json,
  );
}
