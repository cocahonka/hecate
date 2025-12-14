abstract interface class AuthApiPaths {
  String get initLoginPath;

  String get verifyLoginPath;

  String get initRegisterPath;

  String get verifyRegisterPath;

  String get refreshTokenPath;
}

final class AuthApiPathsImpl implements AuthApiPaths {
  @override
  String get initLoginPath => 'user/login/init';

  @override
  String get verifyLoginPath => 'user/login/verify';

  @override
  String get initRegisterPath => 'user/register/init';

  @override
  String get verifyRegisterPath => 'user/register/verify';

  @override
  String get refreshTokenPath => 'user/login/refresh';
}
