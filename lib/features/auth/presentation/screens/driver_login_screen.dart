import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../home/presentation/screens/driver_home_screen.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

class DriverLoginScreen extends StatefulWidget {
  final String? initialErrorMessage;
  final AuthRepository? authRepository;

  const DriverLoginScreen({
    super.key,
    this.initialErrorMessage,
    this.authRepository,
  });

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthRepository _authRepository;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to Driver Home Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      );
    } on UnauthorizedException {
      if (mounted) {
        setState(() {
          _errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        });
      }
    } on ForbiddenException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر الاتصال بخادم وينجز، يرجى التحقق من اتصال الإنترنت.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر الاتصال بخادم وينجز، يرجى التحقق من اتصال الإنترنت.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fillDriver(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildLoginForm(),
                    const SizedBox(height: 24),
                    _buildQuickDemoPills(),
                    const SizedBox(height: 28),
                    _buildFooterSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0052FF), Color(0xFF38BDF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0052FF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'كابتن وينجز',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'بوابة كباتن التوصيل والأسطول الذكي',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تسجيل الدخول',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'أدخل بيانات حساب الكابتن لبدء استقبال الطلبات',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            const Text(
              'البريد الإلكتروني / اسم المستخدم',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'driver1@wings.ly',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 20),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            const Text(
              'كلمة المرور',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Remember me & Forgot password
            Row(
              mainAxisAlignment: conscienceAlignment(),
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        activeColor: const Color(0xFF0052FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        side: const BorderSide(color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'تذكرني',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF0052FF).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFF0052FF).withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.login_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'تسجيل الدخول وبدء الوردية',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MainAxisAlignment conscienceAlignment() => MainAxisAlignment.spaceBetween;

  Widget _buildQuickDemoPills() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 16),
              SizedBox(width: 6),
              Text(
                'حسابات كباتن تجريبية سريعة (بنقرة واحدة):',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDemoChip(
                name: 'محمود (دراجة)',
                email: 'driver1@wings.ly',
                isSelected: _emailController.text == 'driver1@wings.ly',
              ),
              _buildDemoChip(
                name: 'عبد السلام (سيارة)',
                email: 'driver2@wings.ly',
                isSelected: _emailController.text == 'driver2@wings.ly',
              ),
              _buildDemoChip(
                name: 'فرج (دراجة)',
                email: 'driver3@wings.ly',
                isSelected: _emailController.text == 'driver3@wings.ly',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip({
    required String name,
    required String email,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _fillDriver(email, 'password'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052FF) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF475569),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        TextButton(
          onPressed: _showJoinFleetSheet,
          child: const Text(
            'تريد الانضمام لأسطول وينجز ككابتن جديد؟ قدم طلبك',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.headset_mic_rounded, color: Color(0xFF64748B), size: 14),
            SizedBox(width: 4),
            Text(
              'غرفة دعم العمليات: 0910000002',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.support_agent_rounded, color: Color(0xFF0052FF)),
            SizedBox(width: 8),
            Text(
              'استعادة الحساب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ],
        ),
        content: const Text(
          'لأسباب أمنية وتشغيلية خاصة بأسطول السائقين، يتم إعادة تعيين كلمة المرور بالتواصل المباشر مع مشرف العمليات.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showJoinFleetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.two_wheeler_rounded, color: Color(0xFF0052FF), size: 28),
                SizedBox(width: 10),
                Text(
                  'شروط الانضمام لأسطول وينجز',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRequirementItem('رخصة قيادة سارية المفعول (دراجة نارية أو سيارة).'),
            _buildRequirementItem('كتيب ملكية المركبة أو توكيل رسمي معتمد.'),
            _buildRequirementItem('الرقم الوطني والهوية الشخصية.'),
            _buildRequirementItem('هاتف ذكي بنظام أندرويد أو iOS يدعم الملاحة اللحظية.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('تواصل مع إدارة التوظيف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
