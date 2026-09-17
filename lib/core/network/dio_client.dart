import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  static String? _authToken;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _authToken = prefs.getString('auth_token');
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          debugPrint('🌐 [Driver Dio REQ] ${options.method} -> ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [Driver Dio RESP] [${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('❌ [Driver Dio ERR] ${error.message} on ${error.requestOptions.path}');
          return handler.next(error);
        },
      ),
    );
  }

  static void setToken(String token) {
    _authToken = token;
  }

  static String? getToken() {
    return _authToken;
  }

  static void clearToken() {
    _authToken = null;
  }
}
