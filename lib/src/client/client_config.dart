/// Configuration used to create an [OllamaCloudClient].
class OllamaClientConfig {
  /// Creates a client configuration.
  ///
  /// [baseUrl] is the API endpoint root, for example `https://host/v1`.
  OllamaClientConfig({
    required this.baseUrl,
    this.apiKey,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(minutes: 5),
    this.headers = const {},
  }) : assert(baseUrl != '', 'baseUrl must not be empty.'),
       assert(
         baseUrl.startsWith('http://') || baseUrl.startsWith('https://'),
         'baseUrl must start with http:// or https://',
       ),
       assert(
         apiKey == null || apiKey.trim().isNotEmpty,
         'apiKey must not be blank when provided.',
       );

  /// Base URL for all Ollama API requests.
  final String baseUrl;

  /// Optional bearer token or API key used for authenticated requests.
  final String? apiKey;

  /// Maximum time allowed to establish a TCP/HTTP connection.
  final Duration connectTimeout;

  /// Maximum time allowed while sending request bytes.
  final Duration sendTimeout;

  /// Maximum time allowed while waiting to receive response bytes.
  final Duration receiveTimeout;

  /// Additional headers merged into every outgoing request.
  final Map<String, String> headers;
}
