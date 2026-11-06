import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_service.dart';

/// أرقام الدعم والعمليات: تعدّلها الإدارة من لوحة التحكم (GET /support-contacts).
class SupportContacts {
  SupportContacts._();

  static Future<List<String>> _phones() async {
    final res = await ApiService.get('/support-contacts');
    final data = res.data is Map ? res.data['data'] : null;
    final phones = data is Map ? data['phones'] : null;
    return phones is List ? phones.map((p) => '$p').where((p) => p.isNotEmpty).toList() : [];
  }

  /// زر «اتصال»: رقم واحد يتصل مباشرة، ورقمان يختار السائق بينهما.
  static Future<void> call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    List<String> phones;
    try {
      phones = await _phones();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذر جلب رقم الدعم، تأكد من الإنترنت')));
      return;
    }
    if (!context.mounted) return;
    if (phones.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('رقم الدعم غير متاح حالياً')));
      return;
    }

    final phone = phones.length == 1
        ? phones.first
        : await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('اتصل بالدعم والعمليات',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  for (final p in phones)
                    ListTile(
                      leading: const Icon(Icons.phone_rounded),
                      title: Text(p, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                      onTap: () => Navigator.pop(ctx, p),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
    if (phone == null) return;

    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok) messenger.showSnackBar(SnackBar(content: Text('تعذر فتح الاتصال. الرقم: $phone')));
  }
}
