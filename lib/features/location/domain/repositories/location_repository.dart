abstract class LocationRepository {
  /// تحديث إحداثيات السائق الحية على الخادم
  Future<void> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  });
}
