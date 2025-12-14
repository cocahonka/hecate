import 'dart:collection';

import 'package:hecate/features/bindings/domain/bindings_interactor.dart';
import 'package:hecate/features/chats/data/api/chats/chats_api.dart';
import 'package:hecate/features/chats/data/api/messages/messages_api.dart';
import 'package:hecate/features/chats/data/api/users/users_api.dart';
import 'package:hecate/features/chats/data/storage/chats/chats_storage.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:hecate/features/chats/domain/models/message.dart';

abstract interface class ChatsRepository {
  Future<List<Chat>> getUserChats();

  Future<String> getParticipantPk9dPem({
    required String participantNickname,
  });

  Future<Chat> createChat({
    required String participantNickname,
    required AesEncryptedKeys encryptedKeys,
  });

  Future<List<Message>> getMessages({
    required String chatId,
    required String myNickname,
  });

  Future<Message> sendMessage({
    required String chatId,
    required String encryptedPayload,
    required String myNickname,
  });
}

final class ChatsRepositoryImpl implements ChatsRepository {
  final ChatsApi _chatsApi;
  final MessagesApi _messagesApi;
  final UsersApi _usersApi;
  final ChatsStorage _chatsStorage;

  ChatsRepositoryImpl({
    required ChatsApi chatsApi,
    required MessagesApi messagesApi,
    required UsersApi usersApi,
    required ChatsStorage chatsStorage,
  }) : _chatsApi = chatsApi,
       _messagesApi = messagesApi,
       _usersApi = usersApi,
       _chatsStorage = chatsStorage;

  @override
  Future<List<Chat>> getUserChats() async {
    final chatsResponse = await _chatsApi.getUserChats();

    final chats = <Chat>[];
    for (final chatResponse in chatsResponse.chats) {
      final participantNickname = await _chatsStorage
          .readParticipantNicknameByChatId(
            chatId: chatResponse.id,
          );

      if (participantNickname == null) {
        continue;
      }

      final encryptedKeyResponse = await _chatsApi.getEncryptedKey(
        chatId: chatResponse.id,
      );

      final participantResponse = await _usersApi.getUserByNickname(
        nickname: participantNickname,
      );

      chats.add(
        Chat(
          id: chatResponse.id,
          createdAt: chatResponse.createdAt,
          updatedAt: chatResponse.updatedAt,
          participantNickname: participantNickname,
          participantId: participantResponse.id,
          encryptedKey: encryptedKeyResponse.encryptedKey,
          messages: UnmodifiableListView([]),
        ),
      );
    }

    return chats;
  }

  @override
  Future<String> getParticipantPk9dPem({
    required String participantNickname,
  }) async {
    final participantResponse = await _usersApi.getUserByNickname(
      nickname: participantNickname,
    );
    return participantResponse.pub9d;
  }

  @override
  Future<Chat> createChat({
    required String participantNickname,
    required AesEncryptedKeys encryptedKeys,
  }) async {
    final participantIdResponse = await _usersApi.getUserByNickname(
      nickname: participantNickname,
    );

    final chat = await _chatsApi.createChat(
      participantId: participantIdResponse.id,
      myEncryptedKey: encryptedKeys.myEncryptedKey,
      participantEncryptedKey: encryptedKeys.participantEncryptedKey,
    );

    return Chat(
      id: chat.id,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
      participantNickname: participantNickname,
      participantId: participantIdResponse.id,
      encryptedKey: encryptedKeys.myEncryptedKey,
      messages: UnmodifiableListView([]),
    );
  }

  @override
  Future<List<Message>> getMessages({
    required String chatId,
    required String myNickname,
  }) async {
    final participantNickname = await _chatsStorage
        .readParticipantNicknameByChatId(
          chatId: chatId,
        );

    if (participantNickname == null) {
      throw StateError('Participant nickname not found for chat $chatId');
    }

    final messagesResponse = await _messagesApi.getHistory(
      chatId: chatId,
      limit: 0,
    );

    final participantResponse = await _usersApi.getUserByNickname(
      nickname: participantNickname,
    );

    final myUserResponse = await _usersApi.getUserByNickname(
      nickname: myNickname,
    );

    final messages = <Message>[];
    for (final messageResponse in messagesResponse.messages) {
      messages.add(
        Message(
          id: messageResponse.id,
          chatId: messageResponse.chatId,
          senderId: messageResponse.senderId,
          nickname: messageResponse.senderId == myUserResponse.id
              ? myNickname
              : participantResponse.nickname,
          content: messageResponse.encryptedPayload,
          createdAt: messageResponse.createdAt,
        ),
      );
    }

    return messages;
  }

  @override
  Future<Message> sendMessage({
    required String chatId,
    required String encryptedPayload,
    required String myNickname,
  }) async {
    final messageResponse = await _messagesApi.sendMessage(
      chatId: chatId,
      encryptedPayload: encryptedPayload,
    );

    return Message(
      id: messageResponse.id,
      chatId: messageResponse.chatId,
      senderId: messageResponse.senderId,
      nickname: myNickname,
      content: messageResponse.encryptedPayload,
      createdAt: messageResponse.createdAt,
    );
  }
}
