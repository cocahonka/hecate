import 'package:meta/meta.dart';

@immutable
sealed class PivBindingsStatus {
  final String message;

  int get code;

  PivBindingsStatus(this.message);

  factory PivBindingsStatus.fromCode(int code, String message) =>
      switch (code) {
        0 => PivBindingsStatus.ok(message),
        1 => PivBindingsStatus.notPresent(message),
        2 => PivBindingsStatus.transient(message),
        3 => PivBindingsStatus.invalidHandle(message),
        4 => PivBindingsStatus.pinRequired(message),
        5 => PivBindingsStatus.invalidInput(message),
        6 => PivBindingsStatus.slotEmpty(message),
        7 => PivBindingsStatus.unknownPolicy(message),
        8 => PivBindingsStatus.internalError(message),
        _ => throw FormatException(
          'Invalid PivBindingsStatus code',
          code,
        ),
      };

  factory PivBindingsStatus.ok(String message) = PivBindingsStatus$Ok._;
  factory PivBindingsStatus.notPresent(String message) =
      PivBindingsStatus$NotPresent._;
  factory PivBindingsStatus.transient(String message) =
      PivBindingsStatus$Transient._;
  factory PivBindingsStatus.invalidHandle(String message) =
      PivBindingsStatus$InvalidHandle._;
  factory PivBindingsStatus.pinRequired(String message) =
      PivBindingsStatus$PinRequired._;
  factory PivBindingsStatus.invalidInput(String message) =
      PivBindingsStatus$InvalidInput._;
  factory PivBindingsStatus.slotEmpty(String message) =
      PivBindingsStatus$SlotEmpty._;
  factory PivBindingsStatus.unknownPolicy(String message) =
      PivBindingsStatus$UnknownPolicy._;
  factory PivBindingsStatus.internalError(String message) =
      PivBindingsStatus$InternalError._;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PivBindingsStatus &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;
}

final class PivBindingsStatus$Ok extends PivBindingsStatus {
  @override
  int get code => 0;

  PivBindingsStatus$Ok._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$Ok('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$NotPresent extends PivBindingsStatus {
  @override
  int get code => 1;

  PivBindingsStatus$NotPresent._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$NotPresent('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$Transient extends PivBindingsStatus {
  @override
  int get code => 2;

  PivBindingsStatus$Transient._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$Transient('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$InvalidHandle extends PivBindingsStatus {
  @override
  int get code => 3;

  PivBindingsStatus$InvalidHandle._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$InvalidHandle('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$PinRequired extends PivBindingsStatus {
  @override
  int get code => 4;

  PivBindingsStatus$PinRequired._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$PinRequired('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$InvalidInput extends PivBindingsStatus {
  @override
  int get code => 5;

  PivBindingsStatus$InvalidInput._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$InvalidInput('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$SlotEmpty extends PivBindingsStatus {
  @override
  int get code => 6;

  PivBindingsStatus$SlotEmpty._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$SlotEmpty('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$UnknownPolicy extends PivBindingsStatus {
  @override
  int get code => 7;

  PivBindingsStatus$UnknownPolicy._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$UnknownPolicy('
      'message: $message, '
      'code: $code'
      ')';
}

final class PivBindingsStatus$InternalError extends PivBindingsStatus {
  @override
  int get code => 8;

  PivBindingsStatus$InternalError._(super.message);

  @override
  String toString() =>
      r'PivBindingsStatus$InternalError('
      'message: $message, '
      'code: $code'
      ')';
}
