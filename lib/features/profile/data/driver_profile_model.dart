class DriverProfileModel {
  final int userId;
  final String name;
  final String phone;
  final bool isOnline;
  final String operationalStatus;
  final String statusLabel;
  final String? vehicleType;
  final String? licenseNumber;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? heading;
  final double? accuracy;
  final String? lastLocationAt;
  final bool isLocationFresh;
  final bool hasActiveOrder;
  final int? activeOrderId;
  final String? activeOrderStatus;

  DriverProfileModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.isOnline,
    required this.operationalStatus,
    required this.statusLabel,
    this.vehicleType,
    this.licenseNumber,
    this.currentLatitude,
    this.currentLongitude,
    this.heading,
    this.accuracy,
    this.lastLocationAt,
    this.isLocationFresh = false,
    this.hasActiveOrder = false,
    this.activeOrderId,
    this.activeOrderStatus,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isOnline: json['is_online'] == true,
      operationalStatus: json['operational_status'] ?? 'offline',
      statusLabel: json['status_label'] ?? 'غير متصل',
      vehicleType: json['vehicle_type'],
      licenseNumber: json['license_number'],
      currentLatitude: json['current_latitude'] != null ? (json['current_latitude'] as num).toDouble() : null,
      currentLongitude: json['current_longitude'] != null ? (json['current_longitude'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      lastLocationAt: json['last_location_at'],
      isLocationFresh: json['is_location_fresh'] == true,
      hasActiveOrder: json['has_active_order'] == true,
      activeOrderId: json['active_order_id'],
      activeOrderStatus: json['active_order_status'],
    );
  }

  DriverProfileModel copyWith({
    bool? isOnline,
    String? operationalStatus,
    String? statusLabel,
    bool? hasActiveOrder,
    int? activeOrderId,
    String? activeOrderStatus,
  }) {
    return DriverProfileModel(
      userId: userId,
      name: name,
      phone: phone,
      isOnline: isOnline ?? this.isOnline,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      statusLabel: statusLabel ?? this.statusLabel,
      vehicleType: vehicleType,
      licenseNumber: licenseNumber,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      heading: heading,
      accuracy: accuracy,
      lastLocationAt: lastLocationAt,
      isLocationFresh: isLocationFresh,
      hasActiveOrder: hasActiveOrder ?? this.hasActiveOrder,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      activeOrderStatus: activeOrderStatus ?? this.activeOrderStatus,
    );
  }
}
