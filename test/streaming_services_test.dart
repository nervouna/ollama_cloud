import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_cloud/ollama_cloud.dart';

void main() {
  group('streaming services', () {
    test('chatStream consumes NDJSON chunks and sends bearer token', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');
        expect(request.headers.value(HttpHeaders.authorizationHeader), 'Bearer stream-token');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['stream'], true);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:00Z","message":{"role":"assistant","content":"hello"},"done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:01Z","message":{"role":"assistant","content":" world"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'stream-token',
        ),
      );
      addTearDown(client.close);

      final chunks = await client
          .chatStream(
            const ChatRequest(
              model: 'qwen2.5:7b',
              messages: [ChatMessage(role: 'user', content: 'hi')],
            ),
          )
          .toList();

      expect(chunks, hasLength(2));
      expect(chunks[0].message.content, 'hello');
      expect(chunks[1].done, isTrue);
    });

    test('pullModelStream parses progress updates', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/pull');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['stream'], true);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write('{"status":"pulling manifest","done":false}\n');
        request.response.write('{"status":"success","done":true}\n');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .pullModelStream(const PullModelRequest(model: 'qwen2.5:7b'))
          .toList();

      expect(chunks, hasLength(2));
      expect(chunks[0].status, 'pulling manifest');
      expect(chunks[1].done, isTrue);
    });

    test('pushModelStream parses progress updates', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/push');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['stream'], true);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write('{"status":"pushing layers","done":false}\n');
        request.response.write('{"status":"success","done":true}\n');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .pushModelStream(const PushModelRequest(model: 'qwen2.5:7b'))
          .toList();

      expect(chunks, hasLength(2));
      expect(chunks[0].status, 'pushing layers');
      expect(chunks[1].done, isTrue);
    });

    test('chatStream throws when stream closes before done true', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:00Z","message":{"role":"assistant","content":"partial"},"done":false}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .chatStream(
              const ChatRequest(
                model: 'qwen2.5:7b',
                messages: [ChatMessage(role: 'user', content: 'hi')],
              ),
            )
            .toList(),
        throwsA(isA<OllamaInvalidResponseException>()),
      );
    });

    test('chatStream throws invalid response on malformed JSON chunk', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write('{"message":');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .chatStream(
              const ChatRequest(
                model: 'qwen2.5:7b',
                messages: [ChatMessage(role: 'user', content: 'hi')],
              ),
            )
            .toList(),
        throwsA(isA<OllamaInvalidResponseException>()),
      );
    });

    test('chatStream maps 401 to unauthorized exception', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"invalid token"}');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .chatStream(
              const ChatRequest(
                model: 'qwen2.5:7b',
                messages: [ChatMessage(role: 'user', content: 'hi')],
              ),
            )
            .toList(),
        throwsA(isA<OllamaUnauthorizedException>()),
      );
    });

    test('generateStream consumes NDJSON chunks', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/generate');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['stream'], true);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:00Z","response":"hello","done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:01Z","response":" world","done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .generateStream(
            const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hello'),
          )
          .toList();

      expect(chunks, hasLength(2));
      expect(chunks[0].response, 'hello');
      expect(chunks[1].done, isTrue);
    });

    test('generateStream throws when stream closes before done true', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/generate');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:00Z","response":"partial","done":false}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .generateStream(
              const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
            )
            .toList(),
        throwsA(isA<OllamaInvalidResponseException>()),
      );
    });

    test('generateStream maps 401 to unauthorized exception', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/generate');

        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"invalid token"}');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .generateStream(
              const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
            )
            .toList(),
        throwsA(isA<OllamaUnauthorizedException>()),
      );
    });

    test('chatStream throws invalid response when message is missing', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-19T12:00:00Z","done":false}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .chatStream(
              const ChatRequest(
                model: 'qwen2.5:7b',
                messages: [ChatMessage(role: 'user', content: 'hi')],
              ),
            )
            .toList(),
        throwsA(isA<OllamaInvalidResponseException>()),
      );
    });

    test('pullModelStream maps 500 to server exception', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/pull');

        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"internal error"}');
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      expect(
        () => client
            .pullModelStream(const PullModelRequest(model: 'qwen2.5:7b'))
            .toList(),
        throwsA(isA<OllamaServerException>()),
      );
    });
  });
}
