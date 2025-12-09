abstract interface class AuthApiPaths {
  String get initLogin;

  String get verifyLogin;

  String get initRegister;

  String get verifyRegister;

  String get refreshToken;
}

final class AuthApiPathsImpl implements AuthApiPaths {
  @override
  String get initLogin => const String.fromEnvironment('API_INIT_LOGIN');

  @override
  String get verifyLogin => const String.fromEnvironment('API_VERIFY_LOGIN');

  @override
  String get initRegister => const String.fromEnvironment('API_INIT_REGISTER');

  @override
  String get verifyRegister =>
      const String.fromEnvironment('API_VERIFY_REGISTER');

  @override
  String get refreshToken => const String.fromEnvironment('API_REFRESH_TOKEN');
}
