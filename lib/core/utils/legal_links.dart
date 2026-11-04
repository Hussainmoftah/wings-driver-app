import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحات الخصوصية وشروط السائق المنشورة على موقع سديم (تطلبها Apple وGoogle داخل التطبيق)
class LegalLinks {
  LegalLinks._();

  static const _base = 'https://alsadeem.com.ly';
  static const privacy = '$_base/privacy';
  static const terms = '$_base/terms/captain';

  /// تُفتح داخل التطبيق (متصفح مدمج)
  static Future<void> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
}

/// "بتسجيل الدخول توافق على الشروط وسياسة الخصوصية" والرابطان قابلان للضغط
class LegalConsentText extends StatefulWidget {
  final Color linkColor;
  final Color textColor;

  const LegalConsentText({super.key, required this.linkColor, required this.textColor});

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  final _terms = TapGestureRecognizer()..onTap = () => LegalLinks.open(LegalLinks.terms);
  final _privacy = TapGestureRecognizer()..onTap = () => LegalLinks.open(LegalLinks.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(color: widget.linkColor, fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, height: 1.6, color: widget.textColor),
        children: [
          const TextSpan(text: 'بتسجيل الدخول توافق على '),
          TextSpan(text: 'شروط السائق', style: link, recognizer: _terms),
          const TextSpan(text: ' و'),
          TextSpan(text: 'سياسة الخصوصية', style: link, recognizer: _privacy),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
