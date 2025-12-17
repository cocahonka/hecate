abstract interface class UsersApiPaths {
  String userByNicknamePath(String nickname);
}

final class UsersApiPathsImpl implements UsersApiPaths {
  @override
  String userByNicknamePath(String nickname) => 'api/v1/user/user/$nickname';
}
