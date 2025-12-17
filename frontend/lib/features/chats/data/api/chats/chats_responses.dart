import 'package:meta/meta.dart';

@immutable
final class ChatResponse {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatResponse({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatResponse.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'id': final String id,
      'created_at': final String createdAt,
      'updated_at': final String updatedAt,
    } =>
      ChatResponse(
        id: id,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      ),
    _ => throw FormatException('Invalid ChatResponse: $json'),
  };
}

@immutable
final class ChatListResponse {
  final List<ChatResponse> chats;
  final int total;

  ChatListResponse({
    required this.chats,
    required this.total,
  });

  factory ChatListResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'chats': final List<Object?> chatsJson,
          'total': final int total,
        } =>
          ChatListResponse(
            chats: chatsJson
                .cast<Map<String, Object?>>()
                .map((chatJson) => ChatResponse.fromJson(chatJson))
                .toList(growable: false),
            total: total,
          ),
        _ => throw FormatException('Invalid ChatListResponse: $json'),
      };
}

@immutable
final class IsMemberResponse {
  final bool isMember;

  IsMemberResponse({
    required this.isMember,
  });

  factory IsMemberResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'is_member': final bool isMember,
        } =>
          IsMemberResponse(isMember: isMember),
        _ => throw FormatException('Invalid IsMemberResponse: $json'),
      };
}

@immutable
final class EncryptedKeyResponse {
  final String encryptedKey;

  EncryptedKeyResponse({
    required this.encryptedKey,
  });

  factory EncryptedKeyResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'encrypted_key': final String encryptedKey,
        } =>
          EncryptedKeyResponse(encryptedKey: encryptedKey),
        _ => throw FormatException('Invalid EncryptedKeyResponse: $json'),
      };
}

@immutable
final class ChatMembersResponse {
  final List<ChatMemberResponse> members;

  ChatMembersResponse({
    required this.members,
  });

  factory ChatMembersResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'members': final List<Object?> membersJson,
        } =>
          ChatMembersResponse(
            members: membersJson
                .cast<Map<String, Object?>>()
                .map((memberJson) => ChatMemberResponse.fromJson(memberJson))
                .toList(growable: false),
          ),
        _ => throw FormatException('Invalid ChatMembersResponse: $json'),
      };
}

@immutable
final class ChatMemberResponse {
  final String userId;
  final DateTime joinedAt;

  ChatMemberResponse({
    required this.userId,
    required this.joinedAt,
  });

  factory ChatMemberResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'user_id': final String userId,
          'joined_at': final String joinedAt,
        } =>
          ChatMemberResponse(
            userId: userId,
            joinedAt: DateTime.parse(joinedAt),
          ),
        _ => throw FormatException('Invalid ChatMemberResponse: $json'),
      };
}
