import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/driver_palette.dart';

/// قبل بدء الدوام: حالة واضحة وزر واحد كبير.
class OfflineDutyBanner extends StatelessWidget {
  final VoidCallback onGoOnline;

  const OfflineDutyBanner({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    final p = context.dp;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 5, backgroundColor: p.muted),
                const SizedBox(width: 8),
                Text('غير متصل', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700, color: p.body)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ما تستلمش طلبات وأنت غير متصل.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 17, height: 1.6, color: p.body),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: onGoOnline,
              icon: const Icon(Icons.power_settings_new_rounded, size: 26),
              label: const Text('ابدأ الدوام', style: TextStyle(fontFamily: 'Tajawal', fontSize: 21, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onlineGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
