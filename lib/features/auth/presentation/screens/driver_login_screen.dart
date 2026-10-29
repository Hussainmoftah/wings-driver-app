import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/driver_palette.dart';
import '../../../home/presentation/screens/driver_home_screen.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

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
          _errorMessage =
              'تعذر الاتصال بخادم سديم، يرجى التحقق من اتصال الإنترنت.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'تعذر الاتصال بخادم سديم، يرجى التحقق من اتصال الإنترنت.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // تصميم عالي التباين بالوضعين النهاري والليلي: رأس كحلي، حقول كبيرة، وزر واحد واضح
  DriverPalette get _p => context.dp;
  Color get _navy => _p.navy;
  Color get _ink => _p.ink;
  Color get _muted => _p.muted;
  Color get _line => _p.fieldBorder;
  Color get _ground => _p.ground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: _buildLoginForm(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: _buildJoinBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _p.navyCard,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 36, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF283A75), size: 30),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سديم كابتن', style: TextStyle(fontFamily: 'Tajawal', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('تطبيق مناديب التوصيل', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: Color(0xFFDCE2F5))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'أهلاً بيك، سجّل دخولك وابدأ دوامك.',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, height: 1.6, color: Colors.white),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 2]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: 'Tajawal', color: _muted, fontSize: 16),
      filled: true,
      fillColor: _p.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      suffixIcon: suffix,
      enabledBorder: border(_line),
      focusedBorder: border(_navy, 2.5),
      errorBorder: border(SColors.red600),
      focusedErrorBorder: border(SColors.red600, 2.5),
      errorStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: _p.errorText),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
      );

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _p.errorSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: _p.errorText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!, style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700, color: _p.errorText)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          _label('البريد الإلكتروني'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 17, color: _ink),
            decoration: _fieldDecoration(hint: 'driver@sadeem.ly'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'اكتب بريدك الإلكتروني';
              if (!value.contains('@')) return 'البريد الإلكتروني غير صحيح';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _label('كلمة المرور'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 17, color: _ink),
            decoration: _fieldDecoration(
              suffix: IconButton(
                tooltip: _obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'اكتب كلمة المرور' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _navy.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Tajawal', fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: _navy),
              child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _p.line, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: _p.cashSoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.person_add_alt_1_outlined, color: _p.cashText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مش مسجل معانا؟', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                Text('قدّم طلبك كمندوب توصيل في دقيقة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: _muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _showJoinFleetSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4401A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('قدّم الآن', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.dp.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.support_agent_rounded, color: SColors.brand),
            SizedBox(width: 8),
            Text(
              'استعادة الحساب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        content: Text(
          'لأسباب أمنية وتشغيلية خاصة بأسطول السائقين، يتم إعادة تعيين كلمة المرور بالتواصل المباشر مع مشرف العمليات.',
          style: TextStyle(
            fontSize: 13,
            color: context.dp.muted,
            fontFamily: 'Tajawal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إغلاق',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// نموذج التقديم صفحة ويب واحدة (نفس رابط الإعلانات) تُفتح داخل التطبيق
  Future<void> _openJoinPage() async {
    final opened = await launchUrl(
      Uri.parse(ApiConstants.joinPageUrl),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة التقديم، حاول مرة أخرى.')),
      );
    }
  }

  void _showJoinFleetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.dp.surface,
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
                Icon(Icons.two_wheeler_rounded, color: SColors.brand, size: 28),
                SizedBox(width: 10),
                Text(
                  'شروط الانضمام لأسطول سديم',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRequirementItem(
              'رخصة قيادة سارية المفعول (دراجة نارية أو سيارة).',
            ),
            _buildRequirementItem('كتيب ملكية المركبة أو توكيل رسمي معتمد.'),
            _buildRequirementItem(
              'هاتف ذكي بنظام أندرويد أو iOS يدعم الملاحة اللحظية.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openJoinPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'قدّم طلبك الآن',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          const Icon(
            Icons.check_circle_rounded,
            color: SColors.emerald500,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: context.dp.body,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
