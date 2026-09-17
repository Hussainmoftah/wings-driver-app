import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TodaySummaryCards extends StatelessWidget {
  final double todayEarnings;
  final int completedOrdersCount;
  final double shiftHours;
  final double acceptanceRate;

  const TodaySummaryCards({
    super.key,
    required this.todayEarnings,
    required this.completedOrdersCount,
    required this.shiftHours,
    required this.acceptanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ملخص إنجاز اليوم',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'تحديث لحظي',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 1. أرباح اليوم (Today's Earnings)
              Expanded(
                child: _buildMetricCard(
                  title: 'أرباح اليوم',
                  value: '${todayEarnings.toStringAsFixed(2)} د.ل',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.onlineGreen,
                  bgColor: AppColors.onlineGreenLight,
                  subtext: '+15 د.ل آخر رحلة',
                ),
              ),
              const SizedBox(width: 10),

              // 2. الرحلات المكتملة (Completed Trips)
              Expanded(
                child: _buildMetricCard(
                  title: 'الطلبات المنجزة',
                  value: '$completedOrdersCount طلبات',
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  subtext: 'سعة ممتازة اليوم',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 3. ساعات الوردية (Shift Hours)
              Expanded(
                child: _buildMetricCard(
                  title: 'ساعات العمل',
                  value: '${shiftHours.toStringAsFixed(1)} ساعة',
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.busyOrange,
                  bgColor: AppColors.busyOrangeLight,
                  subtext: 'نشط منذ الصباح',
                ),
              ),
              const SizedBox(width: 10),

              // 4. نسبة القبول (Acceptance Rate)
              Expanded(
                child: _buildMetricCard(
                  title: 'نسبة القبول',
                  value: '${acceptanceRate.toStringAsFixed(1)}%',
                  icon: Icons.thumb_up_alt_rounded,
                  iconColor: AppColors.purple,
                  bgColor: const Color(0xFFF3E8FF),
                  subtext: 'تقييم كابتن مميز ⭐',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: iconColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
