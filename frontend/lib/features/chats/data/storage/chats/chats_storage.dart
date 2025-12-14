import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ChatsStorage {
  Future<void> saveParticipantNicknameByChatId({
    required String myNickname,
    required String chatId,
    required String participantNickname,
  });

  Future<String?> readParticipantNicknameByChatId({
    required String myNickname,
    required String chatId,
  });
}

final class ChatsStorageImpl implements ChatsStorage {
  final SharedPreferences _prefs;

  static const _participantNicknameByChatIdKey = 'chat_participant_nickname';

  ChatsStorageImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  @override
  Future<void> saveParticipantNicknameByChatId({
    required String myNickname,
    required String chatId,
    required String participantNickname,
  }) async {
    await _prefs.setString(
      '$_participantNicknameByChatIdKey:$myNickname:$chatId',
      participantNickname,
    );
  }

  @override
  Future<String?> readParticipantNicknameByChatId({
    required String myNickname,
    required String chatId,
  }) async {
    return _prefs.getString(
      '$_participantNicknameByChatIdKey:$myNickname:$chatId',
    );
  }
}
