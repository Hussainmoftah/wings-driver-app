import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../location/data/repositories/location_repository_impl.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../orders/data/driver_order_model.dart';
import '../../../orders/data/repositories/orders_repository_impl.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import 'driver_home_state.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  final ProfileRepository _profileRepository;
  final OrdersRepository _ordersRepository;
  final AuthRepository _authRepository;
  final LocationRepository _locationRepository;
  Timer? _pollTimer;

  DriverHomeCubit({
    ProfileRepository? profileRepository,
    OrdersRepository? ordersRepository,
    AuthRepository? authRepository,
    LocationRepository? locationRepository,
  })  : _profileRepository = profileRepository ?? ProfileRepositoryImpl(),
        _ordersRepository = ordersRepository ?? OrdersRepositoryImpl(),
        _authRepository = authRepository ?? AuthRepositoryImpl(),
        _locationRepository = locationRepository ?? LocationRepositoryImpl(),
        super(const DriverHomeState());

  Future<void> loadHomeData() async {
    emit(state.copyWith(status: DriverHomeStatus.loading));
    await _fetchData();
    _startPolling();
  }

  Future<void> _fetchData() async {
    try {
      final profile = await _profileRepository.getProfile();

      DriverOrderModel? activeOrder;
      try {
        final activeOrders = await _ordersRepository.getActiveOrders();
        if (activeOrders.isNotEmpty) {
          activeOrder = activeOrders.first;
        }
      } catch (e) {
        debugPrint('⚠️ [Driver Active Orders Fetch] Failed to load active orders: $e');
      }

      double earnings = 0.0;
      int completedTrips = 0;
      double cod = 0.0;
      double deposit = 0.0;
      double capacity = 0.0;

      try {
        final finResp = await ApiService.get('/driver/financials');
        if (finResp.statusCode == 200 && finResp.data != null && finResp.data['data'] != null) {
          final finData = finResp.data['data'];
          final earningsObj = finData['earnings'] is Map ? finData['earnings'] : null;
          final custodyObj = finData['collateral_and_custody'] is Map ? finData['collateral_and_custody'] : null;
          
          earnings = (earningsObj?['total_delivery_earnings'] as num?)?.toDouble() 
              ?? (finData['delivery_earnings'] as num?)?.toDouble() ?? 0.0;
          completedTrips = (earningsObj?['today_completed_trips'] as num?)?.toInt() 
              ?? (finData['completed_trips_count'] as num?)?.toInt() ?? 0;
          cod = (custodyObj?['current_cash_custody'] as num?)?.toDouble() 
              ?? (finData['cod_custody'] as num?)?.toDouble() ?? 0.0;
          deposit = (custodyObj?['deposit_amount'] as num?)?.toDouble() 
              ?? (finData['deposit_amount'] as num?)?.toDouble() ?? 0.0;
          capacity = (custodyObj?['remaining_capacity'] as num?)?.toDouble() 
              ?? (finData['remaining_deposit_capacity'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint('⚠️ [Driver Financials Fetch] Error: $e');
      }

      emit(state.copyWith(
        status: DriverHomeStatus.loaded,
        profile: profile,
        activeOrder: activeOrder,
        clearActiveOrder: activeOrder == null,
        todayEarnings: earnings,
        completedOrdersCount: completedTrips,
        codCustody: cod,
        depositAmount: deposit,
        remainingDepositCapacity: capacity,
        shiftHours: 0.0,
        acceptanceRate: 100.0,
        errorMessage: null,
      ));

      if (profile.isOnline) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    } on UnauthorizedException {
      debugPrint('🔒 [Driver Session] 401 Unauthorized - Session expired.');
      _pollTimer?.cancel();
      await _authRepository.logout();
      emit(state.copyWith(
        status: DriverHomeStatus.unauthenticated,
        errorMessage: 'انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول.',
      ));
    } on ForbiddenException catch (e) {
      debugPrint('⛔ [Driver Session] 403 Forbidden - ${e.message}');
      emit(state.copyWith(
        status: DriverHomeStatus.error,
        errorMessage: e.message,
      ));
    } on ServerException catch (e) {
      debugPrint('⚠️ [Driver Session] Server error: ${e.message}');
      emit(state.copyWith(
        errorMessage: 'خطأ في خادم وينجز، جاري إعادة المحاولة...',
      ));
    } on NetworkException {
      debugPrint('⚠️ [Driver Home Cubit] Network/Connection Error');
      emit(state.copyWith(
        errorMessage: 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.',
      ));
    } catch (e) {
      debugPrint('⚠️ [Driver Home Cubit] Unexpected error: $e');
      emit(state.copyWith(
        errorMessage: 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.',
      ));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (state.profile?.isOnline != true) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (isClosed) return;
      if (state.profile?.isOnline != true) {
        _pollTimer?.cancel();
        return;
      }
      await _fetchData();
    });
  }

  Future<void> toggleDuty(bool isOnline) async {
    emit(state.copyWith(isUpdatingStatus: true));

    try {
      final updatedProfile = await _profileRepository.updateDutyStatus(isOnline);
      final mergedProfile = state.profile?.copyWith(
        isOnline: updatedProfile.isOnline,
        operationalStatus: updatedProfile.operationalStatus,
        statusLabel: updatedProfile.statusLabel,
      ) ?? updatedProfile;

      emit(state.copyWith(
        profile: mergedProfile,
        isUpdatingStatus: false,
      ));

      if (isOnline) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    } catch (e) {
      debugPrint('⚠️ [Driver Duty Toggle] Error: $e');
      final targetStatus = isOnline ? 'online' : 'offline';
      final fallbackProfile = state.profile?.copyWith(
        isOnline: isOnline,
        operationalStatus: targetStatus,
        statusLabel: isOnline ? 'متصل ومتاح' : 'غير متصل',
      );

      emit(state.copyWith(
        profile: fallbackProfile,
        isUpdatingStatus: false,
      ));

      if (isOnline) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    }
  }

  Future<void> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  }) async {
    if (state.profile?.isOnline != true) return;

    try {
      await _locationRepository.updateLocation(
        latitude,
        longitude,
        heading: heading,
        accuracy: accuracy,
      );
    } catch (e) {
      debugPrint('⚠️ [Driver GPS Telemetry] Update failed: $e');
    }
  }

  Future<void> updateOrderStatus(String newStatus, int orderId) async {
    emit(state.copyWith(isUpdatingStatus: true));

    try {
      await _ordersRepository.updateOrderStatus(
        orderId,
        newStatus,
        reason: 'تحديث مسار التوصيل من تطبيق السائق',
      );
      debugPrint('✅ [Driver Status Update] Successfully updated order $orderId to $newStatus');
    } catch (e) {
      debugPrint('⚠️ [Driver Status Update] Error: $e');
    }

    if (newStatus == 'delivered' || newStatus == 'completed') {
      emit(state.copyWith(
        clearActiveOrder: true,
        todayEarnings: state.todayEarnings + (state.activeOrder?.deliveryFee ?? 10.0),
        completedOrdersCount: state.completedOrdersCount + 1,
        isUpdatingStatus: false,
      ));
      await _fetchData();
    } else {
      final updatedOrder = DriverOrderModel(
        id: state.activeOrder?.id ?? orderId,
        orderNumber: state.activeOrder?.orderNumber ?? '#WNG-$orderId',
        status: newStatus,
        subtotal: state.activeOrder?.subtotal ?? 0.0,
        deliveryFee: state.activeOrder?.deliveryFee ?? 10.0,
        total: state.activeOrder?.total ?? 0.0,
        customerName: state.activeOrder?.customerName,
        customerPhone: state.activeOrder?.customerPhone,
        customerAddress: state.activeOrder?.customerAddress,
        customerLat: state.activeOrder?.customerLat,
        customerLng: state.activeOrder?.customerLng,
        restaurantName: state.activeOrder?.restaurantName,
        restaurantPhone: state.activeOrder?.restaurantPhone,
        restaurantAddress: state.activeOrder?.restaurantAddress,
        restaurantLat: state.activeOrder?.restaurantLat,
        restaurantLng: state.activeOrder?.restaurantLng,
        items: state.activeOrder?.items ?? [],
        createdAt: state.activeOrder?.createdAt,
      );

      emit(state.copyWith(
        activeOrder: updatedOrder,
        isUpdatingStatus: false,
      ));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
