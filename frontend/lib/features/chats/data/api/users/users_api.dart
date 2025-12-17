import 'package:dio/dio.dart';

import 'package:hecate/features/chats/data/api/users/users_api_paths.dart';
import 'package:hecate/features/chats/data/api/users/users_responses.dart';

abstract interface class UsersApi {
  Future<GetUserResponse> getUserInfoByNickname({
    required String nickname,
  });

  Future<GetUserResponse> getUserInfoById({
    required String id,
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
  Future<GetUserResponse> getUserInfoByNickname({
    required String nickname,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.userInfoByNicknamePath(nickname),
    );
    final data = response.data!;
    return GetUserResponse.fromJson(data);
  }

  @override
  Future<GetUserResponse> getUserInfoById({
    required String id,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      _paths.userInfoByIdPath(id),
    );
    final data = response.data!;
    return GetUserResponse.fromJson(data);
  }
}
