import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_cloud/src/errors/ollama_exception.dart';
import 'package:ollama_cloud/src/transport/ndjson_stream_parser.dart';

void main() {
  test('parseNdjson decodes line-delimited JSON objects', () async {
    const payload = '{"response":"a"}\n{"response":"b","done":true}\n';
    final bytes = Stream<Uint8List>.fromIterable([
      Uint8List.fromList(utf8.encode(payload)),
    ]);

    final chunks = await parseNdjson(bytes).toList();

    expect(chunks, hasLength(2));
    expect(chunks.first['response'], 'a');
    expect(chunks.last['done'], true);
  });

  test('parseNdjson throws invalid response for non-object JSON', () async {
    const payload = '"oops"\n';
    final bytes = Stream<Uint8List>.fromIterable([
      Uint8List.fromList(utf8.encode(payload)),
    ]);

    expect(
      () => parseNdjson(bytes).drain<void>(),
      throwsA(isA<OllamaInvalidResponseException>()),
    );
  });

  test('parseNdjson returns empty list for empty stream', () async {
    final bytes = Stream<Uint8List>.empty();
    final chunks = await parseNdjson(bytes).toList();
    expect(chunks, isEmpty);
  });

  test('parseNdjson ignores empty lines', () async {
    const payload = '\n  \n{"response":"a"}\n\n';
    final bytes = Stream<Uint8List>.fromIterable([
      Uint8List.fromList(utf8.encode(payload)),
    ]);

    final chunks = await parseNdjson(bytes).toList();

    expect(chunks, hasLength(1));
    expect(chunks.first['response'], 'a');
  });

  test('parseNdjson handles fragmented byte chunks', () async {
    final bytes = Stream<Uint8List>.fromIterable([
      Uint8List.fromList(utf8.encode('{"response":')),
      Uint8List.fromList(utf8.encode('"a"}\n{"response":"b"')),
      Uint8List.fromList(utf8.encode(',"done":true}\n')),
    ]);

    final chunks = await parseNdjson(bytes).toList();

    expect(chunks, hasLength(2));
    expect(chunks.first['response'], 'a');
    expect(chunks.last['done'], true);
  });
}
