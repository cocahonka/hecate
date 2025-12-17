import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:l/l.dart';

abstract interface class LoggerInterceptor implements Interceptor {}

final class LoggerInterceptorImpl extends Interceptor
    implements LoggerInterceptor {
  LoggerInterceptorImpl();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final method = options.method;
    final path = options.uri.path;
    final query = options.uri.query.isEmpty ? '-' : options.uri.query;
    final body = _serializeData(options.data);

    l.i('Dio request | $method | $path | $query | $body');

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final code = response.statusCode ?? 0;
    final path = response.requestOptions.uri.path;
    final body = _serializeData(response.data);

    l.i('Dio response | $code | $path | $body');

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final code = err.response?.statusCode;
    final path = err.requestOptions.uri.path;
    final summary = err.message ?? err.error?.toString() ?? 'Unknown Dio error';

    l.e(
      'Dio error | ${code ?? '-'} | $path | $summary',
      err.stackTrace,
    );

    handler.next(err);
  }

  String _serializeData(Object? data) {
    if (data == null) {
      return '-';
    }

    try {
      if (data is Map<String, Object?> || data is List<Object?>) {
        return jsonEncode(data);
      }
    } on Object {
      // ignore
    }

    return data.toString();
  }
}
