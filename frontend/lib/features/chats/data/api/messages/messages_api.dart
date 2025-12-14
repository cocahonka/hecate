import 'package:dio/dio.dart';

import 'package:hecate/features/chats/data/api/messages/messages_api_paths.dart';
import 'package:hecate/features/chats/data/api/messages/messages_responses.dart';

abstract interface class MessagesApi {
  Future<MessageResponse> sendMessage({
    required String chatId,
    required String encryptedPayload,
  });

  Future<HistoryResponse> getHistory({
    required String chatId,
    int? limit,
    int? offset,
  });
}

final class MessagesApiImpl implements MessagesApi {
  final Dio _dio;
  final MessagesApiPaths _paths;

  MessagesApiImpl({
    required Dio dio,
    required MessagesApiPaths paths,
  }) : _dio = dio,
       _paths = paths;

  @override
  Future<MessageResponse> sendMessage({
    required String chatId,
    required String encryptedPayload,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.sendMessagePath,
      data: {
        'chat_id': chatId,
        'encrypted_payload': encryptedPayload,
      },
    );
    final data = response.data!;
    return MessageResponse.fromJson(data);
  }

  @override
  Future<HistoryResponse> getHistory({
    required String chatId,
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.historyPath,
      queryParameters: {
        'chat_id': chatId,
        'limit': ?limit,
        'offset': ?offset,
      },
    );
    final data = response.data!;
    return HistoryResponse.fromJson(data);
  }
}
