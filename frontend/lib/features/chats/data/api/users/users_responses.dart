import 'package:meta/meta.dart';

@immutable
final class GetUserResponse {
  final String id;
  final String nickname;
  final String pub9c;
  final String pub9d;

  GetUserResponse({
    required this.id,
    required this.nickname,
    required this.pub9c,
    required this.pub9d,
  });

  factory GetUserResponse.fromJson(Map<String, Object?> json) => switch (json) {
    {
      'id': final String id,
      'nickname': final String nickname,
      'pub9c': final String pub9c,
      'pub9d': final String pub9d,
    } =>
      GetUserResponse(
        id: id,
        nickname: nickname,
        pub9c: pub9c,
        pub9d: pub9d,
      ),
    _ => throw FormatException('Invalid GetUserResponse: $json'),
  };
}
