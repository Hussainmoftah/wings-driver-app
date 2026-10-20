import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../location/data/repositories/location_repository_impl.dart';
import '../../../location/data/services/device_location_service.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../orders/data/driver_order_model.dart';
import '../../../orders/data/repositories/orders_repository_impl.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../notifications/services/driver_notification_service.dart';
import 'driver_home_state.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  final ProfileRepository _profileRepository;
  final OrdersRepository _ordersRepository;
  final AuthRepository _authRepository;
  final LocationRepository _locationRepository;
  final DeviceLocationService _locationService;
  Timer? _pollTimer;
  StreamSubscription<Position>? _positionSub;

  /// البث يصدر كل 10 أمتار، لكن لا نرسل للخادم أكثر من مرة كل 5 ثوانٍ.
  static const Duration _telemetryInterval = Duration(seconds: 5);
  DateTime? _lastTelemetryAt;

  DriverHomeCubit({
    ProfileRepository? profileRepository,
    OrdersRepository? ordersRepository,
    AuthRepository? authRepository,
    LocationRepository? locationRepository,
    DeviceLocationService? locationService,
  }) : _profileRepository = profileRepository ?? ProfileRepositoryImpl(),
       _ordersRepository = ordersRepository ?? OrdersRepositoryImpl(),
       _authRepository = authRepository ?? AuthRepositoryImpl(),
       _locationRepository = locationRepository ?? LocationRepositoryImpl(),
       _locationService = locationService ?? DeviceLocationService(),
       super(const DriverHomeState());

  Future<void> loadHomeData() async {
    emit(state.copyWith(status: DriverHomeStatus.loading));
    await _fetchData();
    _startPolling();
  }

  Future<void> refreshHome() async {
    await _fetchData();
  }

  int _pollTicks = 0;

  Future<void> _fetchData({bool fetchFullFinancials = true}) async {
    try {
      final profileFuture = _profileRepository.getProfile();
      final activeOrdersFuture = _ordersRepository.getActiveOrders().catchError(
        (e) {
          debugPrint('⚠️ [Driver Active Orders Fetch] Failed: $e');
          return <DriverOrderModel>[];
        },
      );
      final notifFuture = DriverNotificationService()
          .getUnreadCount()
          .catchError((_) => 0);
      final finFuture = fetchFullFinancials
          ? () async {
              try {
                return await ApiService.get('/driver/financials');
              } catch (e) {
                debugPrint('⚠️ [Driver Financials Fetch] Error: $e');
                return null;
              }
            }()
          : Future<dynamic>.value(null);

      final results = await Future.wait([
        profileFuture,
        activeOrdersFuture,
        notifFuture,
        finFuture,
      ]);

      final profile = results[0] as dynamic;
      final activeOrders = results[1] as List<DriverOrderModel>;
      final unreadNotifications = results[2] as int;
      final finResp = results[3] as dynamic;

      final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

      double earnings = state.todayEarnings;
      int completedTrips = state.completedOrdersCount;
      double cod = state.codCustody;
      double deposit = state.depositAmount;
      double capacity = state.remainingDepositCapacity;
      double remittance = state.requiredRemittance;
      double payoutDue = state.payoutDue;
      bool rewardEnabled = state.rewardEnabled;
      int rewardEvery = state.rewardEvery;
      int rewardRemaining = state.rewardRemaining;
      int rewardToday = state.rewardTodayDeliveries;
      String rewardValue = state.rewardValueLabel;

      if (finResp != null &&
          finResp.statusCode == 200 &&
          finResp.data != null &&
          finResp.data['data'] != null) {
        final finData = finResp.data['data'];
        final earningsObj = finData['earnings'] is Map
            ? finData['earnings']
            : null;
        final custodyObj = finData['collateral_and_custody'] is Map
            ? finData['collateral_and_custody']
            : null;

        earnings =
            (earningsObj?['total_delivery_earnings'] as num?)?.toDouble() ??
            (finData['delivery_earnings'] as num?)?.toDouble() ??
            0.0;
        completedTrips =
            (earningsObj?['today_completed_trips'] as num?)?.toInt() ??
            (finData['completed_trips_count'] as num?)?.toInt() ??
            0;
        cod =
            (custodyObj?['current_cash_custody'] as num?)?.toDouble() ??
            (finData['cod_custody'] as num?)?.toDouble() ??
            0.0;
        deposit =
            (custodyObj?['deposit_amount'] as num?)?.toDouble() ??
            (finData['deposit_amount'] as num?)?.toDouble() ??
            0.0;
        capacity =
            (custodyObj?['remaining_capacity'] as num?)?.toDouble() ??
            (finData['remaining_deposit_capacity'] as num?)?.toDouble() ??
            0.0;
        remittance =
            (custodyObj?['required_remittance'] as num?)?.toDouble() ?? 0.0;
        payoutDue = (custodyObj?['payout_due'] as num?)?.toDouble() ?? 0.0;

        final reward = earningsObj?['reward_program'];
        if (reward is Map) {
          rewardEnabled = reward['enabled'] == true;
          rewardEvery = (reward['every'] as num?)?.toInt() ?? 0;
          rewardRemaining = (reward['remaining_to_reward'] as num?)?.toInt() ?? 0;
          rewardToday = (reward['today_deliveries'] as num?)?.toInt() ?? 0;
          rewardValue = reward['reward_type'] == 'fixed_amount'
              ? '${((reward['reward_amount'] as num?) ?? 0).toStringAsFixed(2)} د.ل'
              : 'رسوم التوصيل كاملة';
        }
      }

      emit(
        state.copyWith(
          status: DriverHomeStatus.loaded,
          profile: profile,
          activeOrder: activeOrder,
          clearActiveOrder: activeOrder == null,
          todayEarnings: earnings,
          completedOrdersCount: completedTrips,
          codCustody: cod,
          depositAmount: deposit,
          remainingDepositCapacity: capacity,
          requiredRemittance: remittance,
          payoutDue: payoutDue,
          rewardEnabled: rewardEnabled,
          rewardEvery: rewardEvery,
          rewardRemaining: rewardRemaining,
          rewardTodayDeliveries: rewardToday,
          rewardValueLabel: rewardValue,
          shiftHours: 0.0,
          acceptanceRate: 100.0,
          unreadNotificationsCount: unreadNotifications,
          errorMessage: null,
        ),
      );

      if (profile.isOnline) {
        _startPolling();
        await startLocationTracking();
      } else {
        _pollTimer?.cancel();
        await stopLocationTracking();
      }
    } on UnauthorizedException {
      debugPrint('🔒 [Driver Session] 401 Unauthorized - Session expired.');
      _pollTimer?.cancel();
      await _authRepository.logout();
      emit(
        state.copyWith(
          status: DriverHomeStatus.unauthenticated,
          errorMessage: 'انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول.',
        ),
      );
    } on ForbiddenException catch (e) {
      debugPrint('⛔ [Driver Session] 403 Forbidden - ${e.message}');
      emit(
        state.copyWith(status: DriverHomeStatus.error, errorMessage: e.message),
      );
    } on ServerException catch (e) {
      debugPrint('⚠️ [Driver Session] Server error: ${e.message}');
      emit(
        state.copyWith(
          errorMessage: 'خطأ في خادم سديم، جاري إعادة المحاولة...',
        ),
      );
    } on NetworkException {
      debugPrint('⚠️ [Driver Home Cubit] Network/Connection Error');
      emit(
        state.copyWith(
          errorMessage: 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.',
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [Driver Home Cubit] Unexpected error: $e');
      emit(
        state.copyWith(
          errorMessage: 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.',
        ),
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (state.profile?.isOnline != true) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (isClosed) return;
      if (state.profile?.isOnline != true) {
        _pollTimer?.cancel();
        return;
      }
      _pollTicks++;
      // Full financials refreshed every 5 ticks (~30s), active orders & profile refreshed every 6s
      final shouldFetchFin = (_pollTicks % 5 == 0);
      await _fetchData(fetchFullFinancials: shouldFetchFin);
    });
  }

  Future<void> toggleDuty(bool isOnline) async {
    emit(state.copyWith(isUpdatingStatus: true));

    try {
      final updatedProfile = await _profileRepository.updateDutyStatus(
        isOnline,
      );
      final mergedProfile =
          state.profile?.copyWith(
            isOnline: updatedProfile.isOnline,
            operationalStatus: updatedProfile.operationalStatus,
            statusLabel: updatedProfile.statusLabel,
          ) ??
          updatedProfile;

      emit(state.copyWith(profile: mergedProfile, isUpdatingStatus: false));

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

      emit(state.copyWith(profile: fallbackProfile, isUpdatingStatus: false));

      if (isOnline) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    }
  }

  /// يبدأ بثّ الموقع اللحظي: يحدّث الخريطة فورًا ويرسل للخادم بوتيرة مخفّفة.
  Future<void> startLocationTracking() async {
    if (_positionSub != null) return;

    // غياب الـ GPS لا يمنع استخدام التطبيق، لذا نبتلع الخطأ هنا عمدًا.
    final LocationUnavailableReason? blocked;
    try {
      blocked = await _locationService.ensureReady();
    } catch (e, st) {
      debugPrint('📍 [Driver GPS] could not start tracking: $e\n$st');
      return;
    }
    if (blocked != null) {
      debugPrint('📍 [Driver GPS] tracking unavailable: $blocked');
      return;
    }

    // اعرض آخر موقع معروف ريثما تصل أول قراءة من البث.
    final seed = await _locationService.lastKnown();
    if (seed != null && !isClosed) _emitPosition(seed, sendToServer: false);

    _positionSub = _locationService.watchPosition().listen((position) {
      if (isClosed) return;
      _emitPosition(position);
    });
  }

  Future<void> stopLocationTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _lastTelemetryAt = null;
  }

  void _emitPosition(Position position, {bool sendToServer = true}) {
    emit(
      state.copyWith(
        driverLat: position.latitude,
        driverLng: position.longitude,
        driverHeading: position.heading,
      ),
    );

    if (!sendToServer) return;

    final now = DateTime.now();
    if (_lastTelemetryAt != null &&
        now.difference(_lastTelemetryAt!) < _telemetryInterval) {
      return;
    }
    _lastTelemetryAt = now;

    unawaited(
      updateLocation(
        position.latitude,
        position.longitude,
        heading: position.heading,
        accuracy: position.accuracy,
      ),
    );
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
      debugPrint(
        '✅ [Driver Status Update] Successfully updated order $orderId to $newStatus',
      );
    } catch (e) {
      debugPrint('⚠️ [Driver Status Update] Error: $e');
    }

    if (newStatus == 'delivered' || newStatus == 'completed') {
      emit(
        state.copyWith(
          clearActiveOrder: true,
          todayEarnings:
              state.todayEarnings + (state.activeOrder?.deliveryFee ?? 10.0),
          completedOrdersCount: state.completedOrdersCount + 1,
          isUpdatingStatus: false,
        ),
      );
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

      emit(state.copyWith(activeOrder: updatedOrder, isUpdatingStatus: false));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _positionSub?.cancel();
    return super.close();
  }
}
