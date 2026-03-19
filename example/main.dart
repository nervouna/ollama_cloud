// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:ollama_cloud/ollama_cloud.dart';

/// Multimodal example for the ollama_cloud package.
///
/// Before running, copy `example/.env.example` to `example/.env` and fill in
/// your real values, then execute from the project root:
///
///   dart run example/main.dart
///
Future<void> main() async {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final env = DotEnv()..load(['$scriptDir/.env']);

  final baseUrl = env['OLLAMA_BASE_URL'];
  final apiKey = env['OLLAMA_API_KEY'];
  final model = env['OLLAMA_MODEL'] ?? 'qwen3.5:397b-cloud';
  final imagePath = _resolveOptionalPath(scriptDir, env['OLLAMA_IMAGE_PATH']);
  final videoPath = _resolveOptionalPath(scriptDir, env['OLLAMA_VIDEO_PATH']);

  if (baseUrl == null || baseUrl.isEmpty) {
    stderr.writeln(
      'Error: OLLAMA_BASE_URL is not set.\n'
      'Copy example/.env.example → example/.env and fill in your values.',
    );
    exit(1);
  }

  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln(
      'Error: OLLAMA_API_KEY is not set.\n'
      'Copy example/.env.example → example/.env and fill in your values.',
    );
    exit(1);
  }

  final client = OllamaCloudClient(
    config: OllamaClientConfig(
      baseUrl: baseUrl,
      apiKey: apiKey,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  print('Using model: $model');
  print('Endpoint:    $baseUrl\n');

  await _runGeneralChat(client, model);
  await _runImageAnalysis(client, model, imagePath);
  await _runVideoAnalysis(client, model, videoPath);
}

Future<void> _runGeneralChat(OllamaCloudClient client, String model) async {
  await _runChatDemo(
    title: 'General Chat',
    client: client,
    request: ChatRequest(
      model: model,
      messages: const [
        ChatMessage(role: 'system', content: 'You are a concise assistant.'),
        ChatMessage(
          role: 'user',
          content: '请用中文简要介绍一下什么是 AI Agent，并给出 3 个典型应用场景。',
        ),
      ],
    ),
  );
}

Future<void> _runImageAnalysis(
  OllamaCloudClient client,
  String model,
  String? imagePath,
) async {
  _header('Image Analysis');

  if (imagePath == null) {
    _printSkip('Set OLLAMA_IMAGE_PATH in example/.env to run this demo.');
    return;
  }

  try {
    final image = await _readFileAsBase64(imagePath);
    final response = await _sendChatRequest(
      client,
      ChatRequest(
        model: model,
        messages: [
          const ChatMessage(
            role: 'system',
            content: 'You are a visual assistant. Focus on concrete details.',
          ),
          ChatMessage(
            role: 'user',
            content: '请解析这张图片，输出主体、场景、关键细节，以及你不确定的部分。',
            images: [image],
          ),
        ],
      ),
      label: 'image-analysis',
    );

    if (response != null) {
      print('Image file: $imagePath\n');
      print(response.message.content);
    }
  } on FileSystemException catch (e) {
    stderr.writeln('[image-analysis] Failed to read image: ${e.message}');
  }
}

Future<void> _runVideoAnalysis(
  OllamaCloudClient client,
  String model,
  String? videoPath,
) async {
  _header('Video Analysis');

  if (videoPath == null) {
    _printSkip('Set OLLAMA_VIDEO_PATH in example/.env to run this demo.');
    return;
  }

  try {
    final frames = await _extractVideoFramesAsBase64(videoPath);
    if (frames.isEmpty) {
      _printSkip('No frames were extracted from the video.');
      return;
    }

    final response = await _sendChatRequest(
      client,
      ChatRequest(
        model: model,
        messages: [
          const ChatMessage(
            role: 'system',
            content: 'You are a visual assistant. The images are video keyframes ordered by time.',
          ),
          ChatMessage(
            role: 'user',
            content:
                '这些图片是按时间顺序从同一段视频中抽取的关键帧。请概括视频内容、主体动作、场景变化，并指出你的判断依据。',
            images: frames,
          ),
        ],
      ),
      label: 'video-analysis',
    );

    if (response != null) {
      print('Video file: $videoPath');
      print('Frames sent: ${frames.length}\n');
      print(response.message.content);
    }
  } on FileSystemException catch (e) {
    stderr.writeln('[video-analysis] Failed to access video: ${e.message}');
  } on ProcessException catch (e) {
    stderr.writeln('[video-analysis] ffmpeg error: ${e.message}');
  } on StateError catch (e) {
    stderr.writeln('[video-analysis] ${e.message}');
  }
}

Future<void> _runChatDemo({
  required String title,
  required OllamaCloudClient client,
  required ChatRequest request,
}) async {
  _header(title);
  final response = await _sendChatRequest(client, request, label: title);
  if (response != null) {
    print(response.message.content);
  }
}

Future<ChatResponse?> _sendChatRequest(
  OllamaCloudClient client,
  ChatRequest request, {
  required String label,
}) async {
  try {
    return await client.chat(request);
  } on OllamaUnauthorizedException {
    stderr.writeln('[$label] Unauthorized – check OLLAMA_API_KEY.');
  } on OllamaTimeoutException catch (e) {
    stderr.writeln('[$label] Timeout: ${e.message}');
  } on OllamaNetworkException catch (e) {
    stderr.writeln('[$label] Network error: ${e.message}');
  } on OllamaServerException catch (e) {
    stderr.writeln('[$label] Server error (${e.statusCode}): ${e.message}');
  } on OllamaException catch (e) {
    stderr.writeln('[$label] Unexpected error: $e');
  }

  return null;
}

Future<String> _readFileAsBase64(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  return base64Encode(bytes);
}

Future<List<String>> _extractVideoFramesAsBase64(
  String videoPath, {
  int maxFrames = 6,
}) async {
  final ffmpegCheck = await Process.run('ffmpeg', const ['-version']);
  if (ffmpegCheck.exitCode != 0) {
    throw StateError(
      'ffmpeg is required for video analysis. Install it first, for example with: brew install ffmpeg',
    );
  }

  final tempDir = await Directory.systemTemp.createTemp(
    'ollama_cloud_video_frames_',
  );

  try {
    final outputPattern = '${tempDir.path}${Platform.pathSeparator}frame_%03d.jpg';
    final result = await Process.run(
      'ffmpeg',
      [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        videoPath,
        '-vf',
        'fps=1',
        '-frames:v',
        '$maxFrames',
        outputPattern,
      ],
    );

    if (result.exitCode != 0) {
      throw StateError(
        'ffmpeg failed to extract frames: ${result.stderr}'.trim(),
      );
    }

    final frameFiles = await tempDir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    final frames = <String>[];
    for (final frameFile in frameFiles) {
      frames.add(await _readFileAsBase64(frameFile.path));
    }
    return frames;
  } finally {
    await tempDir.delete(recursive: true);
  }
}

String? _resolveOptionalPath(String scriptDir, String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) {
    return null;
  }

  final trimmed = rawPath.trim();
  if (File(trimmed).isAbsolute) {
    return trimmed;
  }

  return '$scriptDir${Platform.pathSeparator}$trimmed';
}

void _printSkip(String message) {
  print('Skipped: $message');
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

void _header(String title) {
  print('\n${'─' * 50}');
  print('  $title');
  print('─' * 50);
}
