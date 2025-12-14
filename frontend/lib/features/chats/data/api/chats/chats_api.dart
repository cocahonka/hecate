import 'package:dio/dio.dart';

import 'package:hecate/features/chats/data/api/chats/chats_api_paths.dart';
import 'package:hecate/features/chats/data/api/chats/chats_responses.dart';

abstract interface class ChatsApi {
  Future<ChatListResponse> getUserChats({
    int? limit,
    int? offset,
  });

  Future<ChatResponse> createChat({
    required String participantId,
    required String myEncryptedKey,
    required String participantEncryptedKey,
  });

  Future<ChatResponse> getChatById({
    required String chatId,
  });

  Future<IsMemberResponse> checkMembership({
    required String chatId,
  });

  Future<EncryptedKeyResponse> getEncryptedKey({
    required String chatId,
  });
}

final class ChatsApiImpl implements ChatsApi {
  final Dio _dio;
  final ChatsApiPaths _paths;

  ChatsApiImpl({
    required Dio dio,
    required ChatsApiPaths paths,
  }) : _dio = dio,
       _paths = paths;

  @override
  Future<ChatListResponse> getUserChats({
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.getUserChatsPath,
      queryParameters: {
        'limit': ?limit,
        'offset': ?offset,
      },
    );
    final data = response.data!;
    return ChatListResponse.fromJson(data);
  }

  @override
  Future<ChatResponse> createChat({
    required String participantId,
    required String myEncryptedKey,
    required String participantEncryptedKey,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.createChatPath,
      data: {
        'participant_id': participantId,
        'my_encrypted_key': myEncryptedKey,
        'participant_encrypted_key': participantEncryptedKey,
      },
    );
    final data = response.data!;
    return ChatResponse.fromJson(data);
  }

  @override
  Future<ChatResponse> getChatById({
    required String chatId,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.chatByIdPath(chatId),
    );
    final data = response.data!;
    return ChatResponse.fromJson(data);
  }

  @override
  Future<IsMemberResponse> checkMembership({
    required String chatId,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.checkMembershipPath(chatId),
    );
    final data = response.data!;
    return IsMemberResponse.fromJson(data);
  }

  @override
  Future<EncryptedKeyResponse> getEncryptedKey({
    required String chatId,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.encryptedKeyPath(chatId),
    );
    final data = response.data!;
    return EncryptedKeyResponse.fromJson(data);
  }
}
