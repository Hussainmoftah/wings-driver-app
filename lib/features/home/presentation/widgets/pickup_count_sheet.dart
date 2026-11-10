import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/driver_palette.dart';
import '../../../orders/data/driver_order_model.dart';
import '../../../orders/data/handover_proof.dart';
import '../cubit/driver_home_cubit.dart';

/// عند الاستلام من المطعم: السائق يعدّ القطع والمشروبات بنفسه ويكتبها.
/// إذا خالف العدد الطلب تُعرض له الأصناف ليراجع المطعم، أو يبلغ عن نقص فعلي وينطلق.
/// يرجع true إذا انطلق السائق بالطلب.
class PickupCountSheet extends StatefulWidget {
  final DriverOrderModel order;

  const PickupCountSheet({super.key, required this.order});

  static Future<bool> show(BuildContext context, DriverOrderModel order) async {
    final cubit = context.read<DriverHomeCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.dp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PickupCountSheet(order: order),
      ),
    );
    return result == true;
  }

  @override
  State<PickupCountSheet> createState() => _PickupCountSheetState();
}

class _PickupCountSheetState extends State<PickupCountSheet> {
  static const _max = 99;

  int _pieces = 0;
  int _drinks = 0;
  bool _sending = false;
  PickupMismatchException? _mismatch;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  TextStyle _t(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Tajawal',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  Future<void> _send({String? shortageNote}) async {
    setState(() => _sending = true);
    try {
      final ok = await context.read<DriverHomeCubit>().updateOrderStatus(
        'on_the_way',
        widget.order.id,
        pickup: PickupCount(
          pieces: _pieces,
          drinks: _drinks,
          shortageNote: shortageNote,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        // السبب يظهر في الشاشة خلف النافذة
        Navigator.of(context).pop(false);
      }
    } on PickupMismatchException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _mismatch = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dp;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: _mismatch == null ? _counter(p) : _mismatchView(p, _mismatch!),
      ),
    );
  }

  Widget _counter(DriverPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'عُدّ الطلب قبل ما تنطلق',
          style: _t(20, p.ink, weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'افتح الكيس وعُدّ كل القطع بنفسك، ومنها كم مشروب. '
          'لو العدد ناقص راجع المطعم قبل ما تمشي.',
          style: _t(15, p.body),
        ),
        const SizedBox(height: 20),
        _stepper(
          p,
          label: 'عدد القطع كلها',
          value: _pieces,
          onChanged: (v) => setState(() {
            _pieces = v;
            if (_drinks > v) _drinks = v;
          }),
        ),
        const SizedBox(height: 14),
        _stepper(
          p,
          label: 'منها مشروبات',
          value: _drinks,
          max: _pieces,
          onChanged: (v) => setState(() => _drinks = v),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _sending || _pieces == 0 ? null : () => _send(),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'العدد صحيح، انطلق',
                    style: _t(17, Colors.white, weight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _stepper(
    DriverPalette p, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int max = _max,
  }) {
    Widget button(IconData icon, VoidCallback? onTap) => SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: _sending ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: p.fieldBorder),
        ),
        child: Icon(icon, color: p.ink),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: _t(16, p.ink, weight: FontWeight.w700)),
          ),
          button(
            Icons.remove_rounded,
            value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: _t(24, p.ink, weight: FontWeight.w800),
            ),
          ),
          button(
            Icons.add_rounded,
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _mismatchView(DriverPalette p, PickupMismatchException m) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline_rounded, color: p.errorText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'العدد مش مطابق',
                style: _t(20, p.errorText, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'كتبت $_pieces قطعة منها $_drinks مشروب، والطلب ${m.expectedPieces} قطعة '
          'منها ${m.expectedDrinks} مشروب. راجع الأصناف مع المطعم:',
          style: _t(15, p.body),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (final i in m.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        i.isDrink
                            ? Icons.local_drink_outlined
                            : Icons.lunch_dining_outlined,
                        size: 20,
                        color: p.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          i.restaurant == null
                              ? i.name
                              : '${i.name} · ${i.restaurant}',
                          style: _t(15, p.ink),
                        ),
                      ),
                      Text(
                        '× ${i.quantity}',
                        style: _t(16, p.ink, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _sending
                ? null
                : () => setState(() {
                    _mismatch = null;
                  }),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'راجعت المطعم، أعِد العدّ',
              style: _t(16, Colors.white, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'في نقص فعلاً والمطعم ما عندهش؟',
          style: _t(15, p.ink, weight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          style: _t(15, p.ink),
          decoration: InputDecoration(
            hintText: 'مثال: الكولا خالصة عند المطعم',
            filled: true,
            fillColor: p.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _sending || _note.text.trim().length < 3
                ? null
                : () => _send(shortageNote: _note.text.trim()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.busyOrange,
              side: const BorderSide(color: AppColors.busyOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'أبلغ عن النقص وانطلق',
              style: _t(16, AppColors.busyOrange, weight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
