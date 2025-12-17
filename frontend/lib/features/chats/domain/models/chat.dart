import 'package:collection/collection.dart';
import 'package:hecate/features/chats/domain/models/message.dart';
import 'package:meta/meta.dart';

@immutable
final class Chat {
  final String id;
  final String participantId;
  final String participantNickname;
  final String encryptedKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UnmodifiableListView<Message> messages;

  Chat({
    required this.id,
    required this.participantId,
    required this.participantNickname,
    required this.encryptedKey,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? participantId,
    String? participantNickname,
    String? encryptedKey,
    UnmodifiableListView<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chat(
    id: id ?? this.id,
    participantId: participantId ?? this.participantId,
    participantNickname: participantNickname ?? this.participantNickname,
    encryptedKey: encryptedKey ?? this.encryptedKey,
    messages: messages ?? this.messages,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  int get hashCode => Object.hash(
    id,
    participantId,
    participantNickname,
    encryptedKey,
    const ListEquality<Message>().hash(messages),
    createdAt,
    updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          id == other.id &&
          participantId == other.participantId &&
          participantNickname == other.participantNickname &&
          encryptedKey == other.encryptedKey &&
          const ListEquality<Message>().equals(messages, other.messages) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;
}
