abstract interface class MessagesApiPaths {
  String get sendMessagePath;

  String get historyPath;
}

final class MessagesApiPathsImpl implements MessagesApiPaths {
  @override
  String get sendMessagePath => 'api/v1/messages';

  @override
  String get historyPath => 'api/v1/messages';
}
