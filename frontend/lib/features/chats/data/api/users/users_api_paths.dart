abstract interface class UsersApiPaths {
  String userInfoByNicknamePath(String nickname);

  String userInfoByIdPath(String id);
}

final class UsersApiPathsImpl implements UsersApiPaths {
  @override
  String userInfoByNicknamePath(String nickname) =>
      'api/v1/user/user/$nickname';

  @override
  String userInfoByIdPath(String id) => 'api/v1/user/user/id/$id';
}
