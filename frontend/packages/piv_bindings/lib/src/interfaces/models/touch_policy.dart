import 'package:meta/meta.dart';

@immutable
sealed class TouchPolicy {
  int get code;

  TouchPolicy();

  factory TouchPolicy.fromCode(int code) => switch (code) {
    0 => TouchPolicy.never(),
    1 => TouchPolicy.always(),
    2 => TouchPolicy.cached(),
    _ => throw FormatException(
      'Invalid TouchPolicy code',
      code,
    ),
  };

  factory TouchPolicy.never() = TouchPolicy$Never._;
  factory TouchPolicy.always() = TouchPolicy$Always._;
  factory TouchPolicy.cached() = TouchPolicy$Cached._;

  @override
  int get hashCode => Object.hash(runtimeType, code);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchPolicy &&
          runtimeType == other.runtimeType &&
          code == other.code;
}

final class TouchPolicy$Never extends TouchPolicy {
  @override
  int get code => 0;

  TouchPolicy$Never._();

  @override
  String toString() =>
      r'TouchPolicy$Never('
      'code: $code'
      ')';
}

final class TouchPolicy$Always extends TouchPolicy {
  @override
  int get code => 1;

  TouchPolicy$Always._();

  @override
  String toString() =>
      r'TouchPolicy$Always('
      'code: $code'
      ')';
}

final class TouchPolicy$Cached extends TouchPolicy {
  @override
  int get code => 2;

  TouchPolicy$Cached._();

  @override
  String toString() =>
      r'TouchPolicy$Cached('
      'code: $code'
      ')';
}
