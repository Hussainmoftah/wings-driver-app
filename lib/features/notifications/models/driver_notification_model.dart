class DriverNotificationItem {
  final int id;
  final String title;
  final String body;
  final String category;
  final String actionType;
  final String? actionId;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? data;

  DriverNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.actionType,
    this.actionId,
    required this.isRead,
    this.createdAt,
    this.data,
  });

  factory DriverNotificationItem.fromJson(Map<String, dynamic> json) {
    return DriverNotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? 'order',
      actionType: json['action_type'] ?? 'none',
      actionId: json['action_id']?.toString(),
      isRead: json['read_at'] != null || json['is_read'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  DriverNotificationItem copyWith({
    int? id,
    String? title,
    String? body,
    String? category,
    String? actionType,
    String? actionId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return DriverNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
