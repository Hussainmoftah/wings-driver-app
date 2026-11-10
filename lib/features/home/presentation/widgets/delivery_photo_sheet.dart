import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/driver_palette.dart';
import '../../../orders/data/driver_order_model.dart';
import '../../../orders/data/handover_proof.dart';
import '../cubit/driver_home_cubit.dart';

/// عند التسليم: صورة الطلب في الكيس من الكاميرا مباشرة (لا من المعرض)، مضغوطة.
/// إذا تعذر التصوير يختار السائق السبب. الصورة تُحذف من الخادم بعد 10 ساعات ما لم يشتكِ الزبون.
/// يرجع true إذا سُلّم الطلب.
class DeliveryPhotoSheet extends StatefulWidget {
  final DriverOrderModel order;

  const DeliveryPhotoSheet({super.key, required this.order});

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
        child: DeliveryPhotoSheet(order: order),
      ),
    );
    return result == true;
  }

  @override
  State<DeliveryPhotoSheet> createState() => _DeliveryPhotoSheetState();
}

class _DeliveryPhotoSheetState extends State<DeliveryPhotoSheet> {
  static const _maxSide = 1280.0;
  static const _quality = 60;
  static const _maxBytes = 1400 * 1024; // الخادم يقبل حتى 1.5 ميغابايت
  static const _reasons = [
    'الكاميرا لا تعمل',
    'الزبون استلم قبل التصوير',
    'سبب آخر',
  ];

  Uint8List? _photo;
  bool _sending = false;
  bool _showReasons = false;
  String? _reason;
  final _otherReason = TextEditingController();

  @override
  void dispose() {
    _otherReason.dispose();
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: AppColors.offlineRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
      );
    } catch (_) {
      _toast('تعذر فتح الكاميرا، تحقق من إذن الكاميرا في الإعدادات');
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      _toast('الصورة كبيرة جداً، صوّر مرة ثانية');
      return;
    }
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _showReasons = false;
      _reason = null;
    });
  }

  String? get _skipReason {
    if (_reason == null) return null;
    if (_reason != _reasons.last) return _reason;
    final text = _otherReason.text.trim();
    return text.length >= 3 ? text : null;
  }

  Future<void> _deliver() async {
    final cubit = context.read<DriverHomeCubit>();
    setState(() => _sending = true);
    final ok = await cubit.updateOrderStatus(
      'delivered',
      widget.order.id,
      delivery: DeliveryProof(
        photo: _photo,
        skipReason: _photo == null ? _skipReason : null,
        latitude: cubit.state.driverLat,
        longitude: cubit.state.driverLng,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.dp;
    final canDeliver = !_sending && (_photo != null || _skipReason != null);
    final collect = widget.order.amountToCollect;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'صوّر الطلب في الكيس',
              style: _t(20, p.ink, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'صوّر الكيس بس، بدون أشخاص وبدون واجهة البيت. '
              'الصورة تثبت إن الطلب وصل سليم، وتنحذف بعد 10 ساعات.',
              style: _t(15, p.body),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _sending ? null : _takePhoto,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photo != null
                    ? Image.memory(_photo!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 48,
                            color: p.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لفتح الكاميرا',
                            style: _t(16, p.ink, weight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            if (_photo != null)
              TextButton.icon(
                onPressed: _sending ? null : _takePhoto,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('صوّر من جديد', style: _t(15, p.navyInk)),
              ),
            if (_photo == null) ...[
              TextButton(
                onPressed: _sending
                    ? null
                    : () => setState(() => _showReasons = !_showReasons),
                child: Text(
                  'تعذر التصوير؟',
                  style: _t(15, p.muted, weight: FontWeight.w700),
                ),
              ),
              if (_showReasons) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _reasons)
                      ChoiceChip(
                        label: Text(r, style: _t(14, p.ink)),
                        selected: _reason == r,
                        onSelected: _sending
                            ? null
                            : (v) => setState(() => _reason = v ? r : null),
                      ),
                  ],
                ),
                if (_reason == _reasons.last) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherReason,
                    maxLength: 200,
                    onChanged: (_) => setState(() {}),
                    style: _t(15, p.ink),
                    decoration: InputDecoration(
                      hintText: 'اكتب السبب',
                      filled: true,
                      fillColor: p.field,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: canDeliver ? _deliver : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onlineGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        collect > 0
                            ? 'استلمت ${collect.toStringAsFixed(2)} د.ل وسلّمت الطلب'
                            : 'سلّمت الطلب',
                        style: _t(17, Colors.white, weight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
