/// Base exception type for all client and API failures.
class OllamaException implements Exception {
  /// Creates a typed Ollama exception.
  const OllamaException(this.message, {this.statusCode, this.details});

  /// Human-readable error description.
  final String message;

  /// Optional HTTP status code returned by the server.
  final int? statusCode;

  /// Optional raw error details from transport or response payload.
  final Object? details;

  @override
  String toString() {
    final codePart = statusCode == null ? '' : ' (status: $statusCode)';
    return 'OllamaException$codePart: $message';
  }
}

/// Thrown when the request fails due to network connectivity issues.
class OllamaNetworkException extends OllamaException {
  const OllamaNetworkException(super.message, {super.details});
}

/// Thrown when the request times out.
class OllamaTimeoutException extends OllamaException {
  const OllamaTimeoutException(super.message, {super.details});
}

/// Thrown when the server rejects authentication credentials.
class OllamaUnauthorizedException extends OllamaException {
  const OllamaUnauthorizedException(super.message, {super.details})
      : super(statusCode: 401);
}

/// Thrown when the server returns malformed or unexpected payload content.
class OllamaInvalidResponseException extends OllamaException {
  const OllamaInvalidResponseException(super.message, {super.details});
}

/// Thrown when the server reports an HTTP 5xx failure.
class OllamaServerException extends OllamaException {
  const OllamaServerException(
    super.message, {
    super.statusCode,
    super.details,
  });
}
