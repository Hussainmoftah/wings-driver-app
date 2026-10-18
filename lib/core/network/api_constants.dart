class ApiConstants {
  ApiConstants._();

  /// عنوان الـ API: سيرفر وينجز افتراضياً على كل المنصات.
  ///
  /// للتشغيل على باك إند محلي أثناء التطوير فقط:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api   (محاكي أندرويد)
  ///   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api  (iOS / ويب)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://169.58.30.135.sslip.io/api',
  );

  // Auth endpoints
  static const String login = '/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/logout';

  // Driver Profile & Shift Status
  static const String driverProfile = '/driver/profile';
  static const String driverStatus = '/driver/status';
  static const String driverLocation = '/driver/location';

  // Driver Orders & Delivery Lifecycle (Driver-Scoped)
  static const String driverActiveOrders = '/driver/orders/active';
  static String driverOrderDetails(int orderId) => '/driver/orders/$orderId';
  static String updateOrderStatus(int orderId) =>
      '/driver/orders/$orderId/status';
}
