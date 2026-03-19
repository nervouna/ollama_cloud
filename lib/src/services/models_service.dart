import 'package:dio/dio.dart';

import '../models/model_management_models.dart';
import 'base_service.dart';

/// Service wrapper for model management endpoints.
class ModelsService extends BaseService {
  /// Creates a model management service.
  ModelsService(super.dio);

  /// Lists locally available models.
  Future<TagsResponse> listLocalModels() async {
    try {
      final response = await dio.get<dynamic>('/api/tags');
      ensureSuccess(response);
      return TagsResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Lists models currently loaded and running.
  Future<TagsResponse> listRunningModels() async {
    try {
      final response = await dio.get<dynamic>('/api/ps');
      ensureSuccess(response);
      return TagsResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Retrieves metadata for a specific model.
  Future<ShowModelResponse> showModel(ShowModelRequest request) async {
    try {
      final response = await dio.post<dynamic>('/api/show', data: request.toJson());
      ensureSuccess(response);
      return ShowModelResponse.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Deletes a model by name.
  Future<void> deleteModel(String model) async {
    try {
      final response = await dio.delete<dynamic>(
        '/api/delete',
        data: {'model': model},
      );
      ensureSuccess(response);
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Pulls a model and returns the final operation status.
  Future<ModelOperationStatus> pullModel(PullModelRequest request) async {
    final payload = request.toJson()..['stream'] = false;

    try {
      final response = await dio.post<dynamic>('/api/pull', data: payload);
      ensureSuccess(response);
      return ModelOperationStatus.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Pulls a model and emits incremental progress updates.
  Stream<ModelOperationStatus> pullModelStream(PullModelRequest request) async* {
    final payload = request.toJson()..['stream'] = true;

    Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/api/pull',
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );
      ensureSuccess(response);
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }

    final chunks = parseResponseStream(response).map(ModelOperationStatus.fromJson);
    yield* requireDoneStream(
      chunks,
      isDone: (chunk) => chunk.done == true,
      endpoint: '/api/pull',
    );
  }

  /// Pushes a model and returns the final operation status.
  Future<ModelOperationStatus> pushModel(PushModelRequest request) async {
    final payload = request.toJson()..['stream'] = false;

    try {
      final response = await dio.post<dynamic>('/api/push', data: payload);
      ensureSuccess(response);
      return ModelOperationStatus.fromJson(ensureJsonMap(response.data));
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }
  }

  /// Pushes a model and emits incremental progress updates.
  Stream<ModelOperationStatus> pushModelStream(PushModelRequest request) async* {
    final payload = request.toJson()..['stream'] = true;

    Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/api/push',
        data: payload,
        options: Options(responseType: ResponseType.stream),
      );
      ensureSuccess(response);
    } on DioException catch (error) {
      throw errorMapper.mapDioException(error);
    }

    final chunks = parseResponseStream(response).map(ModelOperationStatus.fromJson);
    yield* requireDoneStream(
      chunks,
      isDone: (chunk) => chunk.done == true,
      endpoint: '/api/push',
    );
  }
}
