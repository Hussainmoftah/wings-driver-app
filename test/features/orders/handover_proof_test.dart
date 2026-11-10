import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wings_driver/core/errors/exceptions.dart';
import 'package:wings_driver/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:wings_driver/features/orders/data/driver_order_model.dart';
import 'package:wings_driver/features/orders/data/handover_proof.dart';

/// يلتقط الطلب المرسل للخادم ويرد بالرد المحدد.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Map<String, dynamic> body;
  RequestOptions? sent;

  _FakeAdapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(OrdersRemoteDataSourceImpl, _FakeAdapter) _source(
  int status,
  Map<String, dynamic> body,
) {
  final adapter = _FakeAdapter(status, body);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.test',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = adapter;
  return (OrdersRemoteDataSourceImpl(dio: dio), adapter);
}

void main() {
  group('عدّ القطع عند الاستلام', () {
    test('يرسل العدد وبلاغ النقص مع الحالة', () async {
      final (source, adapter) = _source(200, {'status': 'success'});

      await source.updateOrderStatus(
        7,
        'on_the_way',
        pickup: const PickupCount(
          pieces: 5,
          drinks: 2,
          shortageNote: 'الكولا خالصة',
        ),
      );

      expect(adapter.sent!.path, '/driver/orders/7/status');
      expect(adapter.sent!.data, {
        'status': 'on_the_way',
        'pieces_count': 5,
        'drinks_count': 2,
        'shortage_note': 'الكولا خالصة',
      });
    });

    test('عدم التطابق يرجع الأصناف ليراجعها السائق', () async {
      final (source, _) = _source(422, {
        'status': 'error',
        'code': 'pickup_count_mismatch',
        'message': 'العدد لا يطابق الطلب.',
        'data': {
          'expected_pieces': 6,
          'expected_drinks': 3,
          'items': [
            {
              'name': 'برجر',
              'quantity': 2,
              'is_drink': false,
              'restaurant': 'مطعم الجناح',
            },
            {'name': 'كولا', 'quantity': 3, 'is_drink': true},
          ],
        },
      });

      await expectLater(
        source.updateOrderStatus(
          7,
          'on_the_way',
          pickup: const PickupCount(pieces: 6, drinks: 2),
        ),
        throwsA(
          isA<PickupMismatchException>()
              .having((e) => e.expectedPieces, 'pieces', 6)
              .having((e) => e.expectedDrinks, 'drinks', 3)
              .having((e) => e.items.length, 'items', 2)
              .having((e) => e.items.last.isDrink, 'drink', true)
              .having(
                (e) => e.items.first.restaurant,
                'restaurant',
                'مطعم الجناح',
              )
              .having((e) => e.message, 'message', 'العدد لا يطابق الطلب.'),
        ),
      );
    });

    test('رفض آخر يبقى خطأ عادياً برسالة الخادم', () async {
      final (source, _) = _source(422, {
        'status': 'error',
        'code': 'pickup_count_required',
        'message': 'اكتب عدد القطع وعدد المشروبات التي استلمتها من المطعم.',
      });

      await expectLater(
        source.updateOrderStatus(7, 'on_the_way'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'اكتب عدد القطع وعدد المشروبات التي استلمتها من المطعم.',
          ),
        ),
      );
    });
  });

  group('صورة التسليم', () {
    test('الصورة تُرسل ملفاً مع الموقع', () async {
      final (source, adapter) = _source(200, {'status': 'success'});

      await source.updateOrderStatus(
        9,
        'delivered',
        delivery: DeliveryProof(
          photo: Uint8List.fromList([1, 2, 3]),
          latitude: 32.88,
          longitude: 13.19,
        ),
      );

      final form = adapter.sent!.data as FormData;
      expect(
        {for (final f in form.fields) f.key: f.value},
        {'status': 'delivered', 'latitude': '32.88', 'longitude': '13.19'},
      );
      expect(form.files.single.key, 'photo');
      expect(form.files.single.value.filename, 'bag.jpg');
      expect(form.files.single.value.length, 3);
    });

    test('بلا صورة يرسل سبب تعذر التصوير', () async {
      final (source, adapter) = _source(200, {'status': 'success'});

      await source.updateOrderStatus(
        9,
        'delivered',
        delivery: const DeliveryProof(skipReason: 'الكاميرا لا تعمل'),
      );

      expect(adapter.sent!.data, {
        'status': 'delivered',
        'photo_skip_reason': 'الكاميرا لا تعمل',
      });
    });
  });

  test('الصنف يعرف إنه مشروب من الخادم', () {
    final drink = DriverOrderItemModel.fromJson({
      'id': 1,
      'product_name': 'كولا',
      'quantity': 2,
      'is_drink': true,
    });
    final meal = DriverOrderItemModel.fromJson({
      'id': 2,
      'product_name': 'برجر',
      'quantity': 1,
    });

    expect(drink.isDrink, isTrue);
    expect(meal.isDrink, isFalse);
  });
}
