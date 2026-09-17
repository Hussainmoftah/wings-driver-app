import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_client.dart';

class ApiService {
  static final Dio _dio = DioClient().dio;

  /// حفظ التوكن في الذاكرة المحلية وتحديث عميل Dio
  static Future<void> saveToken(String token) async {
    DioClient.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// استرجاع التوكن المخزن محلياً
  static Future<String?> getToken() async {
    final memoryToken = DioClient.getToken();
    if (memoryToken != null && memoryToken.isNotEmpty) {
      return memoryToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final diskToken = prefs.getString('auth_token');
    if (diskToken != null && diskToken.isNotEmpty) {
      DioClient.setToken(diskToken);
    }
    return diskToken;
  }

  /// تسجيل الخروج وحذف التوكن وتفريغ الجلسة بالكامل
  static Future<void> logout() async {
    DioClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// التحقق مما إذا كان هناك توكن محفوظ
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> post(
    String endpoint,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> put(
    String endpoint,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
