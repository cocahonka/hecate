import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hecate/features/auth/domain/auth_state.dart';
import 'package:hecate/features/auth/domain/auth_state_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AuthObserver implements AsyncLifecycle {}

final class AuthObserverImpl implements AuthObserver {
  final AuthStateManager _authStateManager;
  final Dio _dio;
  final Interceptor _refreshInterceptor;

  StreamSubscription<void>? _authStateSubscription;

  AuthObserverImpl({
    required AuthStateManager authStateManager,
    required Dio dio,
    required Interceptor refreshInterceptor,
  }) : _authStateManager = authStateManager,
       _dio = dio,
       _refreshInterceptor = refreshInterceptor;

  @override
  Future<void> init() async {
    // ignore: unawaited_futures
    _authStateSubscription?.cancel();
    _authStateSubscription = _authStateManager.stream
        .startWith(_authStateManager.state)
        .distinct()
        .listen(
          (state) {
            switch (state) {
              case AuthState$Unauthenticated():
                _dio.interceptors.remove(_refreshInterceptor);
              case AuthState$Authenticated():
                _dio.interceptors.add(_refreshInterceptor);
            }
          },
        );
  }

  @override
  Future<void> dispose() async {
    // ignore: unawaited_futures
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }
}
