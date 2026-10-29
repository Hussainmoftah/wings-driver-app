import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/driver_palette.dart';

/// مال السائق في سطر واحد واضح: المطلوب توريده (أو المستحق له) بخط كبير،
/// وتحته كيف انحسب (ما حصّله ناقص أجره)، ثم تقدمه نحو المكافأة.
class DriverWalletCards extends StatelessWidget {
  final double cashCustody;
  final double requiredRemittance;
  final double earnings;
  final double payoutDue;
  final bool rewardEnabled;
  final int rewardEvery;
  final int rewardRemaining;
  final int todayDeliveries;
  final String rewardValueLabel;

  const DriverWalletCards({
    super.key,
    required this.cashCustody,
    required this.requiredRemittance,
    required this.earnings,
    required this.payoutDue,
    required this.rewardEnabled,
    required this.rewardEvery,
    required this.rewardRemaining,
    required this.todayDeliveries,
    required this.rewardValueLabel,
  });

  String _money(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final p = context.dp;
    // أجره أكبر من النقد الذي بيده (طلبات مدفوعة إلكترونياً): المنصة تدفع له الفرق
    final owesDriver = payoutDue > 0;
    final headline = owesDriver ? payoutDue : requiredRemittance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: owesDriver ? p.successCard : p.navyCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owesDriver ? 'مستحق لك من الشركة' : 'المطلوب توريده للشركة',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w500, color: p.onNavyMuted),
                ),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _money(headline), style: const TextStyle(fontSize: 38)),
                    const TextSpan(text: ' د.ل', style: TextStyle(fontSize: 20)),
                  ]),
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
                ),
                Text(
                  'حصّلت ${_money(cashCustody)} · أجرك ${_money(earnings)}',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: p.onNavyMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tile(p, 'توصيلات اليوم', '$todayDeliveries')),
              const SizedBox(width: 12),
              Expanded(child: _tile(p, 'أجري', '${_money(earnings)} د.ل')),
            ],
          ),
          if (rewardEnabled && rewardEvery > 0) ...[
            const SizedBox(height: 12),
            _rewardProgress(p),
          ],
        ],
      ),
    );
  }

  Widget _tile(DriverPalette p, String label, String value) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w500, color: p.muted)),
            Text(value, style: TextStyle(fontFamily: 'Tajawal', fontSize: 26, fontWeight: FontWeight.w800, color: p.ink)),
          ],
        ),
      );

  Widget _rewardProgress(DriverPalette p) {
    final doneInCycle = (rewardEvery - rewardRemaining).clamp(0, rewardEvery);
    final nextIsReward = rewardRemaining <= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.readySoft, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.emoji_events_outlined, size: 22, color: p.readyText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nextIsReward
                    ? 'توصيلتك الجاية مكافأة: $rewardValueLabel'
                    : 'باقيلك $rewardRemaining توصيلة للمكافأة ($rewardValueLabel)',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w800, color: p.readyText),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: nextIsReward ? 1 : doneInCycle / rewardEvery,
              minHeight: 10,
              backgroundColor: p.surface,
              color: AppColors.busyOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'توصيلات اليوم: $todayDeliveries · العدّاد يرجع صفر كل يوم',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: p.readyText),
          ),
        ],
      ),
    );
  }
}
