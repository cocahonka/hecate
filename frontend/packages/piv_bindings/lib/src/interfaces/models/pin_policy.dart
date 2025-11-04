import 'package:meta/meta.dart';

@immutable
sealed class PinPolicy {
  int get code;

  PinPolicy();

  factory PinPolicy.fromCode(int code) => switch (code) {
    0 => PinPolicy.never(),
    1 => PinPolicy.once(),
    2 => PinPolicy.always(),
    _ => throw FormatException(
      'Invalid PinPolicy code',
      code,
    ),
  };

  factory PinPolicy.never() = PinPolicy$Never._;
  factory PinPolicy.once() = PinPolicy$Once._;
  factory PinPolicy.always() = PinPolicy$Always._;
}

final class PinPolicy$Never extends PinPolicy {
  @override
  int get code => 0;

  PinPolicy$Never._();

  @override
  String toString() =>
      r'PinPolicy$Never('
      'code: $code'
      ')';
}

final class PinPolicy$Once extends PinPolicy {
  @override
  int get code => 1;

  PinPolicy$Once._();

  @override
  String toString() =>
      r'PinPolicy$Once('
      'code: $code'
      ')';
}

final class PinPolicy$Always extends PinPolicy {
  @override
  int get code => 2;

  PinPolicy$Always._();

  @override
  String toString() =>
      r'PinPolicy$Always('
      'code: $code'
      ')';
}
