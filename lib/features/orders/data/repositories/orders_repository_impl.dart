import '../../data/driver_order_model.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;

  OrdersRepositoryImpl({OrdersRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? OrdersRemoteDataSourceImpl();

  @override
  Future<List<DriverOrderModel>> getActiveOrders() async {
    final responseData = await _remoteDataSource.getActiveOrders();
    final rawList = responseData['data'] as List<dynamic>? ?? [];
    return rawList
        .map((json) => DriverOrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DriverOrderModel> getOrderDetails(int orderId) async {
    final responseData = await _remoteDataSource.getOrderDetails(orderId);
    final orderJson = responseData['data'] as Map<String, dynamic>;
    return DriverOrderModel.fromJson(orderJson);
  }

  @override
  Future<void> updateOrderStatus(int orderId, String newStatus, {String? reason}) async {
    await _remoteDataSource.updateOrderStatus(orderId, newStatus, reason: reason);
  }
}
