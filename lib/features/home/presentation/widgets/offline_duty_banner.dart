import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OfflineDutyBanner extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineDutyBanner({
    super.key,
    required this.onGoOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: AppColors.textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'أنت خارج الوردية حالياً',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'قم بتفعيل زر الاتصال بالأعلى لبدء استقبال طلبات التوصيل وزيادة أرباحك اليومية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onGoOnline,
              icon: const Icon(Icons.power_settings_new_rounded, size: 20),
              label: const Text(
                'بدء العمل والاتصال الآن',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onlineGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
