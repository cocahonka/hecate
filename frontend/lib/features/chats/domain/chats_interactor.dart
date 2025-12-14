import 'package:collection/collection.dart';
import 'package:hecate/features/app/navigation/app_navigation_manager.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';
import 'package:hecate/features/auth/domain/auth_state_manager.dart';
import 'package:hecate/features/bindings/domain/bindings_interactor.dart';
import 'package:hecate/features/chats/data/repository/chats_repository.dart';
import 'package:hecate/features/chats/domain/chats_state_manager.dart';
import 'package:hecate/features/chats/domain/models/chat.dart';
import 'package:hecate/features/chats/domain/models/message.dart';
import 'package:l/l.dart';
import 'package:synchronized/synchronized.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class ChatsInteractor implements AsyncLifecycle {
  Future<void> updateChatsList();

  Future<void> createChat({
    required String participantNickname,
  });

  Future<void> openChat({
    required String chatId,
  });

  Future<void> closeChat({
    required String chatId,
  });

  Future<void> updateMessages({
    required String chatId,
  });

  Future<void> sendMessage({
    required String chatId,
    required String message,
  });
}

final class ChatsInteractorImpl implements ChatsInteractor {
  final ChatsRepository _repository;
  final ChatsStateManager _stateManager;
  final BindingsInteractor _bindingsInteractor;
  final AppNavigationManager _appNavigationManager;
  final AuthStateManager _authStateManager;

  final Lock _lock = Lock();

  ChatsInteractorImpl({
    required ChatsRepository repository,
    required ChatsStateManager stateManager,
    required BindingsInteractor bindingsInteractor,
    required AppNavigationManager appNavigationManager,
    required AuthStateManager authStateManager,
  }) : _repository = repository,
       _stateManager = stateManager,
       _bindingsInteractor = bindingsInteractor,
       _appNavigationManager = appNavigationManager,
       _authStateManager = authStateManager;

  @override
  Future<void> init() async {
    // ignore: unawaited_futures
    updateChatsList();
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> updateChatsList() async => _lock.synchronized(
    () async {
      await _stateManager.setLoading();

      final UnmodifiableListView<Chat> updatedChats;
      try {
        final myNickname = _authStateManager.state.nickname;
        if (myNickname == null) {
          throw StateError('My nickname is null');
        }

        final chatsResponse = await _repository.getUserChats(
          myNickname: myNickname,
        );
        final currentChats = _stateManager.state.chats;
        final currentChatsById = {
          for (final chat in currentChats) chat.id: chat,
        };

        updatedChats = UnmodifiableListView(
          chatsResponse.map(
            (chatResponse) {
              final currentChat = currentChatsById[chatResponse.id];

              return Chat(
                id: chatResponse.id,
                participantId: chatResponse.participantId,
                participantNickname: chatResponse.participantNickname,
                encryptedKey: chatResponse.encryptedKey,
                messages: currentChat?.messages ?? UnmodifiableListView([]),
                createdAt: chatResponse.createdAt,
                updatedAt: chatResponse.updatedAt,
              );
            },
          ),
        );
      } on Object catch (error, stackTrace) {
        // todo add popup error message
        await _stateManager.setError(
          consequence: 'Failed to update chats list',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }

      await _stateManager.setIdle(
        chats: updatedChats,
      );
    },
  );

  @override
  Future<void> createChat({
    required String participantNickname,
  }) async => _lock.synchronized(
    () async {
      final myNickname = _authStateManager.state.nickname;

      if (myNickname == null) {
        l.w(
          'Failed to update messages - myNickname is null',
        );
        return;
      }

      final currentChats = _stateManager.state.chats;
      if (currentChats.any(
        (chat) => chat.participantNickname == participantNickname,
      )) {
        // todo add popup info message
        return;
      }

      final participantPk9dPem = await _repository.getParticipantPk9dPem(
        participantNickname: participantNickname,
      );

      final encryptedKeys = await _bindingsInteractor.generateEncryptedKeys(
        participantPk9dPem: participantPk9dPem,
      );

      if (encryptedKeys == null) {
        // todo add popup error message
        return;
      }

      final chat = await _repository.createChat(
        myNickname: myNickname,
        participantNickname: participantNickname,
        encryptedKeys: encryptedKeys,
      );

      await _stateManager.setIdle(
        chats: UnmodifiableListView([
          ...currentChats,
          chat,
        ]),
      );
    },
  );

  @override
  Future<void> openChat({
    required String chatId,
  }) async => _lock.synchronized(
    () async {
      final pages = _appNavigationManager.controller.value;
      if (pages.any(
        (page) => page is SingleChatPage && page.arguments['chatId'] == chatId,
      )) {
        return;
      }

      _appNavigationManager.controller.value = [
        ...pages,
        SingleChatPage(chatId: chatId),
      ];
    },
  );

  @override
  Future<void> closeChat({
    required String chatId,
  }) async => _lock.synchronized(
    () async {
      final pages = _appNavigationManager.controller.value;

      _appNavigationManager.controller.value = pages
          .where(
            (page) =>
                page is! SingleChatPage || page.arguments['chatId'] != chatId,
          )
          .toList(growable: false);
    },
  );

  @override
  Future<void> updateMessages({
    required String chatId,
  }) async => _lock.synchronized(
    () async {
      final myNickname = _authStateManager.state.nickname;

      if (myNickname == null) {
        l.w(
          'Failed to update messages - myNickname is null',
        );
        return;
      }

      final currentChats = _stateManager.state.chats;

      final chat = currentChats.firstWhereOrNull(
        (chat) => chat.id == chatId,
      );

      if (chat == null) {
        l.w(
          'Failed to update messages - chat not found - chatId: $chatId',
        );
        return;
      }

      final encryptedMessages = await _repository.getMessages(
        chatId: chatId,
        myNickname: myNickname,
      );

      final decryptedMessages = <Message>[];
      for (final encryptedMessage in encryptedMessages) {
        final decryptedMessage = await _bindingsInteractor.decryptMessage(
          myEncryptedKey: chat.encryptedKey,
          encryptedMessage: encryptedMessage.content,
          pin: null,
        );

        if (decryptedMessage == null) {
          l.w(
            'Failed to decrypt message - chatId: $chatId, messageId: ${encryptedMessage.id}',
          );
          continue;
        }

        decryptedMessages.add(
          encryptedMessage.copyWith(
            content: decryptedMessage,
          ),
        );
      }

      final updatedChat = chat.copyWith(
        messages: UnmodifiableListView(decryptedMessages),
      );

      await _stateManager.setIdle(
        chats: UnmodifiableListView([
          updatedChat,
          ...currentChats.where((chat) => chat.id != chatId),
        ]),
      );
    },
  );

  @override
  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async => _lock.synchronized(
    () async {
      final myNickname = _authStateManager.state.nickname;

      if (myNickname == null) {
        l.w(
          'Failed to send message - myNickname is null',
        );
        return;
      }

      final currentChats = _stateManager.state.chats;
      final chat = currentChats.firstWhereOrNull(
        (chat) => chat.id == chatId,
      );

      if (chat == null) {
        l.w(
          'Failed to send message - chat not found - chatId: $chatId',
        );
        return;
      }

      final encryptedPayload = await _bindingsInteractor.encryptMessage(
        myEncryptedKey: chat.encryptedKey,
        plaintext: message,
        pin: null,
      );

      if (encryptedPayload == null) {
        l.w(
          'Failed to encrypt message - chatId: $chatId, message: $message',
        );
        return;
      }

      final encryptedMessage = await _repository.sendMessage(
        chatId: chatId,
        encryptedPayload: encryptedPayload,
        myNickname: myNickname,
      );

      final decryptedMessage = await _bindingsInteractor.decryptMessage(
        myEncryptedKey: chat.encryptedKey,
        encryptedMessage: encryptedMessage.content,
        pin: null,
      );

      if (decryptedMessage == null) {
        l.w(
          'Failed to decrypt message - chatId: $chatId, message: $message',
        );
        return;
      }

      final updatedChat = chat.copyWith(
        messages: UnmodifiableListView(
          [
            ...chat.messages,
            encryptedMessage.copyWith(
              content: decryptedMessage,
            ),
          ],
        ),
      );

      await _stateManager.setIdle(
        chats: UnmodifiableListView([
          updatedChat,
          ...currentChats.where((chat) => chat.id != chatId),
        ]),
      );
    },
  );
}
