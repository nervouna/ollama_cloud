import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:ollama_cloud/ollama_cloud.dart';

void main() {
  test('generate returns parsed response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/generate',
      (server) => server.reply(200, {
        'model': 'qwen2.5:7b',
        'created_at': '2026-03-19T12:00:00Z',
        'response': 'hello',
        'done': true,
      }),
      data: {
        'model': 'qwen2.5:7b',
        'prompt': 'hi',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.generate(
      const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
    );

    expect(response.response, 'hello');
    expect(response.done, isTrue);
  });

  test('maps 401 to unauthorized exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/embeddings',
      (server) => server.reply(401, {'error': 'invalid token'}),
      data: {
        'model': 'nomic-embed-text',
        'input': 'hello',
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.embeddings(
        const EmbeddingsRequest(model: 'nomic-embed-text', input: 'hello'),
      ),
      throwsA(isA<OllamaUnauthorizedException>()),
    );
  });

  test('chat maps 500 to server exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/chat',
      (server) => server.reply(500, {'error': 'internal error'}),
      data: {
        'model': 'qwen2.5:7b',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.chat(
        const ChatRequest(
          model: 'qwen2.5:7b',
          messages: [ChatMessage(role: 'user', content: 'hi')],
        ),
      ),
      throwsA(isA<OllamaServerException>()),
    );
  });

  test('generate maps 500 to server exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/generate',
      (server) => server.reply(500, {'error': 'internal error'}),
      data: {
        'model': 'qwen2.5:7b',
        'prompt': 'hello',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.generate(
        const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hello'),
      ),
      throwsA(isA<OllamaServerException>()),
    );
  });

  test('listLocalModels returns parsed tags response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onGet(
      '/api/tags',
      (server) => server.reply(200, {
        'models': [
          {
            'name': 'qwen2.5:7b',
            'model': 'qwen2.5:7b',
            'size': 123,
          },
        ],
      }),
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.listLocalModels();

    expect(response.models, hasLength(1));
    expect(response.models.first.model, 'qwen2.5:7b');
  });

  test('listRunningModels returns parsed tags response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onGet(
      '/api/ps',
      (server) => server.reply(200, {
        'models': [
          {
            'name': 'qwen2.5:7b',
            'model': 'qwen2.5:7b',
            'size': 321,
          },
        ],
      }),
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.listRunningModels();

    expect(response.models, hasLength(1));
    expect(response.models.first.size, 321);
  });

  test('showModel returns parsed model metadata', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/show',
      (server) => server.reply(200, {
        'modelfile': 'FROM qwen2.5:7b',
        'parameters': 'temperature 0.7',
        'template': '{{ .Prompt }}',
        'model_info': {'family': 'qwen'},
      }),
      data: {
        'model': 'qwen2.5:7b',
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.showModel(
      const ShowModelRequest(model: 'qwen2.5:7b'),
    );

    expect(response.modelfile, contains('qwen2.5:7b'));
    expect(response.modelInfo?['family'], 'qwen');
  });

  test('pullModel sends stream false and returns operation status', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/pull',
      (server) => server.reply(200, {'status': 'success', 'done': true}),
      data: {
        'model': 'qwen2.5:7b',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.pullModel(
      const PullModelRequest(model: 'qwen2.5:7b'),
    );

    expect(response.status, 'success');
    expect(response.done, isTrue);
  });

  test('pushModel sends stream false and returns operation status', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/push',
      (server) => server.reply(200, {'status': 'success', 'done': true}),
      data: {
        'model': 'qwen2.5:7b',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.pushModel(
      const PushModelRequest(model: 'qwen2.5:7b'),
    );

    expect(response.status, 'success');
    expect(response.done, isTrue);
  });

  test('pullModel maps 500 to server exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/pull',
      (server) => server.reply(500, {'error': 'internal error'}),
      data: {
        'model': 'qwen2.5:7b',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.pullModel(const PullModelRequest(model: 'qwen2.5:7b')),
      throwsA(isA<OllamaServerException>()),
    );
  });

  test('pushModel maps 500 to server exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/push',
      (server) => server.reply(500, {'error': 'internal error'}),
      data: {
        'model': 'qwen2.5:7b',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.pushModel(const PushModelRequest(model: 'qwen2.5:7b')),
      throwsA(isA<OllamaServerException>()),
    );
  });

  test('showModel maps 401 to unauthorized exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/show',
      (server) => server.reply(401, {'error': 'invalid token'}),
      data: {
        'model': 'qwen2.5:7b',
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.showModel(const ShowModelRequest(model: 'qwen2.5:7b')),
      throwsA(isA<OllamaUnauthorizedException>()),
    );
  });

  test('chat throws invalid response when message field is missing', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/chat',
      (server) => server.reply(200, {
        'model': 'qwen2.5:7b',
        'created_at': '2026-03-19T12:00:00Z',
        'done': true,
      }),
      data: {
        'model': 'qwen2.5:7b',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.chat(
        const ChatRequest(
          model: 'qwen2.5:7b',
          messages: [ChatMessage(role: 'user', content: 'hi')],
        ),
      ),
      throwsA(isA<OllamaInvalidResponseException>()),
    );
  });

  test('deleteModel maps 401 to unauthorized exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onDelete(
      '/api/delete',
      (server) => server.reply(401, {'error': 'invalid token'}),
      data: {
        'model': 'qwen2.5:7b',
      },
    );

    final client = OllamaCloudClient.withDio(dio);

    expect(
      () => client.deleteModel('qwen2.5:7b'),
      throwsA(isA<OllamaUnauthorizedException>()),
    );
  });

  test('chat response parses thinking in message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/chat',
      (server) => server.reply(200, {
        'model': 'qwen2.5:7b',
        'created_at': '2026-03-20T00:00:00Z',
        'message': {
          'role': 'assistant',
          'content': 'the answer is 42',
          'thinking': 'let me calculate...',
        },
        'done': true,
        'done_reason': 'stop',
      }),
      data: {
        'model': 'qwen2.5:7b',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.chat(
      const ChatRequest(
        model: 'qwen2.5:7b',
        messages: [ChatMessage(role: 'user', content: 'hi')],
      ),
    );

    expect(response.message.content, 'the answer is 42');
    expect(response.message.thinking, 'let me calculate...');
    expect(response.doneReason, 'stop');
  });

  test('chat response parses logprobs', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/chat',
      (server) => server.reply(200, {
        'model': 'qwen2.5:7b',
        'created_at': '2026-03-20T00:00:00Z',
        'message': {'role': 'assistant', 'content': 'hi'},
        'done': true,
        'logprobs': [
          {
            'token': 'hi',
            'logprob': -0.4,
            'bytes': [104, 105],
            'top_logprobs': [
              {'token': 'hello', 'logprob': -1.1, 'bytes': [104]},
            ],
          },
        ],
      }),
      data: {
        'model': 'qwen2.5:7b',
        'messages': [
          {'role': 'user', 'content': 'hi'},
        ],
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.chat(
      const ChatRequest(
        model: 'qwen2.5:7b',
        messages: [ChatMessage(role: 'user', content: 'hi')],
      ),
    );

    expect(response.logprobs, isNotNull);
    expect(response.logprobs!, hasLength(1));
    expect(response.logprobs![0].token, 'hi');
    expect(response.logprobs![0].logprob, -0.4);
    expect(response.logprobs![0].topLogprobs, hasLength(1));
    expect(response.logprobs![0].topLogprobs![0].token, 'hello');
  });

  test('generate response parses thinking and logprobs', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    adapter.onPost(
      '/api/generate',
      (server) => server.reply(200, {
        'model': 'qwen2.5:7b',
        'created_at': '2026-03-20T00:00:00Z',
        'response': 'the answer',
        'thinking': 'step by step: ...',
        'done': true,
        'logprobs': [
          {
            'token': 'the',
            'logprob': -0.2,
            'top_logprobs': [
              {'token': 'a', 'logprob': -1.5},
            ],
          },
        ],
      }),
      data: {
        'model': 'qwen2.5:7b',
        'prompt': 'hi',
        'stream': false,
      },
    );

    final client = OllamaCloudClient.withDio(dio);
    final response = await client.generate(
      const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
    );

    expect(response.response, 'the answer');
    expect(response.thinking, 'step by step: ...');
    expect(response.logprobs, isNotNull);
    expect(response.logprobs!, hasLength(1));
    expect(response.logprobs![0].token, 'the');
    expect(response.logprobs![0].logprob, -0.2);
  });
}
