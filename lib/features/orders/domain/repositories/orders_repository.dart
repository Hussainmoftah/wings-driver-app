import '../../data/driver_order_model.dart';

abstract class OrdersRepository {
  /// جلب الطلبات النشطة المسندة للسائق
  Future<List<DriverOrderModel>> getActiveOrders();

  /// جلب تفاصيل طلب محدد مع التحقق من الإسناد
  Future<DriverOrderModel> getOrderDetails(int orderId);

  /// تحديث حالة مسار التوصيل (on_the_way / delivered)
  Future<void> updateOrderStatus(int orderId, String newStatus, {String? reason});
}
