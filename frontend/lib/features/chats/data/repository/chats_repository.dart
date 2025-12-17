import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:hecate/features/bindings/domain/bindings_interactor.dart';
import 'package:hecate/features/chats/data/api/chats/chats_api.dart';
import 'package:hecate/features/chats/data/api/messages/messages_api.dart';
import 'package:hecate/features/chats/data/api/users/users_api.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:hecate/features/chats/domain/models/message.dart';

abstract interface class ChatsRepository {
  Future<List<Chat>> getUserChats({
    required String myNickname,
  });

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

  ChatsRepositoryImpl({
    required ChatsApi chatsApi,
    required MessagesApi messagesApi,
    required UsersApi usersApi,
  }) : _chatsApi = chatsApi,
       _messagesApi = messagesApi,
       _usersApi = usersApi;

  @override
  Future<List<Chat>> getUserChats({
    required String myNickname,
  }) async {
    final myUserId = (await _usersApi.getUserInfoByNickname(
      nickname: myNickname,
    )).id;
    final chatsResponse = await _chatsApi.getUserChats();

    final chats = <Chat>[];
    for (final chatResponse in chatsResponse.chats) {
      final chatMembersResponse = await _chatsApi.getChatMembers(
        chatId: chatResponse.id,
      );
      final participantId = chatMembersResponse.members
          .firstWhere((member) => member.userId != myUserId)
          .userId;
      final participantNickname = (await _usersApi.getUserInfoById(
        id: participantId,
      )).nickname;

      final encryptedKey = (await _chatsApi.getEncryptedKey(
        chatId: chatResponse.id,
      )).encryptedKey;

      chats.add(
        Chat(
          id: chatResponse.id,
          createdAt: chatResponse.createdAt,
          updatedAt: chatResponse.updatedAt,
          participantNickname: participantNickname,
          participantId: participantId,
          encryptedKey: encryptedKey,
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
    final participantResponse = await _usersApi.getUserInfoByNickname(
      nickname: participantNickname,
    );
    return participantResponse.pub9d;
  }

  @override
  Future<Chat> createChat({
    required String participantNickname,
    required AesEncryptedKeys encryptedKeys,
  }) async {
    final participantId = (await _usersApi.getUserInfoByNickname(
      nickname: participantNickname,
    )).id;

    final chat = await _chatsApi.createChat(
      participantId: participantId,
      myEncryptedKey: encryptedKeys.myEncryptedKey,
      participantEncryptedKey: encryptedKeys.participantEncryptedKey,
    );

    return Chat(
      id: chat.id,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
      participantNickname: participantNickname,
      participantId: participantId,
      encryptedKey: encryptedKeys.myEncryptedKey,
      messages: UnmodifiableListView([]),
    );
  }

  @override
  Future<List<Message>> getMessages({
    required String chatId,
    required String myNickname,
  }) async {
    final chatMembersResponse = await _chatsApi.getChatMembers(
      chatId: chatId,
    );
    final myUserId = (await _usersApi.getUserInfoByNickname(
      nickname: myNickname,
    )).id;
    final participantId = chatMembersResponse.members
        .firstWhere((member) => member.userId != myUserId)
        .userId;
    final participantNickname = (await _usersApi.getUserInfoById(
      id: participantId,
    )).nickname;

    final messagesResponse = await _messagesApi.getHistory(
      chatId: chatId,
      limit: 1000,
    );

    final messages = <Message>[];
    for (final messageResponse in messagesResponse.messages) {
      messages.add(
        Message(
          id: messageResponse.id,
          chatId: messageResponse.chatId,
          senderId: messageResponse.senderId,
          nickname: messageResponse.senderId == myUserId
              ? myNickname
              : participantNickname,
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
