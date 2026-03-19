import 'logprob_models.dart';

/// Request payload for the text generation endpoint.
class GenerateRequest {
  /// Creates a generation request.
  const GenerateRequest({
    required this.model,
    required this.prompt,
    this.stream = false,
    this.suffix,
    this.images,
    this.format,
    this.options,
    this.system,
    this.template,
    this.context,
    this.raw,
    this.keepAlive,
  });

  /// Model name to run, for example `qwen2.5:7b`.
  final String model;

  /// Prompt text used as generation input.
  final String prompt;

  /// Whether to return streaming chunks instead of a single response.
  final bool stream;

  /// Optional suffix appended after generated output.
  final String? suffix;

  /// Optional base64-encoded images for multimodal generation.
  final List<String>? images;

  /// Optional output format configuration accepted by the server.
  final Object? format;

  /// Optional model runtime options.
  final Map<String, dynamic>? options;

  /// Optional system instruction used by the model.
  final String? system;

  /// Optional custom prompt template.
  final String? template;

  /// Optional context token state from previous runs.
  final List<int>? context;

  /// Optional raw mode flag that bypasses prompt templating.
  final bool? raw;

  /// Optional keep-alive policy for model residency.
  final Object? keepAlive;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'prompt': prompt,
      'stream': stream,
      if (suffix != null) 'suffix': suffix,
      if (images != null) 'images': images,
      if (format != null) 'format': format,
      if (options != null) 'options': options,
      if (system != null) 'system': system,
      if (template != null) 'template': template,
      if (context != null) 'context': context,
      if (raw != null) 'raw': raw,
      if (keepAlive != null) 'keep_alive': keepAlive,
    };
  }
}

/// Non-streaming response payload for text generation.
class GenerateResponse {
  /// Creates a generation response.
  const GenerateResponse({
    required this.model,
    required this.createdAt,
    required this.response,
    required this.done,
    this.thinking,
    this.doneReason,
    this.context,
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

  /// Generated response text.
  final String response;

  /// Optional chain-of-thought reasoning text produced by thinking models.
  final String? thinking;

  /// Whether generation is fully completed.
  final bool done;

  /// Optional completion reason returned by the server.
  final String? doneReason;

  /// Optional context token state for follow-up requests.
  final List<int>? context;

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
  factory GenerateResponse.fromJson(Map<String, dynamic> json) {
    return GenerateResponse(
      model: (json['model'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      response: (json['response'] ?? '') as String,
      thinking: json['thinking'] as String?,
      done: (json['done'] ?? false) as bool,
      doneReason: json['done_reason'] as String?,
      context: (json['context'] as List<dynamic>?)?.cast<int>(),
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

/// Streaming chunk payload for text generation.
class GenerateChunk {
  /// Creates a generation chunk.
  const GenerateChunk({
    required this.model,
    required this.createdAt,
    required this.response,
    required this.done,
    this.thinking,
    this.doneReason,
    this.context,
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

  /// Partial generated text in this chunk.
  final String response;

  /// Optional chain-of-thought reasoning text in this chunk.
  final String? thinking;

  /// Whether this is the terminal chunk.
  final bool done;

  /// Optional completion reason for the terminal chunk.
  final String? doneReason;

  /// Optional context token state included in final chunk.
  final List<int>? context;

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
  factory GenerateChunk.fromJson(Map<String, dynamic> json) {
    return GenerateChunk(
      model: (json['model'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      response: (json['response'] ?? '') as String,
      thinking: json['thinking'] as String?,
      done: (json['done'] ?? false) as bool,
      doneReason: json['done_reason'] as String?,
      context: (json['context'] as List<dynamic>?)?.cast<int>(),
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
