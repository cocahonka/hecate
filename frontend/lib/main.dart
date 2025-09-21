// ignore_for_file: avoid_print, avoid_private_typedef_functions

import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;

// C struct: typedef struct { int32_t code; const char* msg; } go_piv_bindings_status_t;
final class GoPivStatus extends ffi.Struct {
  @ffi.Int32()
  external int code;

  external ffi.Pointer<pkgffi.Utf8> msg;
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
      ffi.Pointer<ffi.Int32> has9c,
      ffi.Pointer<ffi.Int32> has9d,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> pk9cPem,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> pk9dPem,
    );
typedef _PivStatusDart =
    GoPivStatus Function(
      int handle,
      ffi.Pointer<ffi.Int32> has9c,
      ffi.Pointer<ffi.Int32> has9d,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> pk9cPem,
      ffi.Pointer<ffi.Pointer<pkgffi.Utf8>> pk9dPem,
    );

typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<ffi.Char> s);
typedef _FreeStringDart = void Function(ffi.Pointer<ffi.Char> s);

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

  final outHandle = pkgffi.calloc<ffi.Int64>();
  try {
    final stOpen = deviceOpen(outHandle);
    if (stOpen.code != 0) {
      final msg = stOpen.msg == ffi.Pointer.fromAddress(0)
          ? ''
          : stOpen.msg.toDartString();
      print('device_open failed: code=${stOpen.code} msg=$msg');
      return;
    }

    final handle = outHandle.value;
    print('device_open OK, handle=$handle');

    final has9c = pkgffi.calloc<ffi.Int32>();
    final has9d = pkgffi.calloc<ffi.Int32>();
    final pk9cPtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    final pk9dPtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    try {
      final st = pivStatus(handle, has9c, has9d, pk9cPtr, pk9dPtr);
      if (st.code != 0) {
        final msg = st.msg == ffi.Pointer.fromAddress(0)
            ? ''
            : st.msg.toDartString();
        print('piv_status failed: code=${st.code} msg=$msg');
        return;
      }

      print('has_9c=${has9c.value != 0} has_9d=${has9d.value != 0}');

      final pk9c = pk9cPtr.value;
      if (pk9c.address != 0) {
        final s = pk9c.toDartString();
        print('pk_9c_pem: ${s.isNotEmpty ? s.split('\n').first : s} ...');
        // Free C string
        freeString(pk9c.cast());
      }
      final pk9d = pk9dPtr.value;
      if (pk9d.address != 0) {
        final s = pk9d.toDartString();
        print('pk_9d_pem: ${s.isNotEmpty ? s.split('\n').first : s} ...');
        freeString(pk9d.cast());
      }
    } finally {
      pkgffi.calloc.free(has9c);
      pkgffi.calloc.free(has9d);
      pkgffi.calloc.free(pk9cPtr);
      pkgffi.calloc.free(pk9dPtr);
    }

    final stClose = deviceClose(handle);
    if (stClose.code != 0) {
      final msg = stClose.msg == ffi.Pointer.fromAddress(0)
          ? ''
          : stClose.msg.toDartString();
      print('device_close failed: code=${stClose.code} msg=$msg');
    } else {
      print('device_close OK');
    }
  } finally {
    pkgffi.calloc.free(outHandle);
  }
}
