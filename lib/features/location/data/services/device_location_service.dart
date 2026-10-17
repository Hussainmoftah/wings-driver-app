import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:geolocator/geolocator.dart';

/// سبب تعذّر تشغيل تتبّع الموقع، لعرض رسالة مناسبة للمندوب.
enum LocationUnavailableReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,

  /// لا توجد إضافة موقع على هذه المنصة (مثل بيئة الاختبار أو سطح المكتب).
  unsupportedPlatform,
}

/// يغلّف حزمة geolocator: التحقق من الأذونات وبثّ الموقع اللحظي.
class DeviceLocationService {
  /// أقل مسافة (بالأمتار) قبل إصدار تحديث جديد؛ تمنع الضجيج أثناء التوقف.
  static const int defaultDistanceFilterMeters = 10;

  /// يتحقق من خدمة الموقع والأذونات، ويعيد null عند الجاهزية أو سبب المنع.
  Future<LocationUnavailableReason?> ensureReady() async {
    // تعذّر الوصول إلى الموقع يجب ألا يُسقط الشاشة أبدًا، لذا تُترجم كل
    // الأخطاء إلى سبب يمكن عرضه بدل أن تُرمى للأعلى.
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationUnavailableReason.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return switch (permission) {
        LocationPermission.denied => LocationUnavailableReason.permissionDenied,
        LocationPermission.deniedForever =>
          LocationUnavailableReason.permissionDeniedForever,
        _ => null,
      };
    } on MissingPluginException catch (e) {
      debugPrint('DeviceLocationService: no platform implementation ($e)');
      return LocationUnavailableReason.unsupportedPlatform;
    } catch (e, st) {
      debugPrint('DeviceLocationService.ensureReady failed: $e\n$st');
      return LocationUnavailableReason.unsupportedPlatform;
    }
  }

  /// بثّ لحظي لموقع الجهاز. يتوقف البث تلقائيًا عند إلغاء الاشتراك.
  Stream<Position> watchPosition({
    int distanceFilterMeters = defaultDistanceFilterMeters,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).handleError((Object e, StackTrace st) {
      // لا نُسقط الاشتراك: الأخطاء العابرة (فقدان الإشارة) شائعة أثناء القيادة.
      debugPrint('DeviceLocationService stream error: $e\n$st');
    });
  }

  /// آخر موقع معروف، لعرض شيء فوري قبل وصول أول تحديث من البث.
  Future<Position?> lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('DeviceLocationService.lastKnown failed: $e');
      return null;
    }
  }
}
