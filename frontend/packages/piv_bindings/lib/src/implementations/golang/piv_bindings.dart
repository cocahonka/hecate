import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:piv_bindings/src/ffi/golang_piv_bindings.ffigen.dart';
import 'package:piv_bindings/src/interfaces/models/models.dart';
import 'package:piv_bindings/src/interfaces/piv_bindings.dart';

/// Implementation of the PivBindings interface using the Golang bindings.
/// Each method corresponds to the following flow:
/// 1. Allocate native memory (only for inputs)
/// 2. Native call
/// 3. Convert to Dart values
/// 4. Free API-returned memory (only for outputs)
/// 5. Free allocated memory
final class PivBindings$GolangImpl implements PivBindings {
  final GeneratedGolangPivBindings _bindings;

  PivBindings$GolangImpl({
    required DynamicLibrary library,
  }) : _bindings = GeneratedGolangPivBindings(library);

  PivBindingsStatus _mapStatus(go_piv_bindings_status_t status) {
    final messagePtr = status.message;
    final messageValue = messagePtr.toDartStringOrEmpty();
    if (messagePtr != nullptr) {
      _bindings.go_piv_bindings_free_string(messagePtr);
    }
    return PivBindingsStatus.fromCode(status.code, messageValue);
  }

  @override
  OpenDeviceResult openDevice() {
    // 1. Allocate native memory
    final outHandlePtr = calloc<go_piv_bindings_handle_t>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_device_open(outHandlePtr);

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final handle = BindingsHandle(outHandlePtr.value);

      return (status: status, handle: handle);
    } finally {
      // 5. Free allocated memory
      calloc.free(outHandlePtr);
    }
  }

  @override
  PivBindingsStatus closeDevice({
    required BindingsHandle handle,
  }) {
    // 2. Native call
    final statusC = _bindings.go_piv_bindings_device_close(handle.handle);

    // 3. Convert to Dart values
    return _mapStatus(statusC);
  }

  @override
  PivBindingsStatus authenticateDevice({
    required BindingsHandle handle,
    required String pin,
  }) {
    // 1. Allocate native memory
    final pinUtf8Ptr = pin.toNativeUtf8();
    final pinCharPtr = pinUtf8Ptr.cast<Char>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_device_authenticate(
        handle.handle,
        pinCharPtr,
      );

      // 3. Convert to Dart values
      return _mapStatus(statusC);
    } finally {
      // 5. Free allocated memory
      malloc.free(pinUtf8Ptr);
    }
  }

  @override
  GetPivStatusResult getPivStatus({required BindingsHandle handle}) {
    // 1. Allocate native memory
    final outHas9cPtr = calloc<Int32>();
    final outHas9dPtr = calloc<Int32>();
    final pk9cPemPtrPtr = calloc<Pointer<Char>>();
    final pk9dPemPtrPtr = calloc<Pointer<Char>>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_piv_status(
        handle.handle,
        outHas9cPtr,
        outHas9dPtr,
        pk9cPemPtrPtr,
        pk9dPemPtrPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final pk9cPemPtr = pk9cPemPtrPtr.value;
      final pk9dPemPtr = pk9dPemPtrPtr.value;
      final pk9cPemValue = pk9cPemPtr.toDartStringOrEmpty();
      final pk9dPemValue = pk9dPemPtr.toDartStringOrEmpty();
      final has9cValue = outHas9cPtr.value != 0;
      final has9dValue = outHas9dPtr.value != 0;

      // 4. Free API-returned memory
      if (pk9cPemPtr != nullptr) {
        _bindings.go_piv_bindings_free_string(pk9cPemPtr);
      }
      if (pk9dPemPtr != nullptr) {
        _bindings.go_piv_bindings_free_string(pk9dPemPtr);
      }

      return (
        status: status,
        has9c: has9cValue,
        has9d: has9dValue,
        pk9cPem: pk9cPemValue,
        pk9dPem: pk9dPemValue,
      );
    } finally {
      // 5. Free allocated memory
      calloc.free(outHas9cPtr);
      calloc.free(outHas9dPtr);
      calloc.free(pk9cPemPtrPtr);
      calloc.free(pk9dPemPtrPtr);
    }
  }

  @override
  PivBindingsStatus verifySignature({
    required String publicKey9cPem,
    required String challengeBase64url,
    required String signatureDerBase64url,
  }) {
    // 1. Allocate native memory
    final pk9cPemUtf8Ptr = publicKey9cPem.toNativeUtf8();
    final challengeUtf8Ptr = challengeBase64url.toNativeUtf8();
    final signatureUtf8Ptr = signatureDerBase64url.toNativeUtf8();
    final pk9cPemCharPtr = pk9cPemUtf8Ptr.cast<Char>();
    final challengeCharPtr = challengeUtf8Ptr.cast<Char>();
    final signatureCharPtr = signatureUtf8Ptr.cast<Char>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_verify_signature_es256(
        pk9cPemCharPtr,
        challengeCharPtr,
        signatureCharPtr,
      );

      // 3. Convert to Dart values
      return _mapStatus(statusC);
    } finally {
      // 5. Free allocated memory
      malloc.free(pk9cPemUtf8Ptr);
      malloc.free(challengeUtf8Ptr);
      malloc.free(signatureUtf8Ptr);
    }
  }

  @override
  SignChallengeResult signChallenge({
    required BindingsHandle handle,
    required String challengeBase64url,
    required String? pin,
  }) {
    // 1. Allocate native memory
    final challengeUtf8Ptr = challengeBase64url.toNativeUtf8();
    final challengeCharPtr = challengeUtf8Ptr.cast<Char>();
    final outSignaturePtrPtr = calloc<Pointer<Char>>();
    final pinUtf8Ptr = pin.toNativeUtf8OrNullptr();
    final pinCharPtr = pinUtf8Ptr.cast<Char>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_sign_challenge(
        handle.handle,
        challengeCharPtr,
        outSignaturePtrPtr,
        pinCharPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final signaturePtr = outSignaturePtrPtr.value;
      final signatureValue = signaturePtr.toDartStringOrEmpty();

      // 4. Free API-returned memory
      if (signaturePtr != nullptr) {
        _bindings.go_piv_bindings_free_string(signaturePtr);
      }

      return (
        status: status,
        signatureDerBase64url: signatureValue,
      );
    } finally {
      // 5. Free allocated memory
      calloc.free(outSignaturePtrPtr);
      malloc.free(challengeUtf8Ptr);
      if (pin != null) {
        malloc.free(pinUtf8Ptr);
      }
    }
  }

  @override
  WrapAesForRecipientsResult wrapAesForRecipients({
    required List<String> recipientsPk9dPem,
  }) {
    // 1. Allocate native memory
    final length = recipientsPk9dPem.length;
    final recipientsArrayPtr = calloc<Pointer<Char>>(length);
    final allocatedRecipientUtf8Ptrs = <Pointer<Utf8>>[];
    for (var i = 0; i < length; i++) {
      final recipientUtf8Ptr = recipientsPk9dPem[i].toNativeUtf8();
      allocatedRecipientUtf8Ptrs.add(recipientUtf8Ptr);
      recipientsArrayPtr[i] = recipientUtf8Ptr.cast<Char>();
    }
    final outAesEnvelopesArrayPtrPtr = calloc<Pointer<Pointer<Char>>>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_wrap_aes_for_recipients(
        recipientsArrayPtr,
        length,
        outAesEnvelopesArrayPtrPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final aesEnvelopesArrayPtr = outAesEnvelopesArrayPtrPtr.value;

      final envelopeJsonStrings = <String>[];
      if (aesEnvelopesArrayPtr != nullptr) {
        for (var i = 0; i < length; i++) {
          final stringPtr = (aesEnvelopesArrayPtr + i).value;
          envelopeJsonStrings.add(stringPtr.toDartStringOrEmpty());
        }

        // 4. Free API-returned memory
        _bindings.go_piv_bindings_free_string_array(
          aesEnvelopesArrayPtr,
          length,
        );
      }

      final envelopes = <AesEnvelope>[];
      for (final jsonString in envelopeJsonStrings) {
        envelopes.add(
          AesEnvelope.fromJson(json.decode(jsonString) as Map<String, Object?>),
        );
      }

      return (
        status: status,
        aesEnvelopes: envelopes,
      );
    } finally {
      // 5. Free allocated memory
      allocatedRecipientUtf8Ptrs.forEach(malloc.free);
      calloc.free(recipientsArrayPtr);
      calloc.free(outAesEnvelopesArrayPtrPtr);
    }
  }

  @override
  EncryptMessageResult encryptMessage({
    required BindingsHandle handle,
    required AesEnvelope aesEnvelope,
    required String plaintextBase64url,
    required String? pin,
  }) {
    // 1. Allocate native memory
    final aesEnvelopeJson = json.encode(aesEnvelope.toJson());
    final aesEnvelopeUtf8Ptr = aesEnvelopeJson.toNativeUtf8();
    final aesEnvelopeCharPtr = aesEnvelopeUtf8Ptr.cast<Char>();
    final plaintextUtf8Ptr = plaintextBase64url.toNativeUtf8();
    final plaintextCharPtr = plaintextUtf8Ptr.cast<Char>();
    final outMessageEnvelopePtrPtr = calloc<Pointer<Char>>();
    final pinUtf8Ptr = pin.toNativeUtf8OrNullptr();
    final pinCharPtr = pinUtf8Ptr.cast<Char>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_encrypt_message(
        handle.handle,
        aesEnvelopeCharPtr,
        plaintextCharPtr,
        outMessageEnvelopePtrPtr,
        pinCharPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final messageEnvelopePtr = outMessageEnvelopePtrPtr.value;
      final messageEnvelopeJson = messageEnvelopePtr.toDartStringOrEmpty();

      // 4. Free API-returned memory
      if (messageEnvelopePtr != nullptr) {
        _bindings.go_piv_bindings_free_string(messageEnvelopePtr);
      }
      final messageEnvelope = MessageEnvelope.fromJson(
        json.decode(messageEnvelopeJson) as Map<String, Object?>,
      );

      return (
        status: status,
        messageEnvelope: messageEnvelope,
      );
    } finally {
      // 5. Free allocated memory
      malloc.free(aesEnvelopeUtf8Ptr);
      malloc.free(plaintextUtf8Ptr);
      if (pin != null) {
        malloc.free(pinUtf8Ptr);
      }
      calloc.free(outMessageEnvelopePtrPtr);
    }
  }

  @override
  DecryptMessageResult decryptMessage({
    required BindingsHandle handle,
    required AesEnvelope aesEnvelope,
    required MessageEnvelope messageEnvelope,
    required String? pin,
  }) {
    // 1. Allocate native memory
    final aesEnvelopeJson = json.encode(aesEnvelope.toJson());
    final messageEnvelopeJson = json.encode(messageEnvelope.toJson());
    final aesEnvelopeUtf8Ptr = aesEnvelopeJson.toNativeUtf8();
    final aesEnvelopeCharPtr = aesEnvelopeUtf8Ptr.cast<Char>();
    final messageEnvelopeUtf8Ptr = messageEnvelopeJson.toNativeUtf8();
    final messageEnvelopeCharPtr = messageEnvelopeUtf8Ptr.cast<Char>();
    final outPlaintextPtrPtr = calloc<Pointer<Char>>();
    final pinUtf8Ptr = pin.toNativeUtf8OrNullptr();
    final pinCharPtr = pinUtf8Ptr.cast<Char>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_decrypt_message(
        handle.handle,
        aesEnvelopeCharPtr,
        messageEnvelopeCharPtr,
        outPlaintextPtrPtr,
        pinCharPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final plaintextPtr = outPlaintextPtrPtr.value;
      final plaintextValue = plaintextPtr.toDartStringOrEmpty();

      // 4. Free API-returned memory
      if (plaintextPtr != nullptr) {
        _bindings.go_piv_bindings_free_string(plaintextPtr);
      }

      return (
        status: status,
        plaintextBase64url: plaintextValue,
      );
    } finally {
      // 5. Free allocated memory
      malloc.free(aesEnvelopeUtf8Ptr);
      malloc.free(messageEnvelopeUtf8Ptr);
      if (pin != null) {
        malloc.free(pinUtf8Ptr);
      }
      calloc.free(outPlaintextPtrPtr);
    }
  }

  @override
  PivSlot9cPolicyResult getPivSlot9cPolicy({required BindingsHandle handle}) {
    // 1. Allocate native memory
    final outPinPolicyPtr = calloc<Int32>();
    final outTouchPolicyPtr = calloc<Int32>();

    try {
      // 2. Native call
      final statusC = _bindings.go_piv_bindings_piv_slot9c_policy(
        handle.handle,
        outPinPolicyPtr,
        outTouchPolicyPtr,
      );

      // 3. Convert to Dart values
      final status = _mapStatus(statusC);
      final pinPolicy = PinPolicy.fromCode(outPinPolicyPtr.value);
      final touchPolicy = TouchPolicy.fromCode(outTouchPolicyPtr.value);

      return (
        status: status,
        pinPolicy: pinPolicy,
        touchPolicy: touchPolicy,
      );
    } finally {
      // 5. Free allocated memory
      calloc.free(outPinPolicyPtr);
      calloc.free(outTouchPolicyPtr);
    }
  }
}

extension _CharPointerExtension on Pointer<Char> {
  String toDartStringOrEmpty() {
    return this == nullptr ? '' : cast<Utf8>().toDartString();
  }
}

extension _NullableStringExtension on String? {
  Pointer<Utf8> toNativeUtf8OrNullptr() {
    if (this case final string?) {
      return string.toNativeUtf8().cast<Utf8>();
    }
    return nullptr;
  }
}
