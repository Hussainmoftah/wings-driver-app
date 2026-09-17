import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wings_driver/core/errors/exceptions.dart';
import 'package:wings_driver/core/network/api_constants.dart';
import 'package:wings_driver/core/network/dio_client.dart';
import 'package:wings_driver/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wings_driver/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wings_driver/features/home/presentation/cubit/driver_home_cubit.dart';
import 'package:wings_driver/features/home/presentation/cubit/driver_home_state.dart';
import 'package:wings_driver/features/location/data/datasources/location_remote_data_source.dart';
import 'package:wings_driver/features/location/data/repositories/location_repository_impl.dart';
import 'package:wings_driver/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:wings_driver/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:wings_driver/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:wings_driver/features/profile/data/repositories/profile_repository_impl.dart';

// ==========================================
// FAKE REMOTE DATA SOURCES
// ==========================================

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  String? lastEmail;
  String? lastPassword;
  Map<String, dynamic>? mockResponse;
  Exception? exceptionToThrow;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockResponse ??
        {
          'status': 'success',
          'token': 'sanctum_driver_token_abc123',
          'user': {'id': 4, 'name': 'Captain Ahmed', 'role': 'driver', 'phone': '0910000004'},
        };
  }
}

class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  Map<String, dynamic>? profileResponse;
  Map<String, dynamic>? dutyResponse;
  Exception? exceptionToThrow;
  String? lastTargetStatus;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return profileResponse ??
        {
          'status': 'success',
          'data': {
            'user_id': 4,
            'name': 'Captain Ahmed',
            'phone': '0910000004',
            'is_online': true,
            'operational_status': 'online',
            'status_label': 'متصل ومتاح',
            'vehicle_type': 'دراجة نارية',
            'license_number': '5-12345',
            'current_latitude': 32.8872,
            'current_longitude': 13.1913,
            'is_location_fresh': true,
            'has_active_order': true,
            'active_order_id': 101,
            'active_order_status': 'ready',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> updateDutyStatus(String status) async {
    lastTargetStatus = status;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return dutyResponse ??
        {
          'status': 'success',
          'data': {
            'user_id': 4,
            'operational_status': status,
            'is_online': status == 'online',
          },
        };
  }
}

class FakeOrdersRemoteDataSource implements OrdersRemoteDataSource {
  Map<String, dynamic>? activeOrdersResponse;
  Map<String, dynamic>? orderDetailsResponse;
  Exception? exceptionToThrow;
  int? lastUpdatedOrderId;
  String? lastUpdatedStatus;
  String? lastUpdatedReason;

  @override
  Future<Map<String, dynamic>> getActiveOrders() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return activeOrdersResponse ??
        {
          'status': 'success',
          'data': [
            {
              'id': 101,
              'order_number': 'WNG-101',
              'status': 'ready',
              'subtotal': '45.00',
              'delivery_fee': '10.00',
              'total': '55.00',
              'customer': {'name': 'Ali Customer', 'phone': '0911111111', 'address': 'Tripoli City Center', 'latitude': 32.8872, 'longitude': 13.1913},
              'delivery_address': {'title': 'Tripoli City Center', 'street': 'Main St', 'latitude': 32.8872, 'longitude': 13.1913},
              'restaurant': {'name': 'Wings Burger', 'phone': '0922222222', 'address': 'Gargarish St', 'latitude': 32.8750, 'longitude': 13.1750},
              'items': [
                {'name': 'Double Burger', 'quantity': 2, 'price': '22.50'},
              ],
            },
          ],
        };
  }

  @override
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return orderDetailsResponse ??
        {
          'status': 'success',
          'data': {
            'id': orderId,
            'order_number': 'WNG-$orderId',
            'status': 'ready',
            'subtotal': '45.00',
            'delivery_fee': '10.00',
            'total': '55.00',
            'customer': {'name': 'Ali Customer', 'phone': '0911111111', 'address': 'Tripoli City Center', 'latitude': 32.8872, 'longitude': 13.1913},
            'delivery_address': {'title': 'Tripoli City Center', 'street': 'Main St', 'latitude': 32.8872, 'longitude': 13.1913},
            'restaurant': {'name': 'Wings Burger', 'phone': '0922222222', 'address': 'Gargarish St', 'latitude': 32.8750, 'longitude': 13.1750},
            'items': [
              {'name': 'Double Burger', 'quantity': 2, 'price': '22.50'},
            ],
          },
        };
  }

  @override
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String newStatus, {String? reason}) async {
    lastUpdatedOrderId = orderId;
    lastUpdatedStatus = newStatus;
    lastUpdatedReason = reason;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return {'status': 'success', 'message': 'تم تحديث الحالة بنجاح'};
  }
}

class FakeLocationRemoteDataSource implements LocationRemoteDataSource {
  double? lastLat;
  double? lastLng;
  double? lastHeading;
  double? lastAccuracy;
  int callCount = 0;
  Exception? exceptionToThrow;

  @override
  Future<Map<String, dynamic>> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  }) async {
    callCount++;
    lastLat = latitude;
    lastLng = longitude;
    lastHeading = heading;
    lastAccuracy = accuracy;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return {'status': 'success', 'message': 'Location updated'};
  }
}

// ==========================================
// MAIN TESTS
// ==========================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.clearToken();
  });

  group('Phase 3 — Item 22: Repository Tests (Mapping, Errors, DTOs, Nulls)', () {
    test('AuthRepositoryImpl: Successful driver login maps and stores token', () async {
      final fakeDataSource = FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(remoteDataSource: fakeDataSource);

      final result = await repository.login('driver1@wings.ly', 'password');

      expect(result['token'], equals('sanctum_driver_token_abc123'));
      expect(await repository.hasValidToken(), isTrue);
      expect(await repository.getToken(), equals('sanctum_driver_token_abc123'));
      expect(DioClient.getToken(), equals('sanctum_driver_token_abc123'));
    });

    test('AuthRepositoryImpl: Non-driver role login throws ForbiddenException', () async {
      final fakeDataSource = FakeAuthRemoteDataSource()
        ..mockResponse = {
          'status': 'success',
          'token': 'customer_token_999',
          'user': {'id': 9, 'role': 'customer'},
        };
      final repository = AuthRepositoryImpl(remoteDataSource: fakeDataSource);

      expect(
        () => repository.login('customer@wings.ly', 'password'),
        throwsA(isA<ForbiddenException>()),
      );
      expect(await repository.hasValidToken(), isFalse);
    });

    test('ProfileRepositoryImpl: getProfile maps DTO correctly with full fields and null fallback', () async {
      final fakeDataSource = FakeProfileRemoteDataSource();
      final repository = ProfileRepositoryImpl(remoteDataSource: fakeDataSource);

      final profile = await repository.getProfile();

      expect(profile.userId, equals(4));
      expect(profile.name, equals('Captain Ahmed'));
      expect(profile.phone, equals('0910000004'));
      expect(profile.isOnline, isTrue);
      expect(profile.operationalStatus, equals('online'));
      expect(profile.statusLabel, equals('متصل ومتاح'));
      expect(profile.vehicleType, equals('دراجة نارية'));
      expect(profile.licenseNumber, equals('5-12345'));
      expect(profile.currentLatitude, equals(32.8872));
      expect(profile.currentLongitude, equals(13.1913));
      expect(profile.isLocationFresh, isTrue);
      expect(profile.hasActiveOrder, isTrue);
      expect(profile.activeOrderId, equals(101));
    });

    test('ProfileRepositoryImpl: updateDutyStatus maps online/offline correctly', () async {
      final fakeDataSource = FakeProfileRemoteDataSource();
      final repository = ProfileRepositoryImpl(remoteDataSource: fakeDataSource);

      final offlineProfile = await repository.updateDutyStatus(false);
      expect(fakeDataSource.lastTargetStatus, equals('offline'));
      expect(offlineProfile.isOnline, isFalse);
      expect(offlineProfile.operationalStatus, equals('offline'));

      final onlineProfile = await repository.updateDutyStatus(true);
      expect(fakeDataSource.lastTargetStatus, equals('online'));
      expect(onlineProfile.isOnline, isTrue);
      expect(onlineProfile.operationalStatus, equals('online'));
    });

    test('OrdersRepositoryImpl: getActiveOrders maps list of DriverOrderModel and nested coordinates', () async {
      final fakeDataSource = FakeOrdersRemoteDataSource();
      final repository = OrdersRepositoryImpl(remoteDataSource: fakeDataSource);

      final orders = await repository.getActiveOrders();

      expect(orders.length, equals(1));
      final order = orders.first;
      expect(order.id, equals(101));
      expect(order.orderNumber, equals('WNG-101'));
      expect(order.status, equals('ready'));
      expect(order.total, equals(55.00));
      expect(order.customerLat, equals(32.8872));
      expect(order.customerLng, equals(13.1913));
      expect(order.restaurantLat, equals(32.8750));
      expect(order.restaurantLng, equals(13.1750));
      expect(order.items.length, equals(1));
    });

    test('OrdersRepositoryImpl: updateOrderStatus passes orderId, status and reason to DataSource', () async {
      final fakeDataSource = FakeOrdersRemoteDataSource();
      final repository = OrdersRepositoryImpl(remoteDataSource: fakeDataSource);

      await repository.updateOrderStatus(101, 'on_the_way', reason: 'الكابتن استلم الطلب وهو في الطريق');

      expect(fakeDataSource.lastUpdatedOrderId, equals(101));
      expect(fakeDataSource.lastUpdatedStatus, equals('on_the_way'));
      expect(fakeDataSource.lastUpdatedReason, equals('الكابتن استلم الطلب وهو في الطريق'));
    });

    test('LocationRepositoryImpl: updateLocation passes coordinates and metadata', () async {
      final fakeDataSource = FakeLocationRemoteDataSource();
      final repository = LocationRepositoryImpl(remoteDataSource: fakeDataSource);

      await repository.updateLocation(32.8872, 13.1913, heading: 180.0, accuracy: 5.0);

      expect(fakeDataSource.lastLat, equals(32.8872));
      expect(fakeDataSource.lastLng, equals(13.1913));
      expect(fakeDataSource.lastHeading, equals(180.0));
      expect(fakeDataSource.lastAccuracy, equals(5.0));
    });
  });

  group('Phase 3 — Item 23: Data Source Endpoint & Method Scoping Tests', () {
    test('Driver Active Orders endpoint must be scoped to /driver/orders/active (NOT /customer/orders)', () {
      expect(ApiConstants.driverActiveOrders, equals('/driver/orders/active'));
      expect(ApiConstants.driverActiveOrders.contains('/customer/'), isFalse);
    });

    test('Driver Profile endpoint must be scoped to /driver/profile (NOT /customer/profile)', () {
      expect(ApiConstants.driverProfile, equals('/driver/profile'));
      expect(ApiConstants.driverProfile.contains('/customer/'), isFalse);
    });

    test('Driver Order Details endpoint must be scoped to /driver/orders/{id}', () {
      expect(ApiConstants.driverOrderDetails(101), equals('/driver/orders/101'));
      expect(ApiConstants.driverOrderDetails(101).contains('/customer/'), isFalse);
    });

    test('Driver Status endpoint must be /driver/status', () {
      expect(ApiConstants.driverStatus, equals('/driver/status'));
    });

    test('Driver Location endpoint must be /driver/location', () {
      expect(ApiConstants.driverLocation, equals('/driver/location'));
    });
  });

  group('Phase 5 — Battery, Performance & GPS Telemetry Tests', () {
    test('GPS Telemetry: Location updates are sent only when driver is Online', () async {
      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: FakeProfileRemoteDataSource());
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: FakeAuthRemoteDataSource());
      final fakeLocationDataSource = FakeLocationRemoteDataSource();
      final fakeLocationRepo = LocationRepositoryImpl(remoteDataSource: fakeLocationDataSource);

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
        locationRepository: fakeLocationRepo,
      );

      await cubit.loadHomeData();
      expect(cubit.state.profile?.isOnline, isTrue);

      // Online driver -> location update succeeds
      await cubit.updateLocation(32.8872, 13.1913, heading: 90.0, accuracy: 4.0);
      expect(fakeLocationDataSource.callCount, equals(1));
      expect(fakeLocationDataSource.lastLat, equals(32.8872));

      // Toggle offline
      await cubit.toggleDuty(false);
      expect(cubit.state.profile?.isOnline, isFalse);

      // Offline driver -> location update is ignored to preserve battery and privacy
      await cubit.updateLocation(32.8900, 13.1950);
      expect(fakeLocationDataSource.callCount, equals(1)); // Did not increment

      await cubit.close();
    });

    test('Adaptive Polling: Going offline cancels polling timer', () async {
      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: FakeProfileRemoteDataSource());
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: FakeAuthRemoteDataSource());

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadHomeData();
      expect(cubit.state.profile?.isOnline, isTrue);

      // Going offline cancels active polling
      await cubit.toggleDuty(false);
      expect(cubit.state.profile?.isOnline, isFalse);
      expect(cubit.state.profile?.operationalStatus, equals('offline'));

      await cubit.close();
    });
  });

  group('Phase 3 & 5 — Unit-testable Cubits (Zero HTTP Leakage)', () {
    test('DriverHomeCubit: loadHomeData emits [loading, loaded] with profile and active order', () async {
      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: FakeProfileRemoteDataSource());
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: FakeAuthRemoteDataSource());

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadHomeData();

      expect(cubit.state.status, equals(DriverHomeStatus.loaded));
      expect(cubit.state.profile?.name, equals('Captain Ahmed'));
      expect(cubit.state.activeOrder?.orderNumber, equals('WNG-101'));
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });

    test('DriverHomeCubit: 401 Unauthorized from ProfileRepository triggers logout and unauthenticated state', () async {
      final fakeProfileDataSource = FakeProfileRemoteDataSource()
        ..exceptionToThrow = const UnauthorizedException();
      final fakeAuthDataSource = FakeAuthRemoteDataSource();

      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: fakeProfileDataSource);
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: fakeAuthDataSource);

      // Pre-populate token
      DioClient.setToken('test_token');

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadHomeData();

      expect(cubit.state.status, equals(DriverHomeStatus.unauthenticated));
      expect(cubit.state.errorMessage, contains('انتهت صلاحية الجلسة'));
      expect(DioClient.getToken(), isNull);

      await cubit.close();
    });

    test('DriverHomeCubit: Network error retains token and displays connection message', () async {
      final fakeProfileDataSource = FakeProfileRemoteDataSource()
        ..exceptionToThrow = const NetworkException();
      final fakeAuthDataSource = FakeAuthRemoteDataSource();

      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: fakeProfileDataSource);
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: fakeAuthDataSource);

      DioClient.setToken('retained_token_on_network_err');

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadHomeData();

      expect(cubit.state.errorMessage, contains('تعذر الاتصال بالخادم'));
      // Token must NOT be cleared on network failure
      expect(DioClient.getToken(), equals('retained_token_on_network_err'));

      await cubit.close();
    });

    test('DriverHomeCubit: updateOrderStatus delivered clears active order and increments earnings', () async {
      final fakeProfileRepo = ProfileRepositoryImpl(remoteDataSource: FakeProfileRemoteDataSource());
      final fakeOrdersRepo = OrdersRepositoryImpl(remoteDataSource: FakeOrdersRemoteDataSource());
      final fakeAuthRepo = AuthRepositoryImpl(remoteDataSource: FakeAuthRemoteDataSource());

      final cubit = DriverHomeCubit(
        profileRepository: fakeProfileRepo,
        ordersRepository: fakeOrdersRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadHomeData();
      expect(cubit.state.activeOrder, isNotNull);

      final initialEarnings = cubit.state.todayEarnings;
      final initialCount = cubit.state.completedOrdersCount;

      await cubit.updateOrderStatus('delivered', 101);

      expect(cubit.state.activeOrder, isNull);
      expect(cubit.state.todayEarnings, equals(initialEarnings + 10.0));
      expect(cubit.state.completedOrdersCount, equals(initialCount + 1));

      await cubit.close();
    });
  });
}
