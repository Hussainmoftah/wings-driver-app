import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
          message: response.data?['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        );
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message: response.data?['message'] ?? 'الحساب غير نشط أو محظور.',
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'فشل تسجيل الدخول.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw UnauthorizedException(
            message: e.response?.data?['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          );
        } else if (e.response?.statusCode == 403) {
          throw ForbiddenException(
            message: e.response?.data?['message'] ?? 'الحساب غير نشط أو محظور.',
          );
        }
        throw ServerException(
          message: e.response?.data?['message'] ?? 'خطأ في الخادم.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const NetworkException();
    }
  }
}
