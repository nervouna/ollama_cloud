/// Summary information for a model returned by list endpoints.
class ModelSummary {
  /// Creates a model summary.
  const ModelSummary({
    required this.name,
    required this.model,
    required this.size,
    this.digest,
    this.details,
    this.modifiedAt,
    this.expiresAt,
    this.sizeVram,
  });

  /// Display name or tag of the model.
  final String name;

  /// Canonical model identifier.
  final String model;

  /// Total model size in bytes.
  final int size;

  /// Optional content digest for model verification.
  final String? digest;

  /// Optional provider-specific model details.
  final Map<String, dynamic>? details;

  /// Optional timestamp for last modification.
  final String? modifiedAt;

  /// Optional timestamp when loaded model expires from memory.
  final String? expiresAt;

  /// Optional VRAM footprint in bytes.
  final int? sizeVram;

  /// Creates a model summary from API JSON payload.
  factory ModelSummary.fromJson(Map<String, dynamic> json) {
    return ModelSummary(
      name: (json['name'] ?? '') as String,
      model: (json['model'] ?? '') as String,
      size: (json['size'] as num? ?? 0).toInt(),
      digest: json['digest'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      modifiedAt: json['modified_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      sizeVram: (json['size_vram'] as num?)?.toInt(),
    );
  }
}

/// Response payload for model listing endpoints.
class TagsResponse {
  /// Creates a tags response.
  const TagsResponse({required this.models});

  /// Models included in the response.
  final List<ModelSummary> models;

  /// Creates a tags response from API JSON payload.
  factory TagsResponse.fromJson(Map<String, dynamic> json) {
    final models = (json['models'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ModelSummary.fromJson)
        .toList();

    return TagsResponse(models: models);
  }
}

/// Request payload for pulling a model from a registry.
class PullModelRequest {
  /// Creates a pull-model request.
  const PullModelRequest({
    required this.model,
    this.insecure,
  });

  /// Model name to pull.
  final String model;

  /// Whether to allow insecure registry access.
  final bool? insecure;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (insecure != null) 'insecure': insecure,
    };
  }
}

/// Request payload for pushing a model to a registry.
class PushModelRequest {
  /// Creates a push-model request.
  const PushModelRequest({
    required this.model,
    this.insecure,
  });

  /// Model name to push.
  final String model;

  /// Whether to allow insecure registry access.
  final bool? insecure;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (insecure != null) 'insecure': insecure,
    };
  }
}

/// Request payload for retrieving model details.
class ShowModelRequest {
  /// Creates a show-model request.
  const ShowModelRequest({required this.model, this.verbose});

  /// Model name to inspect.
  final String model;

  /// Whether to request verbose output.
  final bool? verbose;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (verbose != null) 'verbose': verbose,
    };
  }
}

/// Incremental or final status payload for pull and push operations.
class ModelOperationStatus {
  /// Creates a model operation status.
  const ModelOperationStatus({
    this.status,
    this.digest,
    this.total,
    this.completed,
    this.error,
    this.done,
  });

  /// Human-readable status message.
  final String? status;

  /// Optional digest of the currently processed layer.
  final String? digest;

  /// Optional total bytes expected.
  final int? total;

  /// Optional completed bytes.
  final int? completed;

  /// Optional error message emitted by the server.
  final String? error;

  /// Whether the operation has completed.
  final bool? done;

  /// Creates an operation status from API JSON payload.
  factory ModelOperationStatus.fromJson(Map<String, dynamic> json) {
    return ModelOperationStatus(
      status: json['status'] as String?,
      digest: json['digest'] as String?,
      total: (json['total'] as num?)?.toInt(),
      completed: (json['completed'] as num?)?.toInt(),
      error: json['error'] as String?,
      done: json['done'] as bool?,
    );
  }
}

/// Response payload for detailed model inspection.
class ShowModelResponse {
  /// Creates a show-model response.
  const ShowModelResponse({
    this.modelfile,
    this.parameters,
    this.template,
    this.details,
    this.modelInfo,
    this.modifiedAt,
  });

  /// Raw model file content.
  final String? modelfile;

  /// Parameter section extracted by the server.
  final String? parameters;

  /// Prompt template used by the model.
  final String? template;

  /// Optional model details map.
  final Map<String, dynamic>? details;

  /// Optional low-level model metadata.
  final Map<String, dynamic>? modelInfo;

  /// Optional timestamp for last modification.
  final String? modifiedAt;

  /// Creates a show-model response from API JSON payload.
  factory ShowModelResponse.fromJson(Map<String, dynamic> json) {
    return ShowModelResponse(
      modelfile: json['modelfile'] as String?,
      parameters: json['parameters'] as String?,
      template: json['template'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      modelInfo: json['model_info'] as Map<String, dynamic>?,
      modifiedAt: json['modified_at'] as String?,
    );
  }
}
