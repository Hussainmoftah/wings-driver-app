import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'api_logger.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  static String? _authToken;
  static Future<bool>? _refreshInFlight;

  static const String _accessKey = 'auth_token';
  static const String _refreshKey = 'refresh_token';

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
            _authToken = prefs.getString(_accessKey);
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // توكن الوصول انتهى: نجدده بتوكن التجديد ونعيد الطلب مرة واحدة
          final request = response.requestOptions;
          if (response.statusCode == 401 &&
              request.extra['retried'] != true &&
              !_isAuthPath(request.path) &&
              await refreshSession()) {
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $_authToken';
            try {
              return handler.resolve(await dio.fetch(request));
            } on DioException catch (e) {
              return handler.reject(e);
            }
          }
          return handler.next(response);
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

  /// يحفظ زوج التوكنات (بعد الدخول أو التجديد) في الذاكرة والتخزين المحلي
  static Future<void> saveSession(
    String accessToken,
    String? refreshToken,
  ) async {
    _authToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshKey, refreshToken);
    }
  }

  static Future<void> clearSession() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static bool _isAuthPath(String path) =>
      path.endsWith('/login') || path.endsWith('/auth/refresh');

  /// يجدد زوج التوكنات. الطلبات المتزامنة التي ترجع 401 تنتظر نفس عملية التجديد.
  static Future<bool> refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  static Future<bool> _doRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    // النسخ القديمة من التطبيق لم تحفظ توكن تجديد: التوكن القديم يُقبل للتجديد مرة واحدة
    final refreshToken =
        prefs.getString(_refreshKey) ?? prefs.getString(_accessKey);
    if (refreshToken == null) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(
            ApiConstants.refreshToken,
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $refreshToken',
              },
            ),
          );
      final data = response.data;
      if (data is Map &&
          data['token'] is String &&
          data['refresh_token'] is String) {
        await saveSession(
          data['token'] as String,
          data['refresh_token'] as String,
        );
        return true;
      }
    } on DioException catch (e) {
      // توكن التجديد مرفوض (منتهٍ أو أُلغي): الجلسة انتهت، والـ 401 يصل للشاشة فتعيد للدخول
      if (e.response?.statusCode == 401) await clearSession();
    }
    return false;
  }
}
