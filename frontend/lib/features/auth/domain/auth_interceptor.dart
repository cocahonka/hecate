import 'package:dio/dio.dart';
import 'package:hecate/features/auth/data/repository/auth_repository.dart';
import 'package:hecate/features/auth/domain/auth_state_manager.dart';

abstract interface class AuthInterceptor implements Interceptor {}

final class AuthInterceptorImpl extends Interceptor implements AuthInterceptor {
  final Dio _dio;
  final AuthRepository _repository;
  final AuthStateManager _stateManager;

  static const _retryKey = 'client_auth_retry';

  AuthInterceptorImpl({
    required Dio dio,
    required AuthRepository repository,
    required AuthStateManager stateManager,
  }) : _dio = dio,
       _repository = repository,
       _stateManager = stateManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _repository.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers.putIfAbsent(
        'Authorization',
        () => 'Bearer $token',
      );
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried = requestOptions.extra[_retryKey] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    requestOptions.extra[_retryKey] = true;

    final isRefreshed = await _repository.refreshTokens();
    if (!isRefreshed) {
      await _repository.clearSession();
      final nickname = _stateManager.state.nickname;
      await _stateManager.setUnauthenticated(
        nickname: nickname,
      );
      handler.next(err);
      return;
    }

    final newToken = await _repository.getAccessToken();
    if (newToken != null && newToken.isNotEmpty) {
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
    }

    try {
      final response = await _dio.fetch<Object?>(requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    } on Object {
      handler.next(err);
    }
  }
}
