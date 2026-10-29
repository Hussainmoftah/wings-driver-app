import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_constants.dart';
import '../network/dio_client.dart';

/// والتطبيق في الخلفية أو مغلق يعرض Android إشعار FCM بنفسه (الخادم يرسل
/// notification)، على القناة والأيقونة المحددتين في AndroidManifest.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// إشعارات الدفع (FCM): التطبيق مفتوح أو في الخلفية، وتسجيل توكن الجهاز
/// في الخادم بعد الدخول وحذفه عند الخروج حتى لا تصل إشعارات الحساب لغيره.
///
/// Android فقط حالياً: google-services.json موجود لـ Android وحده، وعلى غيره
/// (أو في الاختبارات) تبقى كل الدوال بلا أثر.
class PushNotifications {
  PushNotifications._();
  static final instance = PushNotifications._();

  static const _channel = AndroidNotificationChannel(
    'sadeem_notifications',
    'إشعارات سديم كابتن',
    description: 'طلبات التوصيل وتحديثاتها',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _registeredToken;

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notification'),
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // التطبيق مفتوح: Android لا يعرض إشعار FCM بنفسه، فنعرضه نحن
      FirebaseMessaging.onMessage.listen(_showInApp);
      // توكن التسجيل الكلاسيكي: الخادم يرسل إلى message.token في FCM v1، أما
      // register()/onRegistered البديلة فتعطي معرّف تثبيت (FID) لا يدعمه الخادم.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (_registeredToken != null) unawaited(_sendToken(token));
      });
      _ready = true;
    } catch (e) {
      debugPrint('Push notifications unavailable: $e');
    }
  }

  /// بعد الدخول أو فتح التطبيق بجلسة محفوظة: يطلب الإذن (Android 13+) ويسجل التوكن
  Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (e) {
      debugPrint('Device token registration failed: $e');
    }
  }

  /// قبل الخروج والتوكن ما زال صالحاً: يحذف الجهاز من حساب المستخدم في الخادم
  Future<void> unregisterDevice() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (!_ready || token == null) return;
    try {
      await DioClient().dio
          .delete(ApiConstants.deviceToken, data: {'token': token})
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // الخادم يعطّل التوكن نفسه عند تسجيله لحساب آخر
    }
  }

  Future<void> _sendToken(String token) async {
    await DioClient().dio.post(
      ApiConstants.deviceToken,
      data: {'token': token, 'platform': 'android'},
    );
    _registeredToken = token;
  }

  void _showInApp(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    unawaited(
      _local.show(
        id: message.messageId?.hashCode ?? notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_notification',
          ),
        ),
      ),
    );
  }
}
