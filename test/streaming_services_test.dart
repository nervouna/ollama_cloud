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

    test('chatStream maps 500 to server exception', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

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
            .chatStream(
              const ChatRequest(
                model: 'qwen2.5:7b',
                messages: [ChatMessage(role: 'user', content: 'hi')],
              ),
            )
            .toList(),
        throwsA(isA<OllamaServerException>()),
      );
    });

    test('chatStream sends no Authorization header when API key is absent',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');
        expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"hi"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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

      expect(chunks, hasLength(1));
    });

    test('chatStream emits doneReason on terminal chunk', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"answer"},"done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:01Z","message":{"role":"assistant","content":""},"done":true,"done_reason":"stop"}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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
      expect(chunks.last.done, isTrue);
      expect(chunks.last.doneReason, 'stop');
    });

    test('chatStream handles multiple intermediate chunks', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        for (var i = 1; i <= 4; i++) {
          request.response.write(
            '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:0${i}Z","message":{"role":"assistant","content":"token$i"},"done":false}\n',
          );
        }
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:05Z","message":{"role":"assistant","content":""},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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

      expect(chunks, hasLength(5));
      expect(chunks[0].message.content, 'token1');
      expect(chunks[3].message.content, 'token4');
      expect(chunks[4].done, isTrue);
    });

    test('chatStream passes multi-turn conversation messages', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        final messages = decoded['messages'] as List<dynamic>;
        expect(messages, hasLength(4));
        expect((messages[0] as Map<String, dynamic>)['role'], 'system');
        expect((messages[1] as Map<String, dynamic>)['role'], 'user');
        expect((messages[2] as Map<String, dynamic>)['role'], 'assistant');
        expect((messages[3] as Map<String, dynamic>)['role'], 'user');
        expect(
          (messages[3] as Map<String, dynamic>)['content'],
          'follow-up question',
        );

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"ok"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .chatStream(
            const ChatRequest(
              model: 'qwen2.5:7b',
              messages: [
                ChatMessage(role: 'system', content: 'You are helpful.'),
                ChatMessage(role: 'user', content: 'Hello'),
                ChatMessage(role: 'assistant', content: 'Hi there!'),
                ChatMessage(role: 'user', content: 'follow-up question'),
              ],
            ),
          )
          .toList();

      expect(chunks, hasLength(1));
    });

    test('chatStream includes options and format in request payload', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['format'], 'json');
        final options = decoded['options'] as Map<String, dynamic>;
        expect(options['temperature'], 0.7);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"{}"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .chatStream(
            const ChatRequest(
              model: 'qwen2.5:7b',
              messages: [ChatMessage(role: 'user', content: 'hi')],
              format: 'json',
              options: {'temperature': 0.7},
            ),
          )
          .toList();

      expect(chunks, hasLength(1));
    });

    test('chatStream includes keepAlive in request payload', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        expect(decoded['keep_alive'], '5m');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"hi"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .chatStream(
            const ChatRequest(
              model: 'qwen2.5:7b',
              messages: [ChatMessage(role: 'user', content: 'hi')],
              keepAlive: '5m',
            ),
          )
          .toList();

      expect(chunks, hasLength(1));
    });

    test('chatStream passes images in multimodal messages', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        final requestBody = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(requestBody) as Map<String, dynamic>;
        final messages = decoded['messages'] as List<dynamic>;
        final firstMsg = messages[0] as Map<String, dynamic>;
        expect(firstMsg['images'], ['base64imagedata']);

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"llava:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"I see a cat"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .chatStream(
            const ChatRequest(
              model: 'llava:7b',
              messages: [
                ChatMessage(
                  role: 'user',
                  content: 'What is in this image?',
                  images: ['base64imagedata'],
                ),
              ],
            ),
          )
          .toList();

      expect(chunks, hasLength(1));
      expect(chunks.first.message.content, 'I see a cat');
    });

    test('chatStream parses thinking field in message', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"","thinking":"let me think..."},"done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:01Z","message":{"role":"assistant","content":"answer"},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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
      expect(chunks[0].message.thinking, 'let me think...');
      expect(chunks[1].message.content, 'answer');
    });

    test('chatStream parses tool_calls in message', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"","tool_calls":[{"function":{"name":"get_weather","arguments":{"city":"Beijing"}}}]},"done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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

      expect(chunks, hasLength(1));
      final toolCalls = chunks[0].message.toolCalls;
      expect(toolCalls, isNotNull);
      expect(toolCalls!, hasLength(1));
      expect(toolCalls[0].function.name, 'get_weather');
      expect(toolCalls[0].function.arguments?['city'], 'Beijing');
    });

    test('chatStream parses stats and logprobs in terminal chunk', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/chat');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","message":{"role":"assistant","content":"hi"},"done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:01Z","message":{"role":"assistant","content":""},"done":true,"done_reason":"stop","total_duration":1000000,"load_duration":200000,"prompt_eval_count":5,"prompt_eval_duration":300000,"eval_count":3,"eval_duration":500000,"logprobs":[{"token":"hi","logprob":-0.5,"bytes":[104,105],"top_logprobs":[{"token":"hello","logprob":-1.2,"bytes":[104,101,108,108,111]}]}]}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
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
      final terminal = chunks[1];
      expect(terminal.done, isTrue);
      expect(terminal.totalDuration, 1000000);
      expect(terminal.loadDuration, 200000);
      expect(terminal.promptEvalCount, 5);
      expect(terminal.evalCount, 3);
      expect(terminal.logprobs, isNotNull);
      expect(terminal.logprobs!, hasLength(1));
      expect(terminal.logprobs![0].token, 'hi');
      expect(terminal.logprobs![0].logprob, -0.5);
      expect(terminal.logprobs![0].topLogprobs, hasLength(1));
      expect(terminal.logprobs![0].topLogprobs![0].token, 'hello');
    });

    test('generateStream parses thinking field', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/generate');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","response":"","thinking":"reasoning step","done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:01Z","response":"answer","done":true}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .generateStream(
            const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
          )
          .toList();

      expect(chunks, hasLength(2));
      expect(chunks[0].thinking, 'reasoning step');
      expect(chunks[1].response, 'answer');
    });

    test('generateStream parses logprobs in terminal chunk', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/api/generate');

        request.response.headers.contentType =
            ContentType('application', 'x-ndjson', charset: 'utf-8');
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:00Z","response":"ok","done":false}\n',
        );
        request.response.write(
          '{"model":"qwen2.5:7b","created_at":"2026-03-20T00:00:01Z","response":"","done":true,"total_duration":800000,"eval_count":2,"logprobs":[{"token":"ok","logprob":-0.3,"top_logprobs":[{"token":"yes","logprob":-0.9}]}]}\n',
        );
        await request.response.close();
      }());

      final client = OllamaCloudClient(
        config: OllamaClientConfig(baseUrl: 'http://127.0.0.1:${server.port}'),
      );
      addTearDown(client.close);

      final chunks = await client
          .generateStream(
            const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
          )
          .toList();

      expect(chunks, hasLength(2));
      final terminal = chunks[1];
      expect(terminal.done, isTrue);
      expect(terminal.totalDuration, 800000);
      expect(terminal.evalCount, 2);
      expect(terminal.logprobs, isNotNull);
      expect(terminal.logprobs!, hasLength(1));
      expect(terminal.logprobs![0].token, 'ok');
      expect(terminal.logprobs![0].logprob, -0.3);
    });
  });
}
