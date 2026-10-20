import 'package:flutter/material.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

/// نافذتا السائق المالية: العهدة النقدية التي بيده، ومستحقاته من التوصيل،
/// مع تقدمه نحو المكافأة التالية اليوم (برنامج الحوافز).
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

  String _money(double v) => '${v.toStringAsFixed(2)} د.ل';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  color: SColors.amber700,
                  title: 'العهدة النقدية',
                  value: _money(cashCustody),
                  note: requiredRemittance > 0
                      ? 'المطلوب توريده: ${_money(requiredRemittance)}'
                      : 'لا يوجد مبلغ للتوريد',
                ),
              ),
              const SizedBox(width: SSpacing.md),
              Expanded(
                child: _card(
                  context,
                  icon: Icons.payments_outlined,
                  color: SColors.emerald700,
                  title: 'مستحقاتي من التوصيل',
                  value: _money(earnings),
                  note: payoutDue > 0 ? 'تُصرف لك: ${_money(payoutDue)}' : 'تُخصم من التوريد عند التسوية',
                ),
              ),
            ],
          ),
          if (rewardEnabled && rewardEvery > 0) ...[
            const SizedBox(height: SSpacing.md),
            _rewardProgress(context),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required IconData icon, required Color color, required String title, required String value, required String note}) {
    return SCard(
      padding: const EdgeInsets.all(SSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: SIconSize.sm, color: color),
            const SizedBox(width: SSpacing.xs),
            Expanded(child: Text(title, style: STextStyles.label.copyWith(color: context.sc.textSecondary))),
          ]),
          const SizedBox(height: SSpacing.sm),
          Text(value, style: STextStyles.title.copyWith(color: context.sc.textPrimary)),
          const SizedBox(height: SSpacing.xs),
          Text(note, style: STextStyles.caption.copyWith(color: context.sc.textSecondary)),
        ],
      ),
    );
  }

  Widget _rewardProgress(BuildContext context) {
    final doneInCycle = (rewardEvery - rewardRemaining).clamp(0, rewardEvery);
    final nextIsReward = rewardRemaining <= 0;
    return SCard(
      color: context.sc.brandTint,
      padding: const EdgeInsets.all(SSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.emoji_events_outlined, size: SIconSize.sm, color: context.sc.brandText),
            const SizedBox(width: SSpacing.xs),
            Expanded(
              child: Text(
                nextIsReward
                    ? 'توصيلتك القادمة مكافأة: $rewardValueLabel'
                    : 'باقي $rewardRemaining توصيلة للمكافأة ($rewardValueLabel)',
                style: STextStyles.label.copyWith(color: context.sc.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: SSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(SRadius.pill),
            child: LinearProgressIndicator(
              value: nextIsReward ? 1 : doneInCycle / rewardEvery,
              minHeight: 8,
              backgroundColor: context.sc.surfaceMuted,
              color: SColors.amber500,
            ),
          ),
          const SizedBox(height: SSpacing.xs),
          Text('توصيلات اليوم: $todayDeliveries • العدّاد يُصفَّر يومياً',
              style: STextStyles.caption.copyWith(color: context.sc.textSecondary)),
        ],
      ),
    );
  }
}
