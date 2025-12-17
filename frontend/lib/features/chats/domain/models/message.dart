import 'package:meta/meta.dart';

@immutable
final class Message {
  final String id;
  final String chatId;
  final String nickname;
  final String senderId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.nickname,
    required this.content,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? nickname,
    String? content,
    DateTime? createdAt,
  }) => Message(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    senderId: senderId ?? this.senderId,
    nickname: nickname ?? this.nickname,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    senderId,
    nickname,
    content,
    createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          id == other.id &&
          chatId == other.chatId &&
          senderId == other.senderId &&
          nickname == other.nickname &&
          content == other.content &&
          createdAt == other.createdAt;

  @override
  String toString() =>
      'Message('
      'id: $id, '
      'chatId: $chatId, '
      'senderId: $senderId, '
      'nickname: $nickname, '
      'content: $content, '
      'createdAt: $createdAt'
      ')';
}
