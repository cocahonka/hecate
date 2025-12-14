abstract interface class ChatsApiPaths {
  String get getUserChatsPath;

  String get createChatPath;

  String chatByIdPath(String id);

  String encryptedKeyPath(String id);

  String checkMembershipPath(String id);
}

final class ChatsApiPathsImpl implements ChatsApiPaths {
  @override
  String get getUserChatsPath => 'api/v1/chats';

  @override
  String get createChatPath => 'api/v1/chats';

  @override
  String chatByIdPath(String chatId) => 'api/v1/chats/$chatId';

  @override
  String encryptedKeyPath(String chatId) => 'api/v1/chats/$chatId/key';

  @override
  String checkMembershipPath(String chatId) => 'api/v1/chats/$chatId/member';
}
