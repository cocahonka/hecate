import 'dart:convert';

import 'package:hecate/features/bindings/domain/bindings_state.dart';
import 'package:hecate/features/bindings/domain/bindings_state_manager.dart';
import 'package:l/l.dart';
import 'package:piv_bindings/piv_bindings.dart';
import 'package:synchronized/synchronized.dart';
import 'package:yx_scope/yx_scope.dart';

typedef BindingsKeys = ({String pk9cPem, String pk9dPem});

typedef AesEncryptedKeys = ({
  String myEncryptedKey,
  String participantEncryptedKey,
});

abstract interface class BindingsInteractor implements AsyncLifecycle {
  Future<void> openSession();

  Future<void> closeSession();

  Future<BindingsKeys?> getKeys();

  Future<String?> signChallenge({
    required String challengeBase64url,
    required String? pin,
  });

  Future<AesEncryptedKeys?> generateEncryptedKeys({
    required String participantPk9dPem,
  });

  Future<String?> decryptMessage({
    required String myEncryptedKey,
    required String encryptedMessage,
    required String? pin,
  });

  Future<String?> encryptMessage({
    required String myEncryptedKey,
    required String plaintext,
    required String? pin,
  });
}

final class BindingsInteractorImpl implements BindingsInteractor {
  final PivBindings _bindings;
  final BindingsStateManager _stateManager;

  final Lock _lock = Lock();

  BindingsInteractorImpl({
    required PivBindings bindings,
    required BindingsStateManager stateManager,
  }) : _bindings = bindings,
       _stateManager = stateManager;

  @override
  Future<void> init() async {
    await openSession();
  }

  @override
  Future<void> dispose() async {
    await closeSession();
  }

  @override
  Future<void> openSession() async => _lock.synchronized(
    () async {
      if (_stateManager.state
          case BindingsState$Opened() || BindingsState$Opening()) {
        return;
      }

      await _stateManager.setOpening();

      final OpenDeviceResult result;
      try {
        result = _bindings.openDevice();
      } on Object catch (error, stackTrace) {
        l.e(
          'Failed to open session $error',
          stackTrace,
        );
        await _stateManager.setOpeningError(
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }

      if (result.status is PivBindingsStatus$Ok) {
        await _stateManager.setOpened(handle: result.handle);
        return;
      }

      await _stateManager.setOpeningFailed(
        status: result.status,
      );
    },
  );

  @override
  Future<void> closeSession() async => _lock.synchronized(
    () async {
      final state = _stateManager.state;
      if (state is! BindingsState$Opened) {
        return;
      }

      final PivBindingsStatus closeStatus;
      try {
        closeStatus = _bindings.closeDevice(handle: state.handle);
      } on Object catch (error, stackTrace) {
        l.e(
          'Failed to close session $error',
          stackTrace,
        );
        return;
      }

      if (closeStatus is! PivBindingsStatus$Ok) {
        l.w('Failed to close session, status: $closeStatus');
        return;
      }

      await _stateManager.setClosed();
    },
  );

  @override
  Future<BindingsKeys?> getKeys() async {
    final state = _stateManager.state;
    if (state is! BindingsState$Opened) {
      return null;
    }

    final GetPivStatusResult result;
    try {
      result = _bindings.getPivStatus(handle: state.handle);
    } on Object catch (error, stackTrace) {
      l.e(
        'Failed to get keys $error',
        stackTrace,
      );
      await _stateManager.setCallError(
        handle: state.handle,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }

    if (result.status is! PivBindingsStatus$Ok) {
      l.w('Failed to get keys, status: ${result.status}');
      await _stateManager.setCallFailed(
        handle: state.handle,
        status: result.status,
      );
      return null;
    }

    if (!result.has9c || !result.has9d) {
      await _stateManager.setInconsistentState(
        handle: state.handle,
        type: BindingsInconsistentType.missingKeys,
      );
      return null;
    }

    await _stateManager.setOpened(handle: state.handle);

    return (
      pk9cPem: result.pk9cPem,
      pk9dPem: result.pk9dPem,
    );
  }

  @override
  Future<String?> signChallenge({
    required String challengeBase64url,
    required String? pin,
  }) async {
    final state = _stateManager.state;
    if (state is! BindingsState$Opened) {
      return null;
    }

    final SignChallengeResult result;
    try {
      result = _bindings.signChallenge(
        handle: state.handle,
        challengeBase64url: challengeBase64url,
        pin: pin,
      );
    } on Object catch (error, stackTrace) {
      l.e(
        'Failed to sign challenge $error',
        stackTrace,
      );
      await _stateManager.setCallError(
        handle: state.handle,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }

    if (result.status is PivBindingsStatus$PinRequired) {
      await _stateManager.setInconsistentState(
        handle: state.handle,
        type: BindingsInconsistentType.pinRequired,
      );
      return null;
    }

    if (result.status is! PivBindingsStatus$Ok) {
      l.w('Failed to sign challenge, status: ${result.status}');
      await _stateManager.setCallFailed(
        handle: state.handle,
        status: result.status,
      );
      return null;
    }

    await _stateManager.setOpened(handle: state.handle);

    return result.signatureDerBase64url;
  }

  @override
  Future<AesEncryptedKeys?> generateEncryptedKeys({
    required String participantPk9dPem,
  }) async {
    final state = _stateManager.state;
    if (state is! BindingsState$Opened) {
      return null;
    }

    final WrapAesForRecipientsResult result;
    try {
      final myKeys = await getKeys();
      if (myKeys == null) {
        return null;
      }
      result = _bindings.wrapAesForRecipients(
        recipientsPk9dPem: [
          participantPk9dPem,
          myKeys.pk9dPem,
        ],
      );
    } on Object catch (error, stackTrace) {
      l.e(
        'Failed to generate encrypted keys $error',
        stackTrace,
      );
      return null;
    }

    if (result.status is PivBindingsStatus$PinRequired) {
      await _stateManager.setInconsistentState(
        handle: state.handle,
        type: BindingsInconsistentType.pinRequired,
      );
      return null;
    }

    if (result.status is! PivBindingsStatus$Ok ||
        result.aesEnvelopes.length != 2) {
      l.w('Failed to generate encrypted keys, status: ${result.status}');
      return null;
    }

    await _stateManager.setOpened(handle: state.handle);

    return (
      myEncryptedKey: json.encode(result.aesEnvelopes.first.toJson()),
      participantEncryptedKey: json.encode(result.aesEnvelopes.last.toJson()),
    );
  }

  @override
  Future<String?> decryptMessage({
    required String myEncryptedKey,
    required String encryptedMessage,
    required String? pin,
  }) async {
    final state = _stateManager.state;
    if (state is! BindingsState$Opened) {
      return null;
    }

    final DecryptMessageResult result;
    try {
      result = _bindings.decryptMessage(
        handle: state.handle,
        aesEnvelope: AesEnvelope.fromJson(
          json.decode(myEncryptedKey) as Map<String, Object?>,
        ),
        messageEnvelope: MessageEnvelope.fromJson(
          json.decode(encryptedMessage) as Map<String, Object?>,
        ),
        pin: pin,
      );
    } on Object catch (error, stackTrace) {
      l.e(
        'Failed to decrypt message $error',
        stackTrace,
      );
      return null;
    }

    if (result.status is PivBindingsStatus$PinRequired) {
      await _stateManager.setInconsistentState(
        handle: state.handle,
        type: BindingsInconsistentType.pinRequired,
      );
      return null;
    }

    if (result.status is! PivBindingsStatus$Ok) {
      l.w('Failed to decrypt message, status: ${result.status}');
      return null;
    }

    return result.plaintextBase64url.plaintextFromBase64url;
  }

  @override
  Future<String?> encryptMessage({
    required String myEncryptedKey,
    required String plaintext,
    required String? pin,
  }) async {
    final state = _stateManager.state;
    if (state is! BindingsState$Opened) {
      return null;
    }

    final EncryptMessageResult result;
    try {
      result = _bindings.encryptMessage(
        handle: state.handle,
        aesEnvelope: AesEnvelope.fromJson(
          json.decode(myEncryptedKey) as Map<String, Object?>,
        ),
        plaintextBase64url: plaintext.base64urlFromPlaintext,
        pin: pin,
      );
    } on Object catch (error, stackTrace) {
      l.e(
        'Failed to encrypt message $error',
        stackTrace,
      );
      return null;
    }

    if (result.status is PivBindingsStatus$PinRequired) {
      await _stateManager.setInconsistentState(
        handle: state.handle,
        type: BindingsInconsistentType.pinRequired,
      );
      return null;
    }

    if (result.status is! PivBindingsStatus$Ok) {
      l.w('Failed to encrypt message, status: ${result.status}');
      return null;
    }

    return json.encode(
      result.messageEnvelope.toJson(),
    );
  }
}

extension _Base64Extension on String {
  String get plaintextFromBase64url => utf8.decode(base64Url.decode(this));

  String get base64urlFromPlaintext => base64Url.encode(utf8.encode(this));
}
