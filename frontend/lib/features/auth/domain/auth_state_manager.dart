import 'package:hecate/core/base_state_manager.dart';
import 'package:hecate/features/auth/domain/auth_state.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class AuthStateManager
    implements StateReadable<AuthState>, AsyncLifecycle {
  Future<void> setUnauthenticated({
    String? nickname,
  });

  Future<void> setAuthenticated({
    required String nickname,
  });
}

final class AuthStateManagerImpl extends BaseStateManager<AuthState>
    implements AuthStateManager {
  AuthStateManagerImpl() : super(AuthState.unauthenticated());

  @override
  Future<void> setUnauthenticated({
    String? nickname,
  }) async => handle(
    (emit) async => emit(
      AuthState.unauthenticated(
        nickname: nickname,
      ),
    ),
  );

  @override
  Future<void> setAuthenticated({
    required String nickname,
  }) async => handle(
    (emit) async => emit(
      AuthState.authenticated(
        nickname: nickname,
      ),
    ),
  );
}
