import '../../data/driver_profile_model.dart';

abstract class ProfileRepository {
  /// جلب الملف التشغيلي وحالة الوردية للسائق
  Future<DriverProfileModel> getProfile();

  /// تبديل حالة اتصال السائق (Online / Offline)
  Future<DriverProfileModel> updateDutyStatus(bool isOnline);
}
