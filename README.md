# ollama_cloud

A Flutter SDK for calling Ollama cloud APIs with a consistent model layer,
error mapping, and both stream/non-stream support.

## Features

- `generate` and `generateStream` for text generation
- `chat` and `chatStream` for multi-turn messages
- `embeddings` for vector embedding generation
- model management APIs (`tags`, `ps`, `show`, `pull`, `push`, `delete`)
- unified Bearer token authentication
- typed exceptions for network/timeout/server/unauthorized errors
- `thinking` field for chain-of-thought reasoning (models that support it)
- `tool_calls` field with typed `ToolCall` / `ToolCallFunction` models
- `logprobs` field with typed `LogprobItem` / `TopLogprob` models

## Getting Started

Add dependency:

```yaml
dependencies:
	ollama_cloud: ^0.0.2
```

Create a client:

```dart
import 'package:ollama_cloud/ollama_cloud.dart';

final client = OllamaCloudClient(
	config: OllamaClientConfig(
		baseUrl: 'https://your-ollama-cloud-endpoint',
		apiKey: 'your-token',
	),
);
```

## Usage

### 1) Generate (non-stream)

```dart
final result = await client.generate(
	const GenerateRequest(
		model: 'qwen2.5:7b',
		prompt: 'Explain RAG in one paragraph.',
	),
);

print(result.response);
```

### 2) Generate (stream)

```dart
await for (final chunk in client.generateStream(
	const GenerateRequest(
		model: 'qwen2.5:7b',
		prompt: 'Write a short release note.',
	),
)) {
	if (chunk.response.isNotEmpty) {
		print(chunk.response);
	}
}
```

### 3) Chat

```dart
final chat = await client.chat(
	const ChatRequest(
		model: 'qwen2.5:7b',
		messages: [
			ChatMessage(role: 'system', content: 'You are a concise assistant.'),
			ChatMessage(role: 'user', content: 'Give me 3 CI tips.'),
		],
	),
);

print(chat.message.content);

// For thinking models, the reasoning process is available separately:
if (chat.message.thinking != null) {
	print('Thinking: ${chat.message.thinking}');
}
```

### 3b) Chat (stream) with thinking

```dart
await for (final chunk in client.chatStream(
	const ChatRequest(
		model: 'qwen2.5:7b',
		messages: [ChatMessage(role: 'user', content: 'Solve step by step: 2+2')],
	),
)) {
	if (chunk.message.thinking?.isNotEmpty ?? false) {
		stdout.write('[thinking] ${chunk.message.thinking}');
	} else if (chunk.message.content.isNotEmpty) {
		stdout.write(chunk.message.content);
	}
}
```

### 4) Embeddings

```dart
final emb = await client.embeddings(
	const EmbeddingsRequest(
		model: 'nomic-embed-text',
		input: 'semantic search example',
	),
);

print(emb.embedding?.length ?? 0);
```

### 5) Model Management

```dart
final local = await client.listLocalModels();
final running = await client.listRunningModels();

await client.pullModel(
	const PullModelRequest(model: 'qwen2.5:7b'),
);

await client.deleteModel('old-model:latest');
```

## Error Handling

The SDK throws typed exceptions:

- `OllamaUnauthorizedException`
- `OllamaTimeoutException`
- `OllamaNetworkException`
- `OllamaServerException`
- `OllamaInvalidResponseException`

Example:

```dart
try {
	await client.generate(
		const GenerateRequest(model: 'qwen2.5:7b', prompt: 'hi'),
	);
} on OllamaUnauthorizedException {
	// refresh token or re-login
} on OllamaException catch (e) {
	print(e);
}
```

## Notes for Flutter Web

- If your endpoint blocks browser cross-origin requests, add a backend proxy.
- Some environments may not support long-lived stream responses reliably;
	fallback to non-stream calls if needed.

## Run the Full Example

The `example/` directory contains a runnable Dart program that demonstrates
three multimodal workflows with full exception handling:

- general chat
- image analysis from a local file
- video analysis by sampling local video keyframes and sending them as images

### Prerequisites

- Dart SDK available in your environment.
- `ffmpeg` installed if you want to run the video analysis demo.

```bash
brew install ffmpeg
```

**1. Copy the environment template**

```bash
cp example/.env.example example/.env
```

**2. Fill in your values** in `example/.env`

```dotenv
OLLAMA_BASE_URL=https://your-ollama-cloud-endpoint
OLLAMA_API_KEY=your-api-key-here
OLLAMA_MODEL=qwen3.5:397b-cloud     # optional, example default model
OLLAMA_IMAGE_PATH=assets/demo-image.jpg
OLLAMA_VIDEO_PATH=assets/demo-video.mp4
```

The API snippets above use `qwen2.5:7b` as a lightweight text example model.
The full example uses `qwen3.5:397b-cloud` by default for multimodal demos.

`example/.env` is listed in `.gitignore` and will never be committed.

If `OLLAMA_IMAGE_PATH` or `OLLAMA_VIDEO_PATH` is omitted, the corresponding demo
is skipped. Relative paths are resolved from the `example/` directory.

**3. Install dependencies**

```bash
dart pub get
```

**4. Run from the project root**

```bash
dart run example/main.dart
```

## Contributing

- Contribution guide: `CONTRIBUTING.md`
- Release process: `RELEASING.md`

## License

This project is licensed under the WTFPL, Version 2.

See `LICENSE` for the full text.
