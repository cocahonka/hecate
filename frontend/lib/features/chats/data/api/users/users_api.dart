import 'package:dio/dio.dart';

import 'package:hecate/features/chats/data/api/users/users_api_paths.dart';
import 'package:hecate/features/chats/data/api/users/users_responses.dart';

abstract interface class UsersApi {
  Future<GetUserResponse> getUserByNickname({
    required String nickname,
  });
}

final class UsersApiImpl implements UsersApi {
  final Dio _dio;
  final UsersApiPaths _paths;

  UsersApiImpl({
    required Dio dio,
    required UsersApiPaths paths,
  }) : _dio = dio,
       _paths = paths;

  @override
  Future<GetUserResponse> getUserByNickname({
    required String nickname,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.userByNicknamePath(nickname),
    );
    final data = response.data!;
    return GetUserResponse.fromJson(data);
  }
}
