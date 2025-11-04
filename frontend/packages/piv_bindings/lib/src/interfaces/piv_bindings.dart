// ignore_for_file: comment_references

import 'dart:ffi';

import 'package:piv_bindings/src/implementations/golang/piv_bindings.dart';
import 'package:piv_bindings/src/interfaces/models/models.dart';

typedef OpenDeviceResult = ({PivBindingsStatus status, BindingsHandle handle});

typedef GetPivStatusResult = ({
  PivBindingsStatus status,
  bool has9c,
  bool has9d,
  String pk9cPem,
  String pk9dPem,
});

typedef SignChallengeResult = ({
  PivBindingsStatus status,
  String signatureDerBase64url,
});

typedef WrapAesForRecipientsResult = ({
  PivBindingsStatus status,
  List<AesEnvelope> aesEnvelopes,
});

typedef EncryptMessageResult = ({
  PivBindingsStatus status,
  MessageEnvelope messageEnvelope,
});

typedef DecryptMessageResult = ({
  PivBindingsStatus status,
  String plaintextBase64url,
});

typedef PivSlot9cPolicyResult = ({
  PivBindingsStatus status,
  PinPolicy pinPolicy,
  TouchPolicy touchPolicy,
});

/// Wrapper over a native session handle returned by the bindings.
///
/// The numeric [handle] is valid only when the originating call returned
/// a successful [PivBindingsStatus]. Always pass this handle back to the
/// API methods from the same [PivBindings] instance.
extension type BindingsHandle(int handle) {}

/// High-level API for the YubiKey PIV bindings.
///
/// The implementation delegates to a dynamically loaded library that exposes
/// a stable C ABI. All methods return a [PivBindingsStatus] as part of their
/// result indicating success or the specific error condition. Unless noted,
/// strings are encoded as base64url without padding and public keys are PEM
/// SPKI.
abstract interface class PivBindings {
  factory PivBindings({
    required DynamicLibrary library,
  }) = PivBindings$GolangImpl;

  /// Open the first available PIV device and start a session.
  ///
  /// Returns a tuple with operation [status] and a [handle]. When the status
  /// indicates failure, [handle] will wrap 0.
  ///
  /// Safe to re-open a session after it has been closed.
  OpenDeviceResult openDevice();

  /// Close a previously opened device session and release resources.
  ///
  /// Safe to call even if the session is already closed
  PivBindingsStatus closeDevice({
    required BindingsHandle handle,
  });

  /// Optionally authenticate the device with a PIV PIN for the current session.
  ///
  /// Depending on 9c PIN policy, subsequent calls (e.g. [signChallenge]) may
  /// require passing [pin] explicitly (Always) or be satisfied by the cached
  /// verification (Once). The PIN is never persisted by the bindings.
  PivBindingsStatus authenticateDevice({
    required BindingsHandle handle,
    required String pin,
  });

  /// Query presence of 9c/9d keys and fetch their public keys in PEM format.
  GetPivStatusResult getPivStatus({
    required BindingsHandle handle,
  });

  /// Verify signature on the host using a provided 9c public key.
  ///
  /// All inputs are base64url (no padding). Intended for host-side checks
  /// (does not use the device).
  PivBindingsStatus verifySignature({
    required String publicKey9cPem,
    required String challengeBase64url,
    required String signatureDerBase64url,
  });

  /// Produce an ES256 signature for a base64url challenge using 9c.
  ///
  /// If 9c has PIN policy Always, pass [pin]; otherwise pass null.
  SignChallengeResult signChallenge({
    required BindingsHandle handle,
    required String challengeBase64url,
    required String? pin,
  });

  /// Generate a fresh chat AES key and wrap it for all recipients' 9d keys.
  ///
  /// [recipientsPk9dPem] are recipient 9d public keys in PEM SPKI format.
  /// Returns per-recipient envelopes with an ephemeral public key and the
  /// wrapped AES.
  WrapAesForRecipientsResult wrapAesForRecipients({
    required List<String> recipientsPk9dPem,
  });

  /// Encrypt plaintext using the chat AES derived from [aesEnvelope].
  ///
  /// [plaintextBase64url] is the base64url-encoded plaintext.
  EncryptMessageResult encryptMessage({
    required BindingsHandle handle,
    required AesEnvelope aesEnvelope,
    required String plaintextBase64url,
    required String? pin,
  });

  /// Decrypt a message envelope using the chat AES derived from [aesEnvelope].
  ///
  /// Returns the base64url-encoded plaintext.
  DecryptMessageResult decryptMessage({
    required BindingsHandle handle,
    required AesEnvelope aesEnvelope,
    required MessageEnvelope messageEnvelope,
    required String? pin,
  });

  /// Retrieve 9c PIN and touch policies.
  PivSlot9cPolicyResult getPivSlot9cPolicy({
    required BindingsHandle handle,
  });
}
