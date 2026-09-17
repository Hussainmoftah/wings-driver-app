import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/data/driver_order_model.dart';

class ActiveDeliveryCard extends StatefulWidget {
  final DriverOrderModel order;
  final bool isUpdating;
  final Function(String newStatus, int orderId) onUpdateStatus;
  final VoidCallback? onFocusRestaurantOnMap;
  final VoidCallback? onFocusCustomerOnMap;

  const ActiveDeliveryCard({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onUpdateStatus,
    this.onFocusRestaurantOnMap,
    this.onFocusCustomerOnMap,
  });

  @override
  State<ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends State<ActiveDeliveryCard> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bool isReadyForPickup = widget.order.status == 'ready' || widget.order.status == 'accepted' || widget.order.status == 'preparing';
    final bool isOnTheWay = widget.order.status == 'on_the_way' || widget.order.status == 'on_delivery';

    // Calculate total item units
    final int totalUnitsCount = widget.order.items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOnTheWay ? AppColors.onlineGreen : AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnTheWay ? AppColors.onlineGreen : AppColors.primary).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Order Number, Live Status Pill & Total Cash Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: (isOnTheWay ? AppColors.onlineGreen : AppColors.primary).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOnTheWay ? AppColors.onlineGreen : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnTheWay ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.orderNumber,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          isOnTheWay ? 'في الطريق لتسليم الزبون' : 'جاهز للاستلام من المطعم',
                          style: TextStyle(
                            color: isOnTheWay ? AppColors.onlineGreen : AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'مطلوب تحصيله كاش',
                        style: TextStyle(color: AppColors.textLight, fontSize: 9, fontFamily: 'Cairo'),
                      ),
                      Text(
                        '${widget.order.total.toStringAsFixed(2)} د.ل',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Timeline Step 1: Restaurant Pickup Point
                _buildLocationTile(
                  title: 'نقطة الاستلام (المطعم)',
                  name: widget.order.restaurantName ?? 'مطعم الأجنحة',
                  address: widget.order.restaurantAddress ?? 'طريق الشط - طرابلس',
                  phone: widget.order.restaurantPhone,
                  icon: Icons.storefront_rounded,
                  iconBg: AppColors.primaryLight,
                  iconColor: AppColors.primary,
                  isCompleted: isOnTheWay,
                  isCurrent: isReadyForPickup,
                  onTapMap: widget.onFocusRestaurantOnMap,
                ),

                // Connecting Dashed Line
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Container(
                    height: 20,
                    width: 2,
                    color: isOnTheWay ? AppColors.onlineGreen : AppColors.border,
                  ),
                ),

                // 3. Timeline Step 2: Customer Delivery Destination
                _buildLocationTile(
                  title: 'نقطة التسليم (الزبون)',
                  name: widget.order.customerName ?? 'زبون وينجز',
                  address: widget.order.customerAddress ?? 'حي الأندلس - طرابلس',
                  phone: widget.order.customerPhone,
                  icon: Icons.location_on_rounded,
                  iconBg: AppColors.onlineGreenLight,
                  iconColor: AppColors.onlineGreen,
                  isCompleted: false,
                  isCurrent: isOnTheWay,
                  onTapMap: widget.onFocusCustomerOnMap,
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 8),

                // 4. Order Items Summary Breakdown (Clearly Presented)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppColors.textPrimary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'تفاصيل محتويات الطلبية',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'إجمالي: $totalUnitsCount عناصر (${widget.order.items.length} أصناف)',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rich Item Cards List
                ...widget.order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Quantity Badge (العدد واضح جداً)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Item Name & Unit Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  'سعر الوحدة: ${item.unitPrice.toStringAsFixed(2)} د.ل',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Total for line
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} د.ل',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    )),

                // Delivery Fee Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أجرة التوصيل المستحقة للسائق:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
                      ),
                      Text(
                        '+${widget.order.deliveryFee.toStringAsFixed(2)} د.ل',
                        style: const TextStyle(
                          color: AppColors.onlineGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Action Button (State Transitions)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.isUpdating
                        ? null
                        : () {
                            if (isReadyForPickup) {
                              widget.onUpdateStatus('on_the_way', widget.order.id);
                            } else if (isOnTheWay) {
                              widget.onUpdateStatus('delivered', widget.order.id);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnTheWay ? AppColors.onlineGreen : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: widget.isUpdating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOnTheWay ? Icons.check_circle_outline_rounded : Icons.takeout_dining_rounded,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnTheWay
                                    ? 'تأكيد تسليم الطلب وتحصيل ${widget.order.total.toStringAsFixed(2)} د.ل'
                                    : 'تأكيد استلام الطلب من المطعم والانطلاق',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile({
    required String title,
    required String name,
    required String address,
    required String? phone,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isCompleted,
    required bool isCurrent,
    VoidCallback? onTapMap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTapMap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.onlineGreen : iconBg,
              shape: BoxShape.circle,
              border: isCurrent ? Border.all(color: iconColor, width: 2) : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              color: isCompleted ? Colors.white : iconColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontFamily: 'Cairo'),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                address,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (onTapMap != null)
              IconButton(
                onPressed: onTapMap,
                tooltip: 'عرض على الخريطة',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.map_rounded, color: iconColor, size: 18),
                ),
              ),
            if (phone != null && phone.isNotEmpty)
              IconButton(
                onPressed: () {},
                tooltip: 'اتصال',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
