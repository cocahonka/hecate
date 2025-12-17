abstract interface class AuthApiPaths {
  String get initLoginPath;

  String get verifyLoginPath;

  String get initRegisterPath;

  String get verifyRegisterPath;

  String get refreshTokenPath;
}

final class AuthApiPathsImpl implements AuthApiPaths {
  @override
  String get initLoginPath => 'api/v1/user/login/init';

  @override
  String get verifyLoginPath => 'api/v1/user/login/verify';

  @override
  String get initRegisterPath => 'api/v1/user/register/init';

  @override
  String get verifyRegisterPath => 'api/v1/user/register/verify';

  @override
  String get refreshTokenPath => 'api/v1/user/login/refresh';
}
