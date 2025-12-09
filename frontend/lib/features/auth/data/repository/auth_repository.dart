import 'package:hecate/features/auth/data/api/auth_api.dart';
import 'package:hecate/features/auth/data/storage/auth_storage.dart';
import 'package:hecate/features/auth/data/storage/auth_tokens.dart';

abstract interface class AuthRepository {
  Future<String?> loadNickname();

  Future<void> clearSession();

  Future<String> initRegister({
    required String nickname,
  });

  Future<bool> verifyRegister({
    required String nickname,
    required String pub9c,
    required String pub9d,
    required String signedChallenge,
  });

  Future<String> initLogin({
    required String nickname,
  });

  Future<void> verifyLogin({
    required String nickname,
    required String signedChallenge,
  });

  Future<String?> getAccessToken();

  Future<bool> refreshTokens();
}

final class AuthRepositoryImpl implements AuthRepository {
  final AuthStorage _storage;
  final AuthApi _api;

  AuthRepositoryImpl({
    required AuthStorage storage,
    required AuthApi api,
  }) : _storage = storage,
       _api = api;

  @override
  Future<String?> loadNickname() async {
    final nickname = await _storage.readNickname();
    return nickname;
  }

  @override
  Future<void> clearSession() => _storage.clear();

  @override
  Future<String> initRegister({
    required String nickname,
  }) async {
    final response = await _api.initRegister(
      nickname: nickname,
    );
    return response.challenge;
  }

  @override
  Future<bool> verifyRegister({
    required String nickname,
    required String pub9c,
    required String pub9d,
    required String signedChallenge,
  }) async {
    final response = await _api.verifyRegister(
      nickname: nickname,
      pub9c: pub9c,
      pub9d: pub9d,
      signedChallenge: signedChallenge,
    );
    return response.success;
  }

  @override
  Future<String> initLogin({
    required String nickname,
  }) async {
    final response = await _api.initLogin(
      nickname: nickname,
    );
    return response.challenge;
  }

  @override
  Future<void> verifyLogin({
    required String nickname,
    required String signedChallenge,
  }) async {
    final response = await _api.verifyLogin(
      nickname: nickname,
      signature: signedChallenge,
    );
    final tokens = AuthTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    await _storage.saveTokens(tokens);
    await _storage.saveNickname(nickname);
  }

  @override
  Future<String?> getAccessToken() async {
    final tokens = await _storage.readTokens();
    return tokens?.accessToken;
  }

  @override
  Future<bool> refreshTokens() async {
    final nickname = await _storage.readNickname();
    if (nickname == null) {
      return false;
    }

    final refreshToken = (await _storage.readTokens())?.refreshToken;
    if (refreshToken == null) {
      return false;
    }

    final response = await _api.refreshToken(
      refreshToken: refreshToken,
      nickname: nickname,
    );

    final tokens = AuthTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    await _storage.saveTokens(tokens);

    return true;
  }
}
