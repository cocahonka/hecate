// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:piv_bindings/piv_bindings.dart';

String b64urlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');
String b64urlNormalize(String s) => s.padRight((s.length + 3) ~/ 4 * 4, '=');
List<int> b64urlNoPadDecode(String s) => base64Url.decode(b64urlNormalize(s));

void main() async {
  const dylibName = String.fromEnvironment(
    'BINDINGS_DYLIB_NAME',
  );
  final lib = DynamicLibrary.open(dylibName);
  final piv = PivBindings(library: lib);

  // 1. Open device
  final open = piv.openDevice();
  if (open.status is! PivBindingsStatus$Ok) {
    print('device_open failed: ${open.status}');
    return;
  }
  final handle = open.handle;
  print('device_open OK, handle=${handle.handle}');

  // 2. Optional PIN
  stdout.write('Enter PIV PIN (press Enter to skip): ');
  final pinInput = stdin.readLineSync();
  if (pinInput != null && pinInput.isNotEmpty) {
    final authStatus = piv.authenticateDevice(handle: handle, pin: pinInput);
    print('device_authenticate: $authStatus');
  }

  // 3. PIV status
  final pivStatus = piv.getPivStatus(handle: handle);
  print('has_9c=${pivStatus.has9c} has_9d=${pivStatus.has9d}');

  // 4. 9c policies
  final slot9cPolicy = piv.getPivSlot9cPolicy(handle: handle);
  print(
    '9c policies: pin=${slot9cPolicy.pinPolicy} touch=${slot9cPolicy.touchPolicy}',
  );

  // 5. Sign challenge + verify
  final random = Random.secure();
  final challenge = List<int>.generate(32, (_) => random.nextInt(256));
  final challengeB64 = b64urlNoPad(challenge);
  final needPinForSign = slot9cPolicy.pinPolicy is PinPolicy$Always;
  final sign = piv.signChallenge(
    handle: handle,
    challengeBase64url: challengeB64,
    pin: needPinForSign ? pinInput : null,
  );
  print('sign_challenge: ${sign.status}');
  if (pivStatus.pk9cPem.isNotEmpty) {
    final verify = piv.verifySignature(
      publicKey9cPem: pivStatus.pk9cPem,
      challengeBase64url: challengeB64,
      signatureDerBase64url: sign.signatureDerBase64url,
    );
    print('verify_signature_es256: $verify');
  }

  // 6. Wrap AES for recipients (use our own 9d)
  if (pivStatus.pk9dPem.isNotEmpty) {
    final wrap = piv.wrapAesForRecipients(
      recipientsPk9dPem: [pivStatus.pk9dPem],
    );
    print('wrap_aes_for_recipients: ${wrap.status}');
    if (wrap.aesEnvelopes.isNotEmpty) {
      final aesEnvelope = wrap.aesEnvelopes.first;
      const plaintext = 'hello world';
      final plaintextB64 = b64urlNoPad(utf8.encode(plaintext));

      final enc = piv.encryptMessage(
        handle: handle,
        aesEnvelope: aesEnvelope,
        plaintextBase64url: plaintextB64,
        pin: null,
      );
      print('encrypt_message: ${enc.status}');

      final dec = piv.decryptMessage(
        handle: handle,
        aesEnvelope: aesEnvelope,
        messageEnvelope: enc.messageEnvelope,
        pin: null,
      );
      print('decrypt_message: ${dec.status}');
      if (dec.status is PivBindingsStatus$Ok) {
        final bytes = b64urlNoPadDecode(dec.plaintextBase64url);
        print('decrypted: ${utf8.decode(bytes)}');
      }
    }
  }

  // 7. Close device
  final closeStatus = piv.closeDevice(handle: handle);
  print('device_close: $closeStatus');
}
