import 'package:meta/meta.dart';

@immutable
sealed class AuthState {
  AuthState();

  factory AuthState.unauthenticated({
    String? nickname,
  }) = AuthState$Unauthenticated;

  factory AuthState.authenticated({
    required String nickname,
  }) = AuthState$Authenticated;
}

final class AuthState$Unauthenticated extends AuthState {
  final String? nickname;

  AuthState$Unauthenticated({
    this.nickname,
  });

  @override
  int get hashCode => nickname.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState$Unauthenticated && nickname == other.nickname;
}

final class AuthState$Authenticated extends AuthState {
  final String nickname;

  AuthState$Authenticated({
    required this.nickname,
  });

  @override
  int get hashCode => nickname.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState$Authenticated && nickname == other.nickname;
}
