/// Request payload for the embeddings endpoint.
class EmbeddingsRequest {
  /// Creates an embeddings request.
  const EmbeddingsRequest({
    required this.model,
    required this.input,
    this.truncate,
    this.options,
    this.keepAlive,
  });

  /// Model name used to compute embeddings.
  final String model;

  /// Input value accepted by the embeddings API.
  ///
  /// This is typically a single string or a list of strings.
  final Object input;

  /// Whether to truncate input that exceeds model limits.
  final bool? truncate;

  /// Optional model runtime options.
  final Map<String, dynamic>? options;

  /// Optional keep-alive policy for model residency.
  final Object? keepAlive;

  /// Serializes this request to API JSON format.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'input': input,
      if (truncate != null) 'truncate': truncate,
      if (options != null) 'options': options,
      if (keepAlive != null) 'keep_alive': keepAlive,
    };
  }
}

/// Response payload for the embeddings endpoint.
class EmbeddingsResponse {
  /// Creates an embeddings response.
  const EmbeddingsResponse({
    required this.model,
    this.embedding,
    this.embeddings,
  });

  /// Model that generated the vectors.
  final String model;

  /// Single embedding vector for one input.
  final List<double>? embedding;

  /// Multiple embedding vectors for batched inputs.
  final List<List<double>>? embeddings;

  /// Creates a response from API JSON payload.
  factory EmbeddingsResponse.fromJson(Map<String, dynamic> json) {
    return EmbeddingsResponse(
      model: (json['model'] ?? '') as String,
      embedding: _toDoubleList(json['embedding']),
      embeddings: _toDoubleMatrix(json['embeddings']),
    );
  }

  static List<double>? _toDoubleList(Object? value) {
    if (value is! List) {
      return null;
    }
    return value.map((item) => (item as num).toDouble()).toList();
  }

  static List<List<double>>? _toDoubleMatrix(Object? value) {
    if (value is! List) {
      return null;
    }
    return value
        .map((item) => (item as List).map((v) => (v as num).toDouble()).toList())
        .toList();
  }
}
