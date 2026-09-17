class DriverOrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;
  final String? restaurantName;
  final String? restaurantPhone;
  final String? restaurantAddress;
  final String? restaurantLogo;
  final double? restaurantLat;
  final double? restaurantLng;
  final List<DriverOrderItemModel> items;
  final String? createdAt;

  DriverOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.total,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerLat,
    this.customerLng,
    this.restaurantName,
    this.restaurantPhone,
    this.restaurantAddress,
    this.restaurantLogo,
    this.restaurantLat,
    this.restaurantLng,
    this.items = const [],
    this.createdAt,
  });

  factory DriverOrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final restaurant = json['restaurant'] as Map<String, dynamic>?;
    final address = (json['delivery_address'] ?? json['address']) as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((i) => DriverOrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    double parseNum(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    double? parseOptionalNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    // Build human-readable address strings without injecting hardcoded fake names
    String? resolvedCustomerAddress;
    if (address != null) {
      final parts = [
        address['title'],
        address['street'],
        address['city'],
        if (address['building_number'] != null) 'مبنى ${address['building_number']}',
        if (address['floor'] != null) 'طابق ${address['floor']}',
      ].where((p) => p != null && p.toString().trim().isNotEmpty).toList();
      resolvedCustomerAddress = parts.isNotEmpty ? parts.join(' - ') : address['address'];
    } else if (customer != null && customer['address'] != null) {
      resolvedCustomerAddress = customer['address'].toString();
    }

    String? resolvedRestaurantAddress;
    if (restaurant != null) {
      final parts = [
        restaurant['street'],
        restaurant['city'],
      ].where((p) => p != null && p.toString().trim().isNotEmpty).toList();
      resolvedRestaurantAddress = parts.isNotEmpty ? parts.join(' - ') : restaurant['address'];
    }

    return DriverOrderModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      orderNumber: json['order_number'] ?? '#WNG-${json['id']}',
      status: json['status'] ?? 'pending',
      subtotal: parseNum(json['subtotal']),
      deliveryFee: parseNum(json['delivery_fee']),
      discount: parseNum(json['discount']),
      total: parseNum(json['total']),
      customerName: customer?['name'],
      customerPhone: customer?['phone'],
      customerAddress: resolvedCustomerAddress,
      customerLat: parseOptionalNum(address?['latitude'] ?? customer?['latitude']),
      customerLng: parseOptionalNum(address?['longitude'] ?? customer?['longitude']),
      restaurantName: restaurant?['name'],
      restaurantPhone: restaurant?['phone'],
      restaurantAddress: resolvedRestaurantAddress,
      restaurantLogo: restaurant?['logo'],
      restaurantLat: parseOptionalNum(restaurant?['latitude']),
      restaurantLng: parseOptionalNum(restaurant?['longitude']),
      items: parsedItems,
      createdAt: json['created_at'],
    );
  }
}

class DriverOrderItemModel {
  final int id;
  final int? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  DriverOrderItemModel({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory DriverOrderItemModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DriverOrderItemModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      productId: json['product_id'] != null ? (json['product_id'] as num).toInt() : null,
      productName: json['product_name'] ?? json['name'] ?? 'وجبة',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1),
      unitPrice: parseNum(json['unit_price'] ?? json['unit_price_snapshot']),
      totalPrice: parseNum(json['subtotal'] ?? json['total_price'] ?? json['subtotal_snapshot']),
      notes: json['notes'],
    );
  }
}
