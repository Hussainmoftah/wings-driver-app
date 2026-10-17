import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// مُسجِّل طلبات واستجابات الـ API لأغراض التشخيص أثناء التطوير.
///
/// يكتب عبر `dart:developer` فيظهر مصنفاً باسم [tag] وبمستوى خطورة يتبع
/// حالة الاستجابة، ما يتيح فرزه وتصفيته في DevTools.
///
/// يُسجَّل لكل نداء مدخلان: الطلب الصادر، ثم الاستجابة أو الخطأ ومعهما
/// المدة الزمنية. تُحجب الحقول السرية وتُقتطع الأجسام الطويلة.
///
/// التسجيل كامل داخل `kDebugMode`، فلا يصدر عنه أي إخراج في نسخة الإصدار.
///
/// يُضاف كآخر اعتراض في السلسلة حتى يرى الطلب بترويسته النهائية بعد إضافة
/// التوكن، وحتى لا يسبق منطق تجديد الجلسة.
class ApiLogger extends Interceptor {
  ApiLogger({
    this.tag = 'API',
    this.logBodies = true,
    this.maxBodyChars = 2000,
  });

  /// اسم المُسجِّل كما يظهر في DevTools، ويميز التطبيق عند تشغيل أكثر من واحد.
  final String tag;

  /// تسجيل أجسام الطلب والاستجابة، أو الاكتفاء بسطر واحد لكل نداء.
  final bool logBodies;

  /// الحد الأقصى لطول الجسم المسجَّل قبل الاقتطاع.
  final int maxBodyChars;

  /// مستويات الخطورة بترتيب `package:logging` المتعارف عليه.
  static const int _levelInfo = 800;
  static const int _levelWarning = 900;
  static const int _levelSevere = 1000;

  /// الحقول التي تُستبدل قيمها بـ [_placeholder] على أي عمق من التداخل.
  static const Set<String> _secretKeys = {
    'password',
    'password_confirmation',
    'current_password',
    'new_password',
    'token',
    'access_token',
    'refresh_token',
    'plain_text_token',
    'api_token',
    'secret',
    'authorization',
    'credit_card',
    'cvv',
  };

  static const String _placeholder = '[REDACTED]';
  static const String _startKey = '__api_logger_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();

    if (kDebugMode) {
      final hasAuth = options.headers.containsKey('Authorization');
      developer.log(
        _compose(
          '→ ${options.method} ${options.uri}${hasAuth ? '' : '  (no auth)'}',
          'request',
          options.data,
        ),
        name: tag,
        level: _levelInfo,
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final request = response.requestOptions;
      final status = response.statusCode ?? 0;

      developer.log(
        _compose(
          '← $status ${request.method} ${request.path} (${_elapsed(request)})',
          'response',
          response.data,
        ),
        name: tag,
        level: _levelFor(status),
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = err.requestOptions;
      final status = err.response?.statusCode;

      developer.log(
        _compose(
          '✖ ${status ?? err.type.name} ${request.method} ${request.path} '
              '(${_elapsed(request)})',
          'error body',
          err.response?.data,
        ),
        name: tag,
        level: status == null ? _levelSevere : _levelFor(status),
        error: err,
        stackTrace: err.stackTrace,
      );
    }

    handler.next(err);
  }

  /// اشتقاق مستوى الخطورة من حالة الاستجابة.
  int _levelFor(int status) {
    if (status >= 500) return _levelSevere;
    if (status >= 400) return _levelWarning;
    return _levelInfo;
  }

  /// دمج سطر العنوان مع الجسم في مدخل سجل واحد.
  String _compose(String headline, String bodyLabel, dynamic body) {
    if (!logBodies || body == null) return headline;

    final formatted = _format(body);
    if (formatted.isEmpty) return headline;

    return '$headline\n  $bodyLabel: $formatted';
  }

  /// المدة المنقضية منذ إرسال الطلب.
  String _elapsed(RequestOptions options) {
    final startedAt = options.extra[_startKey];
    if (startedAt is! DateTime) return '—';
    return '${DateTime.now().difference(startedAt).inMilliseconds}ms';
  }

  /// تحويل الجسم إلى نص JSON مقروء بعد الحجب والاقتطاع.
  String _format(dynamic body) {
    dynamic value = body;

    if (value is FormData) {
      value = <String, dynamic>{
        for (final field in value.fields) field.key: field.value,
        for (final file in value.files)
          file.key: '[file: ${file.value.filename ?? 'unnamed'}]',
      };
    } else if (value is String) {
      if (value.isEmpty) return '';
      try {
        value = jsonDecode(value);
      } catch (_) {
        return _cap(value);
      }
    }

    try {
      return _cap(jsonEncode(_redact(value)));
    } catch (_) {
      return _cap(value.toString());
    }
  }

  /// استبدال قيم الحقول السرية مع الحفاظ على بنية الجسم.
  dynamic _redact(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString():
              _secretKeys.contains(entry.key.toString().toLowerCase())
                  ? _placeholder
                  : _redact(entry.value),
      };
    }

    if (value is List) {
      return value.map(_redact).toList();
    }

    return value;
  }

  /// اقتطاع النصوص الطويلة مع بيان عدد المحارف المحذوفة.
  String _cap(String text) {
    if (text.length <= maxBodyChars) return text;
    final dropped = text.length - maxBodyChars;
    return '${text.substring(0, maxBodyChars)}…[truncated $dropped chars]';
  }
}
