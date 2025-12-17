import 'package:collection/collection.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:meta/meta.dart';

@immutable
sealed class ChatsState {
  final UnmodifiableListView<Chat> chats;

  ChatsState({
    required this.chats,
  });

  factory ChatsState.loading({
    required UnmodifiableListView<Chat> chats,
  }) = ChatsState$Loading;

  factory ChatsState.idle({
    required UnmodifiableListView<Chat> chats,
  }) = ChatsState$Idle;

  factory ChatsState.error({
    required UnmodifiableListView<Chat> chats,
    required String? consequence,
    required Object? error,
    required StackTrace? stackTrace,
  }) = ChatsState$Error;

  @override
  int get hashCode => Object.hash(
    const ListEquality<Object?>().hash(chats),
    runtimeType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatsState &&
          runtimeType == other.runtimeType &&
          const ListEquality<Object?>().equals(chats, other.chats);
}

final class ChatsState$Loading extends ChatsState {
  ChatsState$Loading({
    required super.chats,
  });
}

final class ChatsState$Idle extends ChatsState {
  ChatsState$Idle({
    required super.chats,
  });
}

final class ChatsState$Error extends ChatsState {
  final String? consequence;
  final Object? error;
  final StackTrace? stackTrace;

  ChatsState$Error({
    required super.chats,
    required this.consequence,
    required this.error,
    required this.stackTrace,
  });

  @override
  int get hashCode => Object.hash(
    const ListEquality<Object?>().hash(chats),
    consequence,
    error,
    stackTrace,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatsState$Error &&
          runtimeType == other.runtimeType &&
          const ListEquality<Object?>().equals(chats, other.chats) &&
          consequence == other.consequence &&
          error == other.error &&
          stackTrace == other.stackTrace;
}
