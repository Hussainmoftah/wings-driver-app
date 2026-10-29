import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/driver_palette.dart';
import '../../../orders/data/driver_order_model.dart';

/// بطاقة الطلب الحالي: شريط الحالة، الوجهة الحالية بخط كبير، المبلغ المطلوب تحصيله، وزر واحد للخطوة التالية.
/// الألوان من DriverPalette فتعمل في الوضعين النهاري والليلي.
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
  bool _itemsExpanded = false;

  DriverOrderModel get o => widget.order;
  DriverPalette get p => context.dp;

  bool get _isReady => const ['ready', 'ready_for_pickup'].contains(o.status);
  bool get _isOnTheWay => const ['on_the_way', 'on_delivery'].contains(o.status);

  String _money(double v) => v.toStringAsFixed(2);

  TextStyle _t(double size, Color color, {FontWeight weight = FontWeight.w400, double? height}) =>
      TextStyle(fontFamily: 'Tajawal', fontSize: size, fontWeight: weight, color: color, height: height);

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الاتصال. الرقم: $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('طلب ${o.orderNumber}', style: _t(18, p.ink, weight: FontWeight.w800)),
              if (o.isMultiRestaurant) ...[
                const SizedBox(width: 8),
                _chip('عدة مطاعم', p.navySoft, p.navyInk),
              ],
              const Spacer(),
              Text('أجرك ${_money(o.deliveryFee)} د.ل', style: _t(15, p.successText, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          _statusStrip(),
          const SizedBox(height: 14),
          if (_isOnTheWay) ..._deliveryStage() else ..._pickupStage(),
          const SizedBox(height: 16),
          _actionButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ stages

  List<Widget> _pickupStage() {
    final stops = o.isMultiRestaurant && o.stops.isNotEmpty;
    return [
      if (stops)
        ...o.stops.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _place(
              label: 'استلم من (محطة ${s.stopSequence})',
              name: s.restaurantName ?? o.restaurantName ?? 'المطعم',
              address: s.restaurantAddress ?? o.restaurantAddress,
              phone: s.restaurantPhone ?? o.restaurantPhone,
              onMap: widget.onFocusRestaurantOnMap,
            ),
          ),
        )
      else
        _place(
          label: 'استلم من',
          name: o.restaurantName ?? 'المطعم',
          address: o.restaurantAddress,
          phone: o.restaurantPhone,
          onMap: widget.onFocusRestaurantOnMap,
        ),
      const SizedBox(height: 12),
      _itemsSection(),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سلّم إلى', style: _t(14, p.muted)),
                  Text(
                    [o.customerName, o.customerAddress].where((x) => x != null && x.trim().isNotEmpty).join(' · '),
                    style: _t(16, p.ink, weight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            o.amountToCollect > 0
                ? _chip('حصّل ${_money(o.amountToCollect)}', p.cashSoft, p.cashText)
                : _chip('مدفوع مسبقاً', p.successSoft, p.successText),
          ],
        ),
      ),
    ];
  }

  List<Widget> _deliveryStage() {
    return [
      _place(
        label: 'سلّم إلى',
        name: o.customerName ?? 'الزبون',
        address: o.customerAddress,
        phone: o.customerPhone,
        onMap: widget.onFocusCustomerOnMap,
      ),
      const SizedBox(height: 14),
      if (o.amountToCollect > 0)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.cash, width: 3),
          ),
          child: Column(
            children: [
              Text('حصّل من الزبون نقداً', style: _t(16, p.cashText, weight: FontWeight.w700)),
              Text('${_money(o.amountToCollect)} د.ل', style: _t(44, p.cashText, weight: FontWeight.w800, height: 1.2)),
              Text('الطلب ${_money(o.subtotal - o.discount)} + التوصيل ${_money(o.deliveryFee)}', style: _t(15, p.body)),
            ],
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.successSoft, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: p.successText),
              const SizedBox(width: 10),
              Expanded(
                child: Text('الطلب مدفوع مسبقاً، لا تحصّل أي مبلغ', style: _t(16, p.successText, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      _itemsSection(),
    ];
  }

  // ------------------------------------------------------------------ parts

  Widget _statusStrip() {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String text;
    if (_isOnTheWay) {
      bg = p.navySoft;
      fg = p.navyInk;
      icon = Icons.two_wheeler_rounded;
      text = 'في الطريق للزبون';
    } else if (_isReady) {
      bg = p.readySoft;
      fg = p.readyText;
      icon = Icons.check_circle_rounded;
      text = 'الطلب جاهز، استلمه من المطعم';
    } else {
      bg = p.surfaceMuted;
      fg = p.body;
      icon = Icons.soup_kitchen_outlined;
      text = 'المطعم يحضّر الطلب، توجّه للمطعم';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _t(17, fg, weight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _place({
    required String label,
    required String name,
    required String? address,
    required String? phone,
    VoidCallback? onMap,
  }) {
    final hasPhone = phone != null && phone.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _t(14, p.muted)),
        Text(name, style: _t(21, p.ink, weight: FontWeight.w800)),
        if (address != null && address.trim().isNotEmpty) Text(address, style: _t(15, p.body, height: 1.4)),
        if (hasPhone || onMap != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasPhone) Expanded(child: _outlineButton(icon: Icons.call_rounded, label: 'اتصل', onTap: () => _call(phone))),
              if (hasPhone && onMap != null) const SizedBox(width: 10),
              if (onMap != null) Expanded(child: _outlineButton(icon: Icons.map_outlined, label: 'على الخريطة', onTap: onMap)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _itemsSection() {
    final units = o.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: p.ink, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('الأصناف ($units)', style: _t(16, p.ink, weight: FontWeight.w800))),
                  Icon(_itemsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: p.ink),
                ],
              ),
            ),
          ),
          if (_itemsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in o.items)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity} × ${item.productName}', style: _t(16, p.ink, weight: FontWeight.w700)),
                          if (item.notes != null && item.notes!.trim().isNotEmpty) Text('ملاحظة: ${item.notes}', style: _t(14, p.body)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton() {
    late final String label;
    late final IconData icon;
    late final Color bg;
    String? next;
    if (_isOnTheWay) {
      next = 'delivered';
      bg = AppColors.onlineGreen;
      icon = Icons.check_rounded;
      label = o.amountToCollect > 0 ? 'استلمت ${_money(o.amountToCollect)} وسلّمت الطلب' : 'سلّمت الطلب';
    } else if (_isReady) {
      next = 'on_the_way';
      bg = p.navy;
      icon = Icons.arrow_back_rounded;
      label = 'استلمت الطلب، انطلق';
    } else {
      bg = p.disabled;
      icon = Icons.hourglass_top_rounded;
      label = 'انتظر حتى يجهز الطلب';
    }
    final target = next;

    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: widget.isUpdating || target == null ? null : () => widget.onUpdateStatus(target, o.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: target == null ? p.disabled : bg.withValues(alpha: 0.7),
          disabledForegroundColor: target == null ? p.disabledText : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: widget.isUpdating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.w800))),
                ],
              ),
      ),
    );
  }

  Widget _outlineButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.navyInk,
          side: BorderSide(color: p.navyInk, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: _t(15, fg, weight: FontWeight.w800)),
      );
}
