import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

class OfflineDutyBanner extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineDutyBanner({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.sc.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.sc.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.sc.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nightlight_round,
              color: context.sc.textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'أنت خارج الوردية حالياً',
            style: TextStyle(
              color: context.sc.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قم بتفعيل زر الاتصال بالأعلى لبدء استقبال طلبات التوصيل وزيادة أرباحك اليومية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.sc.textSecondary,
              fontSize: 13,
              fontFamily: 'Tajawal',
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onlineGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
