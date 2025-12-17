import 'package:meta/meta.dart';

@immutable
final class MessageResponse {
  final String id;
  final String chatId;
  final String senderId;
  final String encryptedPayload;
  final DateTime createdAt;

  MessageResponse({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.encryptedPayload,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'id': final String id,
      'chat_id': final String chatId,
      'sender_id': final String senderId,
      'encrypted_payload': final String encryptedPayload,
      'created_at': final String createdAt,
    } =>
      MessageResponse(
        id: id,
        chatId: chatId,
        senderId: senderId,
        encryptedPayload: encryptedPayload,
        createdAt: DateTime.parse(createdAt),
      ),
    _ => throw FormatException('Invalid MessageResponse: $json'),
  };
}

@immutable
final class HistoryResponse {
  final List<MessageResponse> messages;
  final int total;

  HistoryResponse({
    required this.messages,
    required this.total,
  });

  factory HistoryResponse.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'messages': final List<Object?> messagesJson,
      'total': final int total,
    } =>
      HistoryResponse(
        messages: messagesJson
            .cast<Map<String, Object?>>()
            .map(MessageResponse.fromJson)
            .toList(),
        total: total,
      ),
    _ => throw FormatException('Invalid HistoryResponse: $json'),
  };
}
