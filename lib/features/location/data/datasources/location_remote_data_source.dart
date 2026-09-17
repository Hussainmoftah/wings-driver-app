import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';

abstract class LocationRemoteDataSource {
  Future<Map<String, dynamic>> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  });
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio _dio;

  LocationRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  @override
  Future<Map<String, dynamic>> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.driverLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'heading': ?heading,
          'accuracy': ?accuracy,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message: response.data?['message'] ?? 'غير مصرح بتحديث الموقع.',
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'فشل تحديث الموقع.',
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
