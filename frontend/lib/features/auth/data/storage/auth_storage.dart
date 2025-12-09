import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hecate/features/auth/data/storage/auth_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AuthStorage {
  Future<void> saveNickname(String nickname);

  Future<String?> readNickname();

  Future<void> saveTokens(AuthTokens tokens);

  Future<AuthTokens?> readTokens();

  Future<void> clear();
}

final class AuthStorageImpl implements AuthStorage {
  // TODO(cocahonka): Secure storage requires the developer's signature, d
  // drop it for macOS for now
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'user';

  AuthStorageImpl({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage = secureStorage,
       _prefs = prefs;

  @override
  Future<void> saveNickname(String nickname) async {
    await _prefs.setString(
      _userKey,
      nickname,
    );
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    if (Platform.isMacOS) {
      await _prefs.setString(_accessTokenKey, tokens.accessToken);
      await _prefs.setString(_refreshTokenKey, tokens.refreshToken);
      return;
    }

    await _secureStorage.write(
      key: _accessTokenKey,
      value: tokens.accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: tokens.refreshToken,
    );
  }

  @override
  Future<String?> readNickname() async {
    return _prefs.getString(_userKey);
  }

  @override
  Future<AuthTokens?> readTokens() async {
    String? accessToken;
    String? refreshToken;

    if (Platform.isMacOS) {
      accessToken = _prefs.getString(_accessTokenKey);
      refreshToken = _prefs.getString(_refreshTokenKey);
    } else {
      accessToken = await _secureStorage.read(
        key: _accessTokenKey,
      );
      refreshToken = await _secureStorage.read(
        key: _refreshTokenKey,
      );
    }
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> clear() async {
    if (Platform.isMacOS) {
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_refreshTokenKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    }
    await _prefs.remove(_userKey);
  }
}
