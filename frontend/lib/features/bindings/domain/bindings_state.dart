import 'package:meta/meta.dart';
import 'package:piv_bindings/piv_bindings.dart';

enum BindingsInconsistentType {
  missingKeys,
  pinRequired,
}

@immutable
sealed class BindingsState {
  BindingsState();

  factory BindingsState.closed() = BindingsState$Closed;
  factory BindingsState.opening() = BindingsState$Opening;
  factory BindingsState.openingError({
    required Object? error,
    required StackTrace? stackTrace,
  }) = BindingsState$OpeningError;
  factory BindingsState.openingFailed({
    required PivBindingsStatus status,
  }) = BindingsState$OpeningFailed;

  factory BindingsState.opened({
    required BindingsHandle handle,
  }) = BindingsState$Opened;
  factory BindingsState.callError({
    required BindingsHandle handle,
    required Object? error,
    required StackTrace? stackTrace,
  }) = BindingsState$CallError;
  factory BindingsState.callFailed({
    required BindingsHandle handle,
    required PivBindingsStatus status,
  }) = BindingsState$CallFailed;
  factory BindingsState.inconsistentState({
    required BindingsHandle handle,
    required BindingsInconsistentType type,
  }) = BindingsState$InconsistentState;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState && runtimeType == other.runtimeType;
}

final class BindingsState$Closed extends BindingsState {
  @override
  String toString() => r'BindingsState$Closed';
}

final class BindingsState$Opening extends BindingsState$Closed {
  @override
  String toString() => r'BindingsState$Opening';
}

final class BindingsState$OpeningError extends BindingsState$Closed {
  final Object? error;
  final StackTrace? stackTrace;

  BindingsState$OpeningError({
    required this.error,
    required this.stackTrace,
  });

  @override
  int get hashCode => Object.hash(
    error,
    stackTrace,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState$OpeningError &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  String toString() =>
      'BindingsState\$OpeningError(error: $error, stackTrace: $stackTrace)';
}

final class BindingsState$OpeningFailed extends BindingsState$Closed {
  final PivBindingsStatus status;

  BindingsState$OpeningFailed({
    required this.status,
  });

  @override
  int get hashCode => status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState$OpeningFailed &&
          runtimeType == other.runtimeType &&
          status == other.status;

  @override
  String toString() => 'BindingsState\$OpeningFailed(status: $status)';
}

final class BindingsState$Opened extends BindingsState {
  final BindingsHandle handle;

  BindingsState$Opened({
    required this.handle,
  });

  @override
  String toString() => 'BindingsState\$Opened(handle: $handle)';
}

final class BindingsState$CallError extends BindingsState$Opened {
  final Object? error;
  final StackTrace? stackTrace;

  BindingsState$CallError({
    required super.handle,
    required this.error,
    required this.stackTrace,
  });

  @override
  int get hashCode => Object.hash(error, stackTrace);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState$CallError &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  String toString() =>
      'BindingsState\$CallError(error: $error, stackTrace: $stackTrace)';
}

final class BindingsState$CallFailed extends BindingsState$Opened {
  final PivBindingsStatus status;

  BindingsState$CallFailed({
    required super.handle,
    required this.status,
  });

  @override
  int get hashCode => status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState$CallFailed &&
          runtimeType == other.runtimeType &&
          status == other.status;

  @override
  String toString() => 'BindingsState\$CallFailed(status: $status)';
}

final class BindingsState$InconsistentState extends BindingsState$Opened {
  final BindingsInconsistentType type;

  BindingsState$InconsistentState({
    required super.handle,
    required this.type,
  });

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingsState$InconsistentState &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  String toString() => 'BindingsState\$InconsistentState(type: $type)';
}
