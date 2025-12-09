import 'dart:async';

import 'package:hecate/features/auth/data/repository/auth_repository.dart';
import 'package:hecate/features/auth/domain/auth_state.dart';
import 'package:hecate/features/auth/domain/auth_state_manager.dart';
import 'package:hecate/features/bindings/domain/bindings_interactor.dart';
import 'package:l/l.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class AuthInteractor implements AsyncLifecycle {
  Future<String?> getNickname();

  Future<bool> register({
    required String nickname,
    required String? pin,
  });

  Future<void> login({
    required String nickname,
    required String? pin,
  });

  Future<void> restoreSession({
    required String? pin,
  });

  Future<void> logout();
}

final class AuthInteractorImpl implements AuthInteractor {
  final AuthRepository _repository;
  final AuthStateManager _stateManager;
  final BindingsInteractor _bindingsInteractor;

  AuthInteractorImpl({
    required AuthRepository repository,
    required AuthStateManager stateManager,
    required BindingsInteractor bindingsInteractor,
  }) : _repository = repository,
       _stateManager = stateManager,
       _bindingsInteractor = bindingsInteractor;

  @override
  Future<void> init() async {
    final nickname = await _repository.loadNickname().onError(
      (
        error,
        stackTrace,
      ) {
        l.e('Failed to load nickname $error', stackTrace);
        return null;
      },
    );

    if (nickname != null) {
      await _stateManager.setUnauthenticated(
        nickname: nickname,
      );
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> getNickname() async {
    return _repository.loadNickname();
  }

  @override
  Future<bool> register({
    required String nickname,
    required String? pin,
  }) async {
    if (_stateManager.state is AuthState$Authenticated) {
      l.i('Register failed: already authenticated');
      return false;
    }

    final challenge = await _repository.initRegister(
      nickname: nickname,
    );

    final signedChallenge = await _bindingsInteractor.signChallenge(
      challengeBase64url: challenge,
      pin: pin,
    );

    if (signedChallenge == null) {
      l.i('Register failed: failed to sign challenge');
      return false;
    }

    final keys = await _bindingsInteractor.getKeys();

    if (keys == null) {
      l.i('Register failed: failed to get keys');
      return false;
    }

    final success = await _repository.verifyRegister(
      nickname: nickname,
      pub9c: keys.pk9cPem,
      pub9d: keys.pk9dPem,
      signedChallenge: signedChallenge,
    );

    if (!success) {
      l.i('Register failed: failed to verify register');
      return false;
    }

    await _stateManager.setUnauthenticated(
      nickname: nickname,
    );

    return true;
  }

  @override
  Future<void> login({
    required String nickname,
    required String? pin,
  }) async {
    if (_stateManager.state is AuthState$Authenticated) {
      l.i('Login failed: already authenticated');
      return;
    }

    final challenge = await _repository.initLogin(
      nickname: nickname,
    );

    final signedChallenge = await _bindingsInteractor.signChallenge(
      challengeBase64url: challenge,
      pin: pin,
    );

    if (signedChallenge == null) {
      l.i('Login failed: failed to sign challenge');
      return;
    }

    await _repository.verifyLogin(
      nickname: nickname,
      signedChallenge: signedChallenge,
    );

    await _stateManager.setAuthenticated(
      nickname: nickname,
    );
  }

  @override
  Future<void> restoreSession({
    required String? pin,
  }) async {
    final nickname = await _repository.loadNickname();
    if (nickname == null) {
      l.i('Restore session failed: no nickname');
      return;
    }

    final challenge = await _repository.initLogin(
      nickname: nickname,
    );

    final signedChallenge = await _bindingsInteractor.signChallenge(
      challengeBase64url: challenge,
      pin: pin,
    );

    if (signedChallenge == null) {
      l.i('Restore session failed: failed to sign challenge');
      return;
    }

    await _repository.verifyLogin(
      nickname: nickname,
      signedChallenge: signedChallenge,
    );

    await _stateManager.setAuthenticated(
      nickname: nickname,
    );
  }

  @override
  Future<void> logout() async {
    await _stateManager.setUnauthenticated();
    await _repository.clearSession();
  }
}
