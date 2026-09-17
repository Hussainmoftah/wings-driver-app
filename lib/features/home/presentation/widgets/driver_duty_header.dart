import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/data/driver_profile_model.dart';

class DriverDutyHeader extends StatelessWidget {
  final DriverProfileModel? profile;
  final bool isOnline;
  final bool isUpdating;
  final ValueChanged<bool> onToggleDuty;

  const DriverDutyHeader({
    super.key,
    required this.profile,
    required this.isOnline,
    required this.isUpdating,
    required this.onToggleDuty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row: Avatar, Driver Name, Vehicle Badge & Notifications
            Row(
              children: [
                // Driver Avatar with status dot
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOnline ? AppColors.onlineGreen : AppColors.textLight,
                          width: 2.5,
                        ),
                        color: AppColors.darkCardSecondary,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_motorsports_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.onlineGreen : AppColors.offlineRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkCard, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Driver Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? 'كابتن وينجز',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.darkCardSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.two_wheeler_rounded, size: 13, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text(
                                  profile?.vehicleType ?? 'دراجة نارية',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: const [
                              Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                              SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Notifications Icon Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkCardSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Online / Offline Duty Switcher Banner
            GestureDetector(
              onTap: isUpdating ? null : () => onToggleDuty(!isOnline),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline
                        ? [const Color(0xFF059669), const Color(0xFF10B981)]
                        : [const Color(0xFF334155), const Color(0xFF1E293B)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: AppColors.onlineGreen.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Status Icon with Pulse Ring
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.flash_on_rounded : Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'الوردية نشطة (أنت متصل الآن)' : 'خارج الوردية (أنت غير متصل)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            isOnline ? 'جاهز ومؤهل لاستقبال الطلبات الفورية' : 'اضغط للاتصال والبدء في استلام الطلبات',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toggle Button Visual
                    if (isUpdating)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOnline ? 'إيقاف' : 'اتصال',
                          style: TextStyle(
                            color: isOnline ? AppColors.onlineGreen : AppColors.darkCard,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
