import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../errors/ollama_exception.dart';

/// Parses an NDJSON byte stream into JSON object chunks.
///
/// Empty lines are ignored. Each non-empty line must decode to a JSON object.
/// Throws [OllamaInvalidResponseException] when a line contains invalid JSON
/// or when decoded content is not a JSON object.
Stream<Map<String, dynamic>> parseNdjson(Stream<Uint8List> bytes) async* {
  final lines = utf8.decoder.bind(bytes).transform(const LineSplitter());

  await for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (error) {
      throw OllamaInvalidResponseException(
        'Invalid JSON fragment in stream payload.',
        details: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw OllamaInvalidResponseException(
        'Expected an object in stream payload.',
        details: decoded,
      );
    }

    yield decoded;
  }
}
