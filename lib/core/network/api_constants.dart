import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  // Auth endpoints
  static const String login = '/login';

  // Driver Profile & Shift Status
  static const String driverProfile = '/driver/profile';
  static const String driverStatus = '/driver/status';
  static const String driverLocation = '/driver/location';

  // Driver Orders & Delivery Lifecycle (Driver-Scoped)
  static const String driverActiveOrders = '/driver/orders/active';
  static String driverOrderDetails(int orderId) => '/driver/orders/$orderId';
  static String updateOrderStatus(int orderId) => '/driver/orders/$orderId/status';
}
