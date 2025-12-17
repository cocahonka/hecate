import 'package:dio/dio.dart';

import 'package:hecate/features/auth/data/api/auth_api_paths.dart';
import 'package:hecate/features/auth/data/api/auth_responses.dart';

abstract interface class AuthApi {
  Future<InitLoginResponse> initLogin({
    required String nickname,
  });

  Future<VerifyLoginResponse> verifyLogin({
    required String nickname,
    required String signature,
  });

  Future<InitRegisterResponse> initRegister({
    required String nickname,
  });

  Future<VerifyRegisterResponse> verifyRegister({
    required String nickname,
    required String pub9c,
    required String pub9d,
    required String signedChallenge,
  });

  Future<RefreshTokenResponse> refreshToken({
    required String refreshToken,
    required String nickname,
  });
}

final class AuthApiImpl implements AuthApi {
  AuthApiImpl({
    required Dio dio,
    required AuthApiPaths paths,
  }) : _dio = dio,
       _paths = paths;

  final Dio _dio;
  final AuthApiPaths _paths;

  @override
  Future<InitLoginResponse> initLogin({
    required String nickname,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.initLoginPath,
      data: {
        'nickname': nickname,
      },
    );
    final data = response.data!;
    return InitLoginResponse.fromJson(data);
  }

  @override
  Future<VerifyLoginResponse> verifyLogin({
    required String nickname,
    required String signature,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.verifyLoginPath,
      data: {
        'nickname': nickname,
        'signature': signature,
      },
    );
    final data = response.data!;
    return VerifyLoginResponse.fromJson(data);
  }

  @override
  Future<InitRegisterResponse> initRegister({
    required String nickname,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.initRegisterPath,
      data: {
        'nickname': nickname,
      },
    );
    final data = response.data!;
    return InitRegisterResponse.fromJson(data);
  }

  @override
  Future<VerifyRegisterResponse> verifyRegister({
    required String nickname,
    required String pub9c,
    required String pub9d,
    required String signedChallenge,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.verifyRegisterPath,
      data: {
        'nickname': nickname,
        'pub9c': pub9c,
        'pub9d': pub9d,
        'signed_challenge': signedChallenge,
      },
    );
    final data = response.data!;
    return VerifyRegisterResponse.fromJson(data);
  }

  @override
  Future<RefreshTokenResponse> refreshToken({
    required String refreshToken,
    required String nickname,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      _paths.refreshTokenPath,
      data: {
        'refresh_token': refreshToken,
        'nickname': nickname,
      },
    );
    final data = response.data!;
    return RefreshTokenResponse.fromJson(data);
  }
}
