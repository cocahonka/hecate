// ignore_for_file: avoid_print

import 'dart:ffi';

import 'package:piv_bindings/piv_bindings.dart';

void main() {
  const dylibName = String.fromEnvironment('BINDINGS_DYLIB_NAME');
  final lib = DynamicLibrary.open(dylibName);
  final bindings = PivBindings(library: lib);

  final openResult = bindings.openDevice();
  final handle = openResult.handle;

  final statusResult = bindings.getPivStatus(handle: handle);
  print(statusResult);

  bindings.closeDevice(handle: handle);
}
