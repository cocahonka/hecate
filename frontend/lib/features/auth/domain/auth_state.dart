import 'package:meta/meta.dart';

@immutable
sealed class AuthState {
  String? get nickname;

  AuthState();

  factory AuthState.unauthenticated({
    String? nickname,
  }) = AuthState$Unauthenticated;

  factory AuthState.authenticated({
    required String nickname,
  }) = AuthState$Authenticated;

  @override
  int get hashCode => Object.hash(
    nickname,
    runtimeType,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthState &&
            runtimeType == other.runtimeType &&
            nickname == other.nickname;
  }
}

final class AuthState$Unauthenticated extends AuthState {
  @override
  final String? nickname;

  AuthState$Unauthenticated({
    this.nickname,
  });
}

final class AuthState$Authenticated extends AuthState {
  @override
  final String nickname;

  AuthState$Authenticated({
    required this.nickname,
  });
}
