import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'api_logger.dart';

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
          return handler.next(options);
        },
      ),
    );

    // يُضاف أخيراً ليرى الطلب بترويسته النهائية بعد إضافة التوكن.
    dio.interceptors.add(ApiLogger(tag: 'Driver API'));
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
