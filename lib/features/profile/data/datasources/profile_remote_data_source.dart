import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateDutyStatus(String status);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.driverProfile);

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message: response.data?['message'] ?? 'ليس لديك صلاحية للوصول لملف السائق.',
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'خطأ في جلب بيانات السائق.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw const UnauthorizedException();
        } else if (e.response?.statusCode == 403) {
          throw ForbiddenException(
            message: e.response?.data?['message'] ?? 'غير مصرح.',
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

  @override
  Future<Map<String, dynamic>> updateDutyStatus(String status) async {
    try {
      final response = await _dio.post(
        ApiConstants.driverStatus,
        data: {'status': status},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message: response.data?['message'] ?? 'غير مصرح بتعديل الحالة.',
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'فشل تحديث حالة الوردية.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw const UnauthorizedException();
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
