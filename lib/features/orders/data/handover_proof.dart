import 'dart:typed_data';

/// ما عدّه السائق عند استلام الطلب من المطعم، وبلاغ النقص إن وُجد.
class PickupCount {
  final int pieces;
  final int drinks;
  final String? shortageNote;

  const PickupCount({
    required this.pieces,
    required this.drinks,
    this.shortageNote,
  });
}

/// صورة الطلب في الكيس عند التسليم، أو سبب تعذر التصوير، مع موقع السائق.
class DeliveryProof {
  final Uint8List? photo;
  final String? skipReason;
  final double? latitude;
  final double? longitude;

  const DeliveryProof({
    this.photo,
    this.skipReason,
    this.latitude,
    this.longitude,
  });
}

/// صنف في الطلب كما يجب أن يستلمه السائق.
class ExpectedPickupItem {
  final String name;
  final int quantity;
  final bool isDrink;
  final String? restaurant;

  const ExpectedPickupItem({
    required this.name,
    required this.quantity,
    required this.isDrink,
    this.restaurant,
  });

  factory ExpectedPickupItem.fromJson(Map<String, dynamic> json) =>
      ExpectedPickupItem(
        name: json['name']?.toString() ?? 'صنف',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        isDrink: json['is_drink'] == true,
        restaurant: json['restaurant']?.toString(),
      );
}

/// العدد الذي كتبه السائق لا يطابق الطلب: يراجع الأصناف مع المطعم أو يبلغ عن نقص.
class PickupMismatchException implements Exception {
  final String message;
  final int expectedPieces;
  final int expectedDrinks;
  final List<ExpectedPickupItem> items;

  const PickupMismatchException({
    required this.message,
    required this.expectedPieces,
    required this.expectedDrinks,
    required this.items,
  });

  factory PickupMismatchException.fromResponse(Map<String, dynamic> body) {
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : const <String, dynamic>{};
    return PickupMismatchException(
      message: body['message']?.toString() ?? 'العدد لا يطابق الطلب.',
      expectedPieces: (data['expected_pieces'] as num?)?.toInt() ?? 0,
      expectedDrinks: (data['expected_drinks'] as num?)?.toInt() ?? 0,
      items: [
        for (final i in data['items'] as List? ?? const [])
          ExpectedPickupItem.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
    );
  }

  @override
  String toString() => message;
}
