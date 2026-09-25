import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';
import '../models/driver_notification_model.dart';

class DriverNotificationService {
  static final DriverNotificationService _instance = DriverNotificationService._internal();
  factory DriverNotificationService() => _instance;
  DriverNotificationService._internal();

  /// جلب عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('⚠️ [DriverNotificationService] Error fetching unread count: $e');
    }
    return 0;
  }

  /// جلب قائمة الإشعارات
  Future<List<DriverNotificationItem>> getNotifications({
    int page = 1,
    int perPage = 30,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }

      final response = await ApiService.get('/notifications', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        return list.map((item) => DriverNotificationItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [DriverNotificationService] Error fetching notifications: $e');
    }
    return [];
  }

  /// تعليم إشعار كمقروء
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiService.put('/notifications/$notificationId/read', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [DriverNotificationService] Error marking as read: $e');
      return false;
    }
  }

  /// تعليم كافة الإشعارات كمقروءة
  Future<bool> markAllAsRead() async {
    try {
      final response = await ApiService.put('/notifications/read-all', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [DriverNotificationService] Error marking all as read: $e');
      return false;
    }
  }

  /// تسجيل توكن الجهاز للإشعارات السحابية
  Future<bool> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      final response = await ApiService.post('/notifications/device-token', {
        'token': token,
        'platform': platform,
        'device_model': 'Mobile Device',
        'app_version': '1.0.0',
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [DriverNotificationService] Error registering device token: $e');
      return false;
    }
  }
}
