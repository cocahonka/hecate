// ignore_for_file: avoid_print, avoid_private_typedef_functions

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart' as pkgffi;

// C struct: typedef struct { int32_t code; const char* message; } go_piv_bindings_status_t;
final class GoPivStatus extends ffi.Struct {
  @ffi.Int32()
  external int code;

  external ffi.Pointer<pkgffi.Utf8> message;
}

typedef _DeviceOpenNative =
    GoPivStatus Function(ffi.Pointer<ffi.Int64> outHandle);
typedef _DeviceOpenDart =
    GoPivStatus Function(ffi.Pointer<ffi.Int64> outHandle);

typedef _DeviceCloseNative = GoPivStatus Function(ffi.Int64 handle);
typedef _DeviceCloseDart = GoPivStatus Function(int handle);

typedef _PivStatusNative =
    GoPivStatus Function(
      ffi.Int64 handle,
      ffi.Pointer<ffi.Int32> outHas9c,
      ffi.Pointer<ffi.Int32> outHas9d,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outPk9cPem,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outPk9dPem,
    );
typedef _PivStatusDart =
    GoPivStatus Function(
      int handle,
      ffi.Pointer<ffi.Int32> outHas9c,
      ffi.Pointer<ffi.Int32> outHas9d,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outPk9cPem,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outPk9dPem,
    );

typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<ffi.Char> s);
typedef _FreeStringDart = void Function(ffi.Pointer<ffi.Char> s);

typedef _DeviceAuthNative =
    GoPivStatus Function(ffi.Int64 handle, ffi.Pointer<ffi.Char> pin);
typedef _DeviceAuthDart =
    GoPivStatus Function(int handle, ffi.Pointer<ffi.Char> pin);

// sign_challenge
typedef _SignNative =
    GoPivStatus Function(
      ffi.Int64 handle,
      ffi.Pointer<pkgffi.Utf8> challengeBase64url,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outSignatureBase64url,
      ffi.Pointer<pkgffi.Utf8> pinUtf8OrNull,
    );
typedef _SignDart =
    GoPivStatus Function(
      int handle,
      ffi.Pointer<pkgffi.Utf8> challengeBase64url,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> outSignatureBase64url,
      ffi.Pointer<pkgffi.Utf8> pinUtf8OrNull,
    );

// verify_signature_es256
typedef _VerifyNative =
    GoPivStatus Function(
      ffi.Pointer<pkgffi.Utf8> publicKey9cPem,
      ffi.Pointer<pkgffi.Utf8> challengeBase64url,
      ffi.Pointer<pkgffi.Utf8> signatureDerBase64url,
    );
typedef _VerifyDart =
    GoPivStatus Function(
      ffi.Pointer<pkgffi.Utf8> publicKey9cPem,
      ffi.Pointer<pkgffi.Utf8> challengeBase64url,
      ffi.Pointer<pkgffi.Utf8> signatureDerBase64url,
    );

// wrap_aes_for_recipients
typedef _WrapRecipientsNative =
    GoPivStatus Function(
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> recipientsPk9dPem,
      ffi.Int32 recipientsCount,
      ffi.Pointer<ffi.Pointer<ffi.Pointer<pkgffi.Utf8>>> outAesEnvelopeJson,
    );
typedef _WrapRecipientsDart =
    GoPivStatus Function(
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> recipientsPk9dPem,
      int recipientsCount,
      ffi.Pointer<ffi.Pointer<ffi.Pointer<pkgffi.Utf8>>> outAesEnvelopeJson,
    );

// free string array
typedef _FreeStringArrayNative =
    ffi.Void Function(
      ffi.Pointer<ffi.Pointer<ffi.Char>> array,
      ffi.Int32 length,
    );
typedef _FreeStringArrayDart =
    void Function(
      ffi.Pointer<ffi.Pointer<ffi.Char>> array,
      int length,
    );

void main() {
  final dylibPath = File(
    '${Directory.current.path}/golang_piv_bindings/go_piv_bindings.dylib',
  ).path;
  if (!File(dylibPath).existsSync()) {
    print('dylib not found at: $dylibPath');
    return;
  }

  final lib = ffi.DynamicLibrary.open(dylibPath);

  final deviceOpen = lib.lookupFunction<_DeviceOpenNative, _DeviceOpenDart>(
    'go_piv_bindings_device_open',
  );
  final deviceClose = lib.lookupFunction<_DeviceCloseNative, _DeviceCloseDart>(
    'go_piv_bindings_device_close',
  );
  final pivStatus = lib.lookupFunction<_PivStatusNative, _PivStatusDart>(
    'go_piv_bindings_piv_status',
  );
  final freeString = lib.lookupFunction<_FreeStringNative, _FreeStringDart>(
    'go_piv_bindings_free_string',
  );
  final deviceAuth = lib.lookupFunction<_DeviceAuthNative, _DeviceAuthDart>(
    'go_piv_bindings_device_authenticate',
  );
  final signChallenge = lib.lookupFunction<_SignNative, _SignDart>(
    'go_piv_bindings_sign_challenge',
  );
  final verifyEs256 = lib.lookupFunction<_VerifyNative, _VerifyDart>(
    'go_piv_bindings_verify_signature_es256',
  );
  final wrapRecipients = lib
      .lookupFunction<_WrapRecipientsNative, _WrapRecipientsDart>(
        'go_piv_bindings_wrap_aes_for_recipients',
      );
  final freeStringArray = lib
      .lookupFunction<_FreeStringArrayNative, _FreeStringArrayDart>(
        'go_piv_bindings_free_string_array',
      );
  // slot9c policy
  final slot9cPolicy = lib
      .lookupFunction<
        GoPivStatus Function(
          ffi.Int64,
          ffi.Pointer<ffi.Int32>,
          ffi.Pointer<ffi.Int32>,
        ),
        GoPivStatus Function(
          int,
          ffi.Pointer<ffi.Int32>,
          ffi.Pointer<ffi.Int32>,
        )
      >('go_piv_bindings_piv_slot9c_policy');

  final outHandle = pkgffi.calloc<ffi.Int64>();
  try {
    final stOpen = deviceOpen(outHandle);
    if (stOpen.code != 0) {
      final msg = stOpen.message == ffi.Pointer.fromAddress(0)
          ? ''
          : stOpen.message.toDartString();
      print('device_open failed: code=${stOpen.code} msg=$msg');
      return;
    }

    final handle = outHandle.value;
    print('device_open OK, handle=$handle');

    // Ask PIN interactively (enter to skip)
    stdout.write('Enter PIV PIN (press Enter to skip): ');
    final pinInput = stdin.readLineSync() ?? '';
    final pinPtr = pinInput.toNativeUtf8();
    try {
      final stAuth = deviceAuth(handle, pinPtr.cast());
      if (stAuth.code != 0) {
        final msg = stAuth.message == ffi.Pointer.fromAddress(0)
            ? ''
            : stAuth.message.toDartString();
        print('device_authenticate: code=${stAuth.code} msg=$msg');
      } else {
        print('device_authenticate OK');
      }
    } finally {
      pkgffi.malloc.free(pinPtr);
    }

    final has9c = pkgffi.calloc<ffi.Int32>();
    final has9d = pkgffi.calloc<ffi.Int32>();
    final pk9cPtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    final pk9dPtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    String? pk9cPemStr;
    String? pk9dPemStr;
    try {
      final st = pivStatus(handle, has9c, has9d, pk9cPtr, pk9dPtr);
      if (st.code != 0) {
        final msg = st.message == ffi.Pointer.fromAddress(0)
            ? ''
            : st.message.toDartString();
        print('piv_status failed: code=${st.code} msg=$msg');
        return;
      }

      print('has_9c=${has9c.value != 0} has_9d=${has9d.value != 0}');

      final pk9c = pk9cPtr.value;
      if (pk9c.address != 0) {
        pk9cPemStr = pk9c.toDartString();
        print(
          'pk_9c_pem: ${pk9cPemStr.isNotEmpty ? pk9cPemStr.split('\n').first : pk9cPemStr} ...',
        );
        // Free C string
        freeString(pk9c.cast());
      }
      final pk9d = pk9dPtr.value;
      if (pk9d.address != 0) {
        final s = pk9d.toDartString();
        pk9dPemStr = s;
        print('pk_9d_pem: ${s.isNotEmpty ? s.split('\n').first : s} ...');
        freeString(pk9d.cast());
      }
    } finally {
      pkgffi.calloc.free(has9c);
      pkgffi.calloc.free(has9d);
      pkgffi.calloc.free(pk9cPtr);
      pkgffi.calloc.free(pk9dPtr);
    }

    // Query 9c policies
    final pinPolicyOut = pkgffi.calloc<ffi.Int32>();
    final touchPolicyOut = pkgffi.calloc<ffi.Int32>();
    int pinPolicyVal = -1;
    int touchPolicyVal = -1;
    try {
      final stPol = slot9cPolicy(handle, pinPolicyOut, touchPolicyOut);
      if (stPol.code == 0) {
        pinPolicyVal = pinPolicyOut.value;
        touchPolicyVal = touchPolicyOut.value;
        print('9c policies: pin=$pinPolicyVal touch=$touchPolicyVal');
      } else {
        final msg = stPol.message == ffi.Pointer.fromAddress(0)
            ? ''
            : stPol.message.toDartString();
        print('slot9c_policy failed: code=${stPol.code} msg=$msg');
      }
    } finally {
      pkgffi.calloc.free(pinPolicyOut);
      pkgffi.calloc.free(touchPolicyOut);
    }

    // Test sign_challenge (ES256)
    final random = Random.secure();
    final challenge = List<int>.generate(32, (_) => random.nextInt(256));
    final challengeB64 = base64Url.encode(challenge).replaceAll('=', '');
    final challengePtr = challengeB64.toNativeUtf8();
    final sigOutPtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    String? sigB64Str;
    try {
      // Pass PIN only if policy requires Always (2)
      final needPinForSign = pinPolicyVal == 2;
      final pinForSign = needPinForSign
          ? pinInput.toNativeUtf8()
          : ffi.Pointer<pkgffi.Utf8>.fromAddress(0);
      try {
        final stSign = signChallenge(
          handle,
          challengePtr,
          sigOutPtr,
          pinForSign,
        );
        if (stSign.code != 0) {
          final msg = stSign.message == ffi.Pointer.fromAddress(0)
              ? ''
              : stSign.message.toDartString();
          print('sign_challenge failed: code=${stSign.code} msg=$msg');
        } else {
          final sigPtr = sigOutPtr.value;
          if (sigPtr.address != 0) {
            sigB64Str = sigPtr.toDartString();
            final head = sigB64Str.length > 16
                ? sigB64Str.substring(0, 16)
                : sigB64Str;
            print('sign_challenge OK, len=${sigB64Str.length} head=$head');
            freeString(sigPtr.cast());
          } else {
            print('sign_challenge returned empty signature');
          }
        }
      } finally {
        if (needPinForSign) {
          // free temporary PIN string used for Always
          // ignore: invalid_use_of_internal_member
          pkgffi.malloc.free(pinForSign);
        }
      }
    } finally {
      pkgffi.malloc.free(challengePtr);
      pkgffi.calloc.free(sigOutPtr);
    }

    // Verify signature with pk9c from piv_status (host-side only)
    if (pk9cPemStr != null && sigB64Str != null) {
      final pkPtr = pk9cPemStr.toNativeUtf8();
      final challPtr = challengeB64.toNativeUtf8();
      final sigPtr = sigB64Str.toNativeUtf8();
      try {
        final stV = verifyEs256(pkPtr, challPtr, sigPtr);
        final msg = stV.message == ffi.Pointer.fromAddress(0)
            ? ''
            : stV.message.toDartString();
        if (stV.code == 0) {
          print('verify_signature_es256 OK (piv_status pk)');
        } else {
          print(
            'verify_signature_es256 failed (piv_status pk): code=${stV.code} msg=$msg',
          );
        }
      } finally {
        pkgffi.malloc.free(pkPtr);
        pkgffi.malloc.free(challPtr);
        pkgffi.malloc.free(sigPtr);
      }
    }

    // demonstrate wrap_aes_for_recipients using pk_9d (single recipient)
    if (pk9dPemStr != null && pk9dPemStr.isNotEmpty) {
      print('wrap_aes_for_recipients demo...');
      // prepare recipients array (1 recipient)
      final recipients = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>(1);
      final pk9dPemPtr = pk9dPemStr.toNativeUtf8();
      recipients[0] = pk9dPemPtr;
      final outArrayPtr = pkgffi
          .calloc<ffi.Pointer<ffi.Pointer<pkgffi.Utf8>>>();
      try {
        final stWrap = wrapRecipients(recipients, 1, outArrayPtr);
        if (stWrap.code != 0) {
          final msg = stWrap.message == ffi.Pointer.fromAddress(0)
              ? ''
              : stWrap.message.toDartString();
          print('wrap_aes_for_recipients failed: code=${stWrap.code} msg=$msg');
        } else {
          final outArray = outArrayPtr.value;
          if (outArray.address != 0) {
            final envPtr = outArray[0];
            final envJson = envPtr.toDartString();
            final formatted = const JsonEncoder.withIndent(
              '  ',
            ).convert(jsonDecode(envJson));
            print('aes_envelope_json[0]:\n$formatted');
            // free array and its strings via C helper
            freeStringArray(outArray.cast(), 1);
          } else {
            print('wrap returned null array');
          }
        }
      } finally {
        // free inputs and holder
        pkgffi.malloc.free(pk9dPemPtr);
        pkgffi.calloc.free(recipients);
        pkgffi.calloc.free(outArrayPtr);
      }
    }

    final stClose = deviceClose(handle);
    if (stClose.code != 0) {
      final msg = stClose.message == ffi.Pointer.fromAddress(0)
          ? ''
          : stClose.message.toDartString();
      print('device_close failed: code=${stClose.code} msg=$msg');
    } else {
      print('device_close OK');
    }
  } finally {
    pkgffi.calloc.free(outHandle);
  }
}
