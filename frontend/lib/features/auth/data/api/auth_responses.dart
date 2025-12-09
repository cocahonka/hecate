import 'package:meta/meta.dart';

@immutable
final class InitLoginResponse {
  final String challenge;

  InitLoginResponse({
    required this.challenge,
  });

  factory InitLoginResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'challenge': final String challenge,
        } =>
          InitLoginResponse(
            challenge: challenge,
          ),
        _ => throw FormatException('Invalid initLogin response: $json'),
      };
}

@immutable
final class VerifyLoginResponse {
  final String accessToken;
  final String refreshToken;

  VerifyLoginResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory VerifyLoginResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'access_token': final String accessToken,
          'refresh_token': final String refreshToken,
        } =>
          VerifyLoginResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        _ => throw FormatException('Invalid verifyLogin response: $json'),
      };
}

@immutable
final class InitRegisterResponse {
  final String challenge;

  InitRegisterResponse({
    required this.challenge,
  });

  factory InitRegisterResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'challenge': final String challenge,
        } =>
          InitRegisterResponse(
            challenge: challenge,
          ),
        _ => throw FormatException('Invalid initRegister response: $json'),
      };
}

@immutable
final class VerifyRegisterResponse {
  final bool success;

  VerifyRegisterResponse({
    required this.success,
  });

  factory VerifyRegisterResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'success': final bool success,
        } =>
          VerifyRegisterResponse(success: success),
        _ => throw FormatException('Invalid verifyRegister response: $json'),
      };
}

@immutable
final class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, Object?> json) =>
      switch (json) {
        {
          'access_token': final String accessToken,
          'refresh_token': final String refreshToken,
        } =>
          RefreshTokenResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        _ => throw FormatException('Invalid refreshToken response: $json'),
      };
}
