import 'package:hecate/core/base_state_manager.dart';
import 'package:hecate/features/bindings/domain/bindings_state.dart';
import 'package:piv_bindings/piv_bindings.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class BindingsStateManager
    implements StateReadable<BindingsState>, AsyncLifecycle {
  Future<void> setOpening();

  Future<void> setOpened({
    required BindingsHandle handle,
  });

  Future<void> setOpeningError({
    required Object? error,
    required StackTrace? stackTrace,
  });

  Future<void> setOpeningFailed({
    required PivBindingsStatus status,
  });

  Future<void> setClosed();

  Future<void> setCallError({
    required BindingsHandle handle,
    required Object? error,
    required StackTrace? stackTrace,
  });

  Future<void> setCallFailed({
    required BindingsHandle handle,
    required PivBindingsStatus status,
  });

  Future<void> setInconsistentState({
    required BindingsHandle handle,
    required BindingsInconsistentType type,
  });
}

final class BindingsStateManagerImpl extends BaseStateManager<BindingsState>
    implements BindingsStateManager {
  BindingsStateManagerImpl() : super(BindingsState.closed());

  @override
  Future<void> setOpening() async => handle(
    (emit) async => emit(
      BindingsState.opening(),
    ),
  );

  @override
  Future<void> setOpened({
    required BindingsHandle handle,
  }) async => super.handle(
    (emit) async => emit(
      BindingsState.opened(
        handle: handle,
      ),
    ),
  );

  @override
  Future<void> setOpeningFailed({
    required PivBindingsStatus status,
  }) async => handle(
    (emit) async => emit(
      BindingsState.openingFailed(
        status: status,
      ),
    ),
  );

  @override
  Future<void> setOpeningError({
    required Object? error,
    required StackTrace? stackTrace,
  }) async => super.handle(
    (emit) async => emit(
      BindingsState.openingError(
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );

  @override
  Future<void> setClosed() async => handle(
    (emit) async => emit(
      BindingsState.closed(),
    ),
  );

  @override
  Future<void> setCallFailed({
    required BindingsHandle handle,
    required PivBindingsStatus status,
  }) async => super.handle(
    (emit) async => emit(
      BindingsState.callFailed(
        handle: handle,
        status: status,
      ),
    ),
  );

  @override
  Future<void> setCallError({
    required BindingsHandle handle,
    required Object? error,
    required StackTrace? stackTrace,
  }) async => super.handle(
    (emit) async => emit(
      BindingsState.callError(
        handle: handle,
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );

  @override
  Future<void> setInconsistentState({
    required BindingsHandle handle,
    required BindingsInconsistentType type,
  }) async => super.handle(
    (emit) async => emit(
      BindingsState.inconsistentState(
        handle: handle,
        type: type,
      ),
    ),
  );
}
