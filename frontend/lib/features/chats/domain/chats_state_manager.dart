import 'dart:collection';

import 'package:hecate/core/base_state_manager.dart';
import 'package:hecate/features/chats/domain/chats_state.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class ChatsStateManager
    implements StateReadable<ChatsState>, AsyncLifecycle {
  Future<void> setLoading();

  Future<void> setIdle({
    required UnmodifiableListView<Chat> chats,
  });

  Future<void> setError({
    required String? consequence,
    required Object? error,
    required StackTrace? stackTrace,
  });
}

final class ChatsStateManagerImpl extends BaseStateManager<ChatsState>
    implements ChatsStateManager {
  ChatsStateManagerImpl()
    : super(
        ChatsState.loading(
          chats: UnmodifiableListView([]),
        ),
      );

  @override
  Future<void> setLoading() async => handle(
    (emit) async => emit(
      ChatsState.loading(
        chats: state.chats,
      ),
    ),
  );

  @override
  Future<void> setIdle({
    required UnmodifiableListView<Chat> chats,
  }) async => handle(
    (emit) async => emit(
      ChatsState.idle(
        chats: chats,
      ),
    ),
  );

  @override
  Future<void> setError({
    required String? consequence,
    required Object? error,
    required StackTrace? stackTrace,
  }) async => handle(
    (emit) async => emit(
      ChatsState.error(
        chats: state.chats,
        consequence: consequence,
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );
}
