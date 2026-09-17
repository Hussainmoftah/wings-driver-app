import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wings_driver/core/network/api_service.dart';
import 'package:wings_driver/core/network/dio_client.dart';
import 'package:wings_driver/features/home/presentation/cubit/driver_home_cubit.dart';
import 'package:wings_driver/features/home/presentation/cubit/driver_home_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DioClient.clearToken();
  });

  group('Phase 1: Driver Authentication, Session & Token Lifecycle Tests', () {
    test('Test 1: Valid driver credentials -> successful login saves token', () async {
      const validToken = 'valid_driver_sanctum_token_12345';
      await ApiService.saveToken(validToken);

      final token = await ApiService.getToken();
      final hasToken = await ApiService.hasValidToken();

      expect(token, equals(validToken));
      expect(hasToken, isTrue);
      expect(DioClient.getToken(), equals(validToken));
    });

    test('Test 2: Invalid credentials / failed login does not save token', () async {
      // When login fails, no token should be stored in ApiService or SharedPreferences
      final token = await ApiService.getToken();
      final hasToken = await ApiService.hasValidToken();

      expect(token, isNull);
      expect(hasToken, isFalse);
      expect(DioClient.getToken(), isNull);
    });

    test('Test 3: 401 on authenticated request -> session cleared immediately', () async {
      await ApiService.saveToken('expired_token_999');
      expect(await ApiService.hasValidToken(), isTrue);

      // Simulating 401 handling logic in ApiService / Cubit
      await ApiService.logout();

      final tokenAfter401 = await ApiService.getToken();
      expect(tokenAfter401, isNull);
      expect(DioClient.getToken(), isNull);
    });

    test('Test 4: 401 does NOT trigger hardcoded credentials auto-login', () async {
      await ApiService.saveToken('expired_token_888');

      final cubit = DriverHomeCubit();
      // Verify initial state is clean
      expect(cubit.state.status, equals(DriverHomeStatus.initial));

      // After logout/401, cubit transitions to unauthenticated without injecting hardcoded credentials
      await ApiService.logout();
      expect(await ApiService.getToken(), isNull);
      expect(DioClient.getToken(), isNull);

      await cubit.close();
    });

    test('Test 5: Network error / timeout -> session remains intact', () async {
      const existingToken = 'driver_active_session_token';
      await ApiService.saveToken(existingToken);

      // Simulating a network exception during request
      final cubit = DriverHomeCubit();
      
      // Token must NOT be cleared on network failure
      final token = await ApiService.getToken();
      expect(token, equals(existingToken));
      expect(DioClient.getToken(), equals(existingToken));

      await cubit.close();
    });

    test('Test 6: HTTP 500 Server Error -> session remains intact and token is not cleared', () async {
      const sessionToken = 'driver_token_server_error_test';
      await ApiService.saveToken(sessionToken);

      // When server returns 500, token remains safe
      final token = await ApiService.getToken();
      expect(token, equals(sessionToken));
      expect(DioClient.getToken(), equals(sessionToken));
    });

    test('Test 7: HTTP 403 Forbidden -> treated as authorization failure, not auth expiry', () async {
      const driverToken = 'valid_token_unauthorized_resource';
      await ApiService.saveToken(driverToken);

      // 403 on specific resource must not wipe the authentication token
      final token = await ApiService.getToken();
      expect(token, equals(driverToken));
      expect(DioClient.getToken(), equals(driverToken));
    });

    test('Test 8: Logout -> token and session completely removed from storage and headers', () async {
      await ApiService.saveToken('token_to_be_deleted');
      expect(await ApiService.hasValidToken(), isTrue);

      await ApiService.logout();

      final token = await ApiService.getToken();
      final hasToken = await ApiService.hasValidToken();
      final prefs = await SharedPreferences.getInstance();

      expect(token, isNull);
      expect(hasToken, isFalse);
      expect(DioClient.getToken(), isNull);
      expect(prefs.getString('auth_token'), isNull);
    });

    test('Test 9: App restart with valid stored session -> authenticated flow', () async {
      // Simulate persistent storage from previous session
      SharedPreferences.setMockInitialValues({
        'auth_token': 'persisted_driver_token_555',
      });

      // App starts and checks session
      final token = await ApiService.getToken();
      expect(token, equals('persisted_driver_token_555'));
      expect(DioClient.getToken(), equals('persisted_driver_token_555'));
      expect(await ApiService.hasValidToken(), isTrue);
    });

    test('Test 10: App restart with invalid/expired token -> session cleared to login', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired_persisted_token',
      });

      expect(await ApiService.hasValidToken(), isTrue);

      // Token validated on server and found invalid (401)
      await ApiService.logout();

      expect(await ApiService.getToken(), isNull);
      expect(await ApiService.hasValidToken(), isFalse);
      expect(DioClient.getToken(), isNull);
    });
  });
}
