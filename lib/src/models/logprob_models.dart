/// A single candidate token and its log-probability.
class TopLogprob {
  /// Creates a top-logprob entry.
  const TopLogprob({
    required this.token,
    required this.logprob,
    this.bytes,
  });

  /// The candidate token string.
  final String token;

  /// Log-probability of this candidate token.
  final double logprob;

  /// Optional UTF-8 byte values of the token.
  final List<int>? bytes;

  /// Creates a top-logprob entry from API JSON payload.
  factory TopLogprob.fromJson(Map<String, dynamic> json) {
    return TopLogprob(
      token: (json['token'] ?? '') as String,
      logprob: (json['logprob'] as num).toDouble(),
      bytes: (json['bytes'] as List<dynamic>?)?.cast<int>(),
    );
  }
}

/// Log-probability information for a single generated token.
class LogprobItem {
  /// Creates a logprob item.
  const LogprobItem({
    required this.token,
    required this.logprob,
    this.bytes,
    this.topLogprobs,
  });

  /// The generated token string.
  final String token;

  /// Log-probability of the generated token.
  final double logprob;

  /// Optional UTF-8 byte values of the token.
  final List<int>? bytes;

  /// Optional list of top candidate tokens and their log-probabilities.
  final List<TopLogprob>? topLogprobs;

  /// Creates a logprob item from API JSON payload.
  factory LogprobItem.fromJson(Map<String, dynamic> json) {
    return LogprobItem(
      token: (json['token'] ?? '') as String,
      logprob: (json['logprob'] as num).toDouble(),
      bytes: (json['bytes'] as List<dynamic>?)?.cast<int>(),
      topLogprobs: (json['top_logprobs'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(TopLogprob.fromJson)
          .toList(),
    );
  }
}
