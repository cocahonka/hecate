import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:piv_bindings/piv_bindings.dart';
import 'package:test/test.dart';

void main() {
  // paths
  final packageRoot = Directory.current.path;
  final dylibPath = '$packageRoot/test/suite/golang_piv_bindings.dylib';
  final testEnvPath = '$packageRoot/test/suite/.env';

  // api & env
  final api = PivBindings(
    library: DynamicLibrary.open(dylibPath),
    testBindingsType: 'GOLANG',
  );
  final testEnvFile = File(testEnvPath).readAsLinesSync();
  final testPin = testEnvFile
      .firstWhere((line) => line.startsWith('TEST_PIV_PIN='))
      .split('=')
      .last;

  // helpers
  final random = Random.secure();
  final pemRegex = RegExp(
    r'^-----BEGIN PUBLIC KEY-----\s+[A-Za-z0-9+/=\r\n]+-----END PUBLIC KEY-----\s*$',
  );
  const invalidPem = '-----NOT A KEY-----';
  const invalidBase64url = 'not-base64url!!!==';
  final invalidHandle = BindingsHandle(100);
  final base64UrlNoPadRegex = RegExp(r'^[A-Za-z0-9_-]+$');
  String generateBase64urlNoPad() => base64Url
      .encode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');

  group('without PIN', () {
    test('sign challenge', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final sign = api.signChallenge(
        handle: opened.handle,
        challengeBase64url: generateBase64urlNoPad(),
        pin: null,
      );
      expect(sign.status, isA<PivBindingsStatus$PinRequired>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });

  group('device open/close', () {
    test(
      'open/close twice, status OK, handle different',
      () {
        final first = api.openDevice();
        expect(first.status, isA<PivBindingsStatus$Ok>());

        final firstClose = api.closeDevice(handle: first.handle);
        expect(firstClose, isA<PivBindingsStatus$Ok>());

        final second = api.openDevice();
        expect(second.status, isA<PivBindingsStatus$Ok>());
        expect(second.handle, isNot(equals(first.handle)));

        final secondClose = api.closeDevice(handle: second.handle);
        expect(secondClose, isA<PivBindingsStatus$Ok>());
      },
    );

    test(
      'double close, status OK, new handle on reopen',
      () {
        final opened = api.openDevice();
        expect(opened.status, isA<PivBindingsStatus$Ok>());

        final closed1 = api.closeDevice(handle: opened.handle);
        expect(closed1, isA<PivBindingsStatus$Ok>());

        final closed2 = api.closeDevice(handle: opened.handle);
        expect(closed2, isA<PivBindingsStatus$Ok>());

        final reopened = api.openDevice();
        expect(reopened.status, isA<PivBindingsStatus$Ok>());
        expect(reopened.handle, isNot(equals(opened.handle)));

        final closed3 = api.closeDevice(handle: reopened.handle);
        expect(closed3, isA<PivBindingsStatus$Ok>());
      },
    );

    test(
      'try to open second device, second open fails',
      () {
        final first = api.openDevice();
        expect(first.status, isA<PivBindingsStatus$Ok>());

        final second = api.openDevice();
        expect(second.status, isA<PivBindingsStatus$NotPresent>());

        final firstClose = api.closeDevice(handle: first.handle);
        expect(firstClose, isA<PivBindingsStatus$Ok>());

        final secondClose = api.closeDevice(handle: second.handle);
        expect(secondClose, isA<PivBindingsStatus$Ok>());
      },
    );

    test(
      'closeAllDevices closes all active sessions',
      () {
        final first = api.openDevice();
        expect(first.status, isA<PivBindingsStatus$Ok>());

        // With a single YubiKey, the second open should fail with NotPresent.
        final second = api.openDevice();
        expect(second.status, isA<PivBindingsStatus$NotPresent>());

        final closedAll = api.closeAllDevices();
        expect(closedAll, isA<PivBindingsStatus$Ok>());

        final reopened = api.openDevice();
        expect(reopened.status, isA<PivBindingsStatus$Ok>());

        final closed = api.closeDevice(handle: reopened.handle);
        expect(closed, isA<PivBindingsStatus$Ok>());
      },
    );
  });

  group('verifySignature', () {
    test('invalid public key (empty and not PEM)', () {
      final challenge = generateBase64urlNoPad();
      final signature = generateBase64urlNoPad();

      final emptyPk = api.verifySignature(
        publicKey9cPem: '',
        challengeBase64url: challenge,
        signatureDerBase64url: signature,
      );
      expect(emptyPk, isA<PivBindingsStatus$InvalidInput>());

      final badPem = api.verifySignature(
        publicKey9cPem: invalidPem,
        challengeBase64url: challenge,
        signatureDerBase64url: signature,
      );
      expect(badPem, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid challenge (empty and not base64url)', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final piv = api.getPivStatus(handle: opened.handle);
      expect(piv.status, isA<PivBindingsStatus$Ok>());
      expect(piv.pk9cPem, matches(pemRegex));

      final signature = generateBase64urlNoPad();

      final emptyChallenge = api.verifySignature(
        publicKey9cPem: piv.pk9cPem,
        challengeBase64url: '',
        signatureDerBase64url: signature,
      );
      expect(emptyChallenge, isA<PivBindingsStatus$InvalidInput>());

      final invalidChallenge = api.verifySignature(
        publicKey9cPem: piv.pk9cPem,
        challengeBase64url: invalidBase64url,
        signatureDerBase64url: signature,
      );
      expect(invalidChallenge, isA<PivBindingsStatus$InvalidInput>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('invalid signature (empty and not base64url)', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final piv = api.getPivStatus(handle: opened.handle);
      expect(piv.status, isA<PivBindingsStatus$Ok>());
      expect(piv.pk9cPem, matches(pemRegex));

      final challenge = generateBase64urlNoPad();

      final emptySignature = api.verifySignature(
        publicKey9cPem: piv.pk9cPem,
        challengeBase64url: challenge,
        signatureDerBase64url: '',
      );
      expect(emptySignature, isA<PivBindingsStatus$InvalidInput>());

      final invalidSignature = api.verifySignature(
        publicKey9cPem: piv.pk9cPem,
        challengeBase64url: challenge,
        signatureDerBase64url: invalidBase64url,
      );
      expect(invalidSignature, isA<PivBindingsStatus$InvalidInput>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('all ok', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final piv = api.getPivStatus(handle: opened.handle);
      expect(piv.status, isA<PivBindingsStatus$Ok>());
      expect(piv.pk9cPem, matches(pemRegex));

      final challenge = generateBase64urlNoPad();
      final sign = api.signChallenge(
        handle: opened.handle,
        challengeBase64url: challenge,
        pin: testPin,
      );
      expect(sign.status, isA<PivBindingsStatus$Ok>());
      expect(sign.signatureDerBase64url, matches(base64UrlNoPadRegex));

      final verify = api.verifySignature(
        publicKey9cPem: piv.pk9cPem,
        challengeBase64url: challenge,
        signatureDerBase64url: sign.signatureDerBase64url,
      );
      expect(verify, isA<PivBindingsStatus$Ok>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });

  group('getPivStatus', () {
    test('invalid handle', () {
      final pivStatus = api.getPivStatus(handle: invalidHandle);
      expect(pivStatus.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test('has9c/has9d true, PEMs valid', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final pivStatus = api.getPivStatus(handle: opened.handle);
      expect(pivStatus.status, isA<PivBindingsStatus$Ok>());
      expect(pivStatus.has9c, isTrue);
      expect(pivStatus.has9d, isTrue);

      expect(pivStatus.pk9cPem, matches(pemRegex));

      expect(pivStatus.pk9dPem, matches(pemRegex));

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });

  group('signChallenge', () {
    test('invalid handle', () {
      final challenge = generateBase64urlNoPad();
      final sign = api.signChallenge(
        handle: invalidHandle,
        challengeBase64url: challenge,
        pin: null,
      );
      expect(sign.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test('challenge invalid format', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final sign = api.signChallenge(
        handle: opened.handle,
        challengeBase64url: invalidBase64url,
        pin: testPin,
      );
      expect(sign.status, isA<PivBindingsStatus$InvalidInput>());

      const empty = '';
      final sign2 = api.signChallenge(
        handle: opened.handle,
        challengeBase64url: empty,
        pin: testPin,
      );
      expect(sign2.status, isA<PivBindingsStatus$InvalidInput>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test(
      'normal signature with PIN',
      () {
        final opened = api.openDevice();
        expect(opened.status, isA<PivBindingsStatus$Ok>());

        final challenge = generateBase64urlNoPad();
        final sign = api.signChallenge(
          handle: opened.handle,
          challengeBase64url: challenge,
          pin: testPin,
        );
        expect(sign.status, isA<PivBindingsStatus$Ok>());
        expect(sign.signatureDerBase64url, matches(base64UrlNoPadRegex));

        final closed = api.closeDevice(handle: opened.handle);
        expect(closed, isA<PivBindingsStatus$Ok>());
      },
    );
  });

  group('getPivSlot9cPolicy', () {
    test('invalid handle', () {
      final policy = api.getPivSlot9cPolicy(handle: invalidHandle);
      expect(policy.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test('all ok', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final policy = api.getPivSlot9cPolicy(handle: opened.handle);
      expect(policy.status, isA<PivBindingsStatus$Ok>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });

  group('getPivSlot9dPolicy', () {
    test('invalid handle', () {
      final policy = api.getPivSlot9dPolicy(handle: invalidHandle);
      expect(policy.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test('all ok', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final policy = api.getPivSlot9dPolicy(handle: opened.handle);
      expect(policy.status, isA<PivBindingsStatus$Ok>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });

  group('wrapAesForRecipients', () {
    late String validPkPem;

    setUp(() {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final pivStatus = api.getPivStatus(handle: opened.handle);
      validPkPem = pivStatus.pk9dPem;

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('zero recipients', () {
      final envelopes = api.wrapAesForRecipients(recipientsPk9dPem: []);
      expect(envelopes.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('one recipient, empty key', () {
      final envelopes = api.wrapAesForRecipients(recipientsPk9dPem: ['']);
      expect(envelopes.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('two recipients, second empty', () {
      final envelopes = api.wrapAesForRecipients(
        recipientsPk9dPem: [validPkPem, ''],
      );
      expect(envelopes.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('one recipient, invalid pem', () {
      final envelopes = api.wrapAesForRecipients(
        recipientsPk9dPem: [invalidPem],
      );
      expect(envelopes.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('two recipients, second invalid pem', () {
      final envelopes = api.wrapAesForRecipients(
        recipientsPk9dPem: [validPkPem, invalidPem],
      );
      expect(envelopes.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('all ok: one recipient', () {
      final envelopes = api.wrapAesForRecipients(
        recipientsPk9dPem: [validPkPem],
      );
      expect(envelopes.status, isA<PivBindingsStatus$Ok>());
      expect(envelopes.aesEnvelopes.length, 1);

      final envelope = envelopes.aesEnvelopes.first;
      expect(envelope.ephemeralPublicKeyPem, matches(pemRegex));
      expect(envelope.wrappedAes, matches(base64UrlNoPadRegex));
    });

    test('all ok: two recipients', () {
      final envelopes = api.wrapAesForRecipients(
        recipientsPk9dPem: [validPkPem, validPkPem],
      );
      expect(envelopes.status, isA<PivBindingsStatus$Ok>());
      expect(envelopes.aesEnvelopes.length, 2);

      for (final envelope in envelopes.aesEnvelopes) {
        expect(envelope.ephemeralPublicKeyPem, matches(pemRegex));
        expect(envelope.wrappedAes, matches(base64UrlNoPadRegex));
      }
    });
  });

  group('encryptMessage', () {
    late String validPk9dPem;
    late BindingsHandle validHandle;

    setUp(() {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final pivStatus = api.getPivStatus(handle: opened.handle);
      validPk9dPem = pivStatus.pk9dPem;
      validHandle = opened.handle;
    });

    tearDown(() {
      final closed = api.closeDevice(handle: validHandle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    AesEnvelope wrapForSelf() {
      final wrap = api.wrapAesForRecipients(recipientsPk9dPem: [validPk9dPem]);
      expect(wrap.status, isA<PivBindingsStatus$Ok>());
      expect(wrap.aesEnvelopes.length, 1);
      return wrap.aesEnvelopes.first;
    }

    test('empty json', () {
      final envelope = AesEnvelope(
        ephemeralPublicKeyPem: '',
        wrappedAes: '',
      );
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('empty ephemeral public key pem', () {
      final envelope = AesEnvelope(
        ephemeralPublicKeyPem: '',
        wrappedAes: wrapForSelf().wrappedAes,
      );
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('empty wrapped aes', () {
      final envelope = AesEnvelope(
        ephemeralPublicKeyPem: wrapForSelf().ephemeralPublicKeyPem,
        wrappedAes: '',
      );
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid wrapped aes', () {
      final envelope = AesEnvelope(
        ephemeralPublicKeyPem: wrapForSelf().ephemeralPublicKeyPem,
        wrappedAes: invalidBase64url,
      );
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid ephemeral public key pem', () {
      final envelope = AesEnvelope(
        ephemeralPublicKeyPem: invalidPem,
        wrappedAes: wrapForSelf().wrappedAes,
      );
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid handle', () {
      final envelope = wrapForSelf();
      final encrypted = api.encryptMessage(
        handle: invalidHandle,
        aesEnvelope: envelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test(
      'empty plaintext and invalid base64url plaintext',
      () {
        final envelope = wrapForSelf();
        final encryptedEmpty = api.encryptMessage(
          handle: validHandle,
          aesEnvelope: envelope,
          plaintextBase64url: '',
          pin: testPin,
        );
        expect(encryptedEmpty.status, isA<PivBindingsStatus$InvalidInput>());

        final encryptedInvalid = api.encryptMessage(
          handle: validHandle,
          aesEnvelope: envelope,
          plaintextBase64url: invalidBase64url,
          pin: testPin,
        );
        expect(encryptedInvalid.status, isA<PivBindingsStatus$InvalidInput>());
      },
    );

    test('all ok', () {
      final envelope = wrapForSelf();
      final plaintext = generateBase64urlNoPad();
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: envelope,
        plaintextBase64url: plaintext,
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$Ok>());
      expect(encrypted.messageEnvelope.nonce, matches(base64UrlNoPadRegex));
      expect(
        encrypted.messageEnvelope.ciphertext,
        matches(base64UrlNoPadRegex),
      );
      expect(encrypted.messageEnvelope.tag, matches(base64UrlNoPadRegex));
    });
  });

  group('decryptMessage', () {
    late String validPk9dPem;
    late BindingsHandle validHandle;
    late AesEnvelope validAesEnvelope;
    late MessageEnvelope validMessageEnvelope;
    late String validPlaintextBase64url;

    setUp(() {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());
      validHandle = opened.handle;

      final pivStatus = api.getPivStatus(handle: validHandle);
      expect(pivStatus.status, isA<PivBindingsStatus$Ok>());
      validPk9dPem = pivStatus.pk9dPem;

      final wrap = api.wrapAesForRecipients(recipientsPk9dPem: [validPk9dPem]);
      expect(wrap.status, isA<PivBindingsStatus$Ok>());
      validAesEnvelope = wrap.aesEnvelopes.first;

      validPlaintextBase64url = generateBase64urlNoPad();
      final encrypted = api.encryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        plaintextBase64url: validPlaintextBase64url,
        pin: testPin,
      );
      expect(encrypted.status, isA<PivBindingsStatus$Ok>());
      validMessageEnvelope = encrypted.messageEnvelope;
    });

    tearDown(() {
      final closed = api.closeDevice(handle: validHandle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('empty json', () {
      final message = MessageEnvelope(
        nonce: '',
        ciphertext: '',
        tag: '',
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('empty nonce', () {
      final message = MessageEnvelope(
        nonce: '',
        ciphertext: validMessageEnvelope.ciphertext,
        tag: validMessageEnvelope.tag,
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('empty ciphertext', () {
      final message = MessageEnvelope(
        nonce: validMessageEnvelope.nonce,
        ciphertext: '',
        tag: validMessageEnvelope.tag,
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('empty tag', () {
      final message = MessageEnvelope(
        nonce: validMessageEnvelope.nonce,
        ciphertext: validMessageEnvelope.ciphertext,
        tag: '',
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid nonce', () {
      final message = MessageEnvelope(
        nonce: invalidBase64url,
        ciphertext: validMessageEnvelope.ciphertext,
        tag: validMessageEnvelope.tag,
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid ciphertext', () {
      final message = MessageEnvelope(
        nonce: validMessageEnvelope.nonce,
        ciphertext: invalidBase64url,
        tag: validMessageEnvelope.tag,
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid tag', () {
      final message = MessageEnvelope(
        nonce: validMessageEnvelope.nonce,
        ciphertext: validMessageEnvelope.ciphertext,
        tag: invalidBase64url,
      );
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: message,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidInput>());
    });

    test('invalid handle', () {
      final decrypted = api.decryptMessage(
        handle: invalidHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: validMessageEnvelope,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$InvalidHandle>());
    });

    test('all ok', () {
      final decrypted = api.decryptMessage(
        handle: validHandle,
        aesEnvelope: validAesEnvelope,
        messageEnvelope: validMessageEnvelope,
        pin: testPin,
      );
      expect(decrypted.status, isA<PivBindingsStatus$Ok>());
      expect(decrypted.plaintextBase64url, matches(base64UrlNoPadRegex));
      expect(
        decrypted.plaintextBase64url,
        equals(validPlaintextBase64url),
      );
    });
  });

  group('device authenticate', () {
    test('empty pin', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final auth = api.authenticateDevice(
        handle: opened.handle,
        pin: '',
      );
      expect(auth, isA<PivBindingsStatus$PinRequired>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('wrong pin', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final auth = api.authenticateDevice(
        handle: opened.handle,
        pin: 'wrong-pin',
      );
      expect(auth, isA<PivBindingsStatus$PinRequired>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });

    test('valid pin and follow-up ops with cached auth', () {
      final opened = api.openDevice();
      expect(opened.status, isA<PivBindingsStatus$Ok>());

      final piv9cPolicy = api.getPivSlot9cPolicy(handle: opened.handle);
      expect(piv9cPolicy.status, isA<PivBindingsStatus$Ok>());
      expect(piv9cPolicy.pinPolicy, equals(PinPolicy.always()));

      final piv9dPolicy = api.getPivSlot9dPolicy(handle: opened.handle);
      expect(piv9dPolicy.status, isA<PivBindingsStatus$Ok>());
      expect(piv9dPolicy.pinPolicy, equals(PinPolicy.once()));

      final auth = api.authenticateDevice(
        handle: opened.handle,
        pin: testPin,
      );
      expect(auth, isA<PivBindingsStatus$Ok>());

      // sign challenge with pin, because 9c policy is always
      final challenge = generateBase64urlNoPad();
      final sign = api.signChallenge(
        handle: opened.handle,
        challengeBase64url: challenge,
        pin: testPin,
      );
      expect(sign.status, isA<PivBindingsStatus$Ok>());

      // prepare envelopes for self
      final piv = api.getPivStatus(handle: opened.handle);
      expect(piv.status, isA<PivBindingsStatus$Ok>());

      final wrap = api.wrapAesForRecipients(recipientsPk9dPem: [piv.pk9dPem]);
      expect(wrap.status, isA<PivBindingsStatus$Ok>());
      final aesEnvelope = wrap.aesEnvelopes.first;

      // encrypt without passing pin explicitly
      final encrypted = api.encryptMessage(
        handle: opened.handle,
        aesEnvelope: aesEnvelope,
        plaintextBase64url: generateBase64urlNoPad(),
        pin: null,
      );
      expect(encrypted.status, isA<PivBindingsStatus$Ok>());

      // decrypt without passing pin explicitly
      final decrypted = api.decryptMessage(
        handle: opened.handle,
        aesEnvelope: aesEnvelope,
        messageEnvelope: encrypted.messageEnvelope,
        pin: null,
      );
      expect(decrypted.status, isA<PivBindingsStatus$Ok>());

      final closed = api.closeDevice(handle: opened.handle);
      expect(closed, isA<PivBindingsStatus$Ok>());
    });
  });
}
