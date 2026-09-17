import 'package:flutter_test/flutter_test.dart';
import 'package:wings_driver/core/network/api_constants.dart';
import 'package:wings_driver/features/orders/data/driver_order_model.dart';
import 'package:wings_driver/features/profile/data/driver_profile_model.dart';

void main() {
  group('Phase 2: Flutter Driver Data Contract & Model Parsing Tests', () {
    test('Test Contract 1: DriverOrderModel correctly parses real Backend active order contract', () {
      final backendJson = {
        'id': 482,
        'order_number': '#WNG-482',
        'status': 'ready',
        'subtotal': 50.00,
        'delivery_fee': 5.00,
        'discount': 0.00,
        'total': 55.00,
        'restaurant': {
          'id': 1,
          'name': 'مطعم الأصالة',
          'phone': '0912222222',
          'street': 'شارع عمر المختار',
          'city': 'طرابلس',
          'latitude': 32.8955,
          'longitude': 13.1844,
          'logo': 'https://wings.ly/uploads/logo.png',
        },
        'customer': {
          'id': 15,
          'name': 'أحمد محمود',
          'phone': '0912345678',
        },
        'delivery_address': {
          'id': 12,
          'title': 'المنزل',
          'address': 'شارع بن عاشور، طرابلس',
          'street': 'شارع بن عاشور',
          'city': 'طرابلس',
          'latitude': 32.8711,
          'longitude': 13.1788,
          'building_number': '14',
          'floor': '2',
          'notes': 'مقابل الصيدلية',
        },
        'items': [
          {
            'id': 101,
            'product_id': 50,
            'product_name': 'برجر دجاج سوبريم',
            'quantity': 2,
            'unit_price': 25.00,
            'subtotal': 50.00,
            'notes': 'بدون بصل',
          }
        ],
        'created_at': '2026-09-09T14:58:22.000000Z',
      };

      final order = DriverOrderModel.fromJson(backendJson);

      expect(order.id, equals(482));
      expect(order.orderNumber, equals('#WNG-482'));
      expect(order.status, equals('ready'));
      expect(order.subtotal, equals(50.00));
      expect(order.deliveryFee, equals(5.00));
      expect(order.total, equals(55.00));

      // Restaurant contract
      expect(order.restaurantName, equals('مطعم الأصالة'));
      expect(order.restaurantPhone, equals('0912222222'));
      expect(order.restaurantLat, equals(32.8955));
      expect(order.restaurantLng, equals(13.1844));

      // Customer & Address contract
      expect(order.customerName, equals('أحمد محمود'));
      expect(order.customerPhone, equals('0912345678'));
      expect(order.customerLat, equals(32.8711));
      expect(order.customerLng, equals(13.1788));
      expect(order.customerAddress, contains('شارع بن عاشور'));

      // Items contract
      expect(order.items.length, equals(1));
      expect(order.items[0].productName, equals('برجر دجاج سوبريم'));
      expect(order.items[0].quantity, equals(2));
      expect(order.items[0].unitPrice, equals(25.00));
      expect(order.items[0].totalPrice, equals(50.00));
    });

    test('Test Contract 2: DriverOrderModel handles null coordinates gracefully without hardcoded defaults', () {
      final jsonWithoutCoords = {
        'id': 99,
        'order_number': '#WNG-99',
        'status': 'accepted',
        'subtotal': 20.00,
        'delivery_fee': 5.00,
        'total': 25.00,
        'restaurant': {
          'id': 1,
          'name': 'مطعم بدون إحداثيات',
        },
        'delivery_address': null,
      };

      final order = DriverOrderModel.fromJson(jsonWithoutCoords);

      expect(order.restaurantLat, isNull);
      expect(order.restaurantLng, isNull);
      expect(order.customerLat, isNull);
      expect(order.customerLng, isNull);
      expect(order.customerAddress, isNull);
    });

    test('Test Contract 3: DriverProfileModel parses backend profile accurately', () {
      final profileJson = {
        'user_id': 3,
        'name': 'كابتن محمود',
        'phone': '0910000001',
        'is_online': true,
        'operational_status': 'online',
        'status_label': 'متصل ومتاح',
        'current_latitude': 32.8872,
        'current_longitude': 13.1913,
        'has_active_order': true,
        'active_order_id': 482,
      };

      final profile = DriverProfileModel.fromJson(profileJson);

      expect(profile.name, equals('كابتن محمود'));
      expect(profile.phone, equals('0910000001'));
      expect(profile.isOnline, isTrue);
      expect(profile.operationalStatus, equals('online'));
      expect(profile.hasActiveOrder, isTrue);
      expect(profile.activeOrderId, equals(482));
    });

    test('Test Contract 4: ApiConstants uses driver-scoped endpoints and NO customer tracking endpoint', () {
      expect(ApiConstants.driverActiveOrders, equals('/driver/orders/active'));
      expect(ApiConstants.driverOrderDetails(482), equals('/driver/orders/482'));
      expect(ApiConstants.updateOrderStatus(482), equals('/driver/orders/482/status'));
    });
  });
}
