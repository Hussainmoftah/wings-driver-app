import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../handover_proof.dart';

abstract class OrdersRemoteDataSource {
  Future<Map<String, dynamic>> getActiveOrders();
  Future<Map<String, dynamic>> getOrderDetails(int orderId);
  Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String newStatus, {
    String? reason,
    PickupCount? pickup,
    DeliveryProof? delivery,
  });
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final Dio _dio;

  OrdersRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  @override
  Future<Map<String, dynamic>> getActiveOrders() async {
    try {
      final response = await _dio.get(ApiConstants.driverActiveOrders);

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message:
              response.data?['message'] ?? 'ليس لديك صلاحية لعرض طلبات السائق.',
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'خطأ في جلب الطلبات النشطة.',
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
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await _dio.get(ApiConstants.driverOrderDetails(orderId));

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message:
              response.data?['message'] ?? 'هذا الطلب غير مسند إليك كسائق.',
        );
      } else if (response.statusCode == 404) {
        throw const NotFoundException(message: 'الطلب غير موجود.');
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'خطأ في جلب تفاصيل الطلب.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw const UnauthorizedException();
        } else if (e.response?.statusCode == 403) {
          throw ForbiddenException(
            message:
                e.response?.data?['message'] ??
                'هذا الطلب غير مسند إليك كسائق.',
          );
        } else if (e.response?.statusCode == 404) {
          throw const NotFoundException(message: 'الطلب غير موجود.');
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
  Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String newStatus, {
    String? reason,
    PickupCount? pickup,
    DeliveryProof? delivery,
  }) async {
    try {
      final fields = <String, dynamic>{
        'status': newStatus,
        'reason': ?reason,
        if (pickup != null) ...{
          'pieces_count': pickup.pieces,
          'drinks_count': pickup.drinks,
          'shortage_note': ?pickup.shortageNote,
        },
        if (delivery != null) ...{
          'photo_skip_reason': ?delivery.skipReason,
          'latitude': ?delivery.latitude,
          'longitude': ?delivery.longitude,
        },
      };
      final photo = delivery?.photo;
      final response = await _dio.post(
        ApiConstants.updateOrderStatus(orderId),
        // صورة الكيس تُرسل ملفاً مع الحقول، وإلا فالطلب JSON كالسابق
        data: photo == null
            ? fields
            : FormData.fromMap({
                ...fields,
                'photo': MultipartFile.fromBytes(photo, filename: 'bag.jpg'),
              }),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw const UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          message:
              response.data?['message'] ?? 'غير مصرح لك بتحديث حالة هذا الطلب.',
        );
      } else if (response.statusCode == 422 &&
          response.data is Map &&
          response.data['code'] == 'pickup_count_mismatch') {
        throw PickupMismatchException.fromResponse(
          Map<String, dynamic>.from(response.data as Map),
        );
      } else if (response.statusCode == 422) {
        throw ValidationException(
          message: response.data?['message'] ?? 'انتقال حالة غير قانوني.',
          errors: response.data?['errors'] as Map<String, dynamic>?,
        );
      } else {
        throw ServerException(
          message: response.data?['message'] ?? 'فشل تحديث حالة الطلب.',
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
        } else if (e.response?.statusCode == 422) {
          throw ValidationException(
            message: e.response?.data?['message'] ?? 'انتقال حالة غير قانوني.',
            errors: e.response?.data?['errors'] as Map<String, dynamic>?,
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
