abstract class AuthRepository {
  /// تسجيل الدخول والتحقق من دور السائق وحفظ التوكن
  Future<Map<String, dynamic>> login(String email, String password);

  /// تسجيل الخروج وحذف التوكن وتفريغ الجلسة
  Future<void> logout();

  /// جلب التوكن المخزن محلياً
  Future<String?> getToken();

  /// التحقق من وجود توكن محلي
  Future<bool> hasValidToken();
}
