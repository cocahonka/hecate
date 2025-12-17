import 'package:meta/meta.dart';

@immutable
final class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokens &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken;
}
