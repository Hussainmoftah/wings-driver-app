import 'package:flutter/material.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../home/presentation/screens/driver_home_screen.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import 'driver_login_screen.dart';

/// بوابة التحقق من الجلسة عند إقلاع التطبيق (DriverAuthGate).
/// 
/// تعتمد كلياً على العقود المعمارية (Domain Repositories):
/// 1. التحقق من وجود توكن صالح عبر [AuthRepository.hasValidToken]
/// 2. استعلام الملف الشخصي عبر [ProfileRepository.getProfile]:
///    - نجاح -> التوجيه للشاشة الرئيسية (DriverHomeScreen).
///    - 401 UnauthorizedException -> تفريغ الجلسة والتوجيه لشاشة تسجيل الدخول.
///    - 403 ForbiddenException -> تفريغ الجلسة والتوجيه للدخول برسالة حظر/عدم صلاحية.
///    - Network/Server Error -> الحفاظ على التوكن والانتقال للرئيسية في وضع عدم الاتصال.
class DriverAuthGate extends StatefulWidget {
  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;

  const DriverAuthGate({
    super.key,
    this.authRepository,
    this.profileRepository,
  });

  @override
  State<DriverAuthGate> createState() => _DriverAuthGateState();
}

class _DriverAuthGateState extends State<DriverAuthGate> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _profileRepository = widget.profileRepository ?? ProfileRepositoryImpl();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasToken = await _authRepository.hasValidToken();

    if (!hasToken) {
      if (!mounted) return;
      _navigateToLogin();
      return;
    }

    try {
      await _profileRepository.getProfile();

      if (!mounted) return;
      _navigateToHome();
    } on UnauthorizedException {
      if (!mounted) return;
      await _authRepository.logout();
      _navigateToLogin(errorMessage: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.');
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      await _authRepository.logout();
      _navigateToLogin(errorMessage: e.message);
    } catch (e) {
      // خطأ شبكة / انقطاع اتصال أو 500 مؤقت -> الحفاظ على التوكن والانتقال للرئيسية
      if (!mounted) return;
      _navigateToHome();
    }
  }

  void _navigateToLogin({String? errorMessage}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DriverLoginScreen(initialErrorMessage: errorMessage),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DriverHomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052FF), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0052FF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كابتن وينجز | Wings Driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'جاري التحقق من بيانات الجلسة...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
