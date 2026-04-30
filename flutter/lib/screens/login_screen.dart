import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../models/user.dart';
import 'office_dashboard.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';
import 'accountant/accountant_dashboard.dart';
import 'store_dashboard.dart';
import 'customer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  static const Color _primaryColor = Color(0xFF54d4dd);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.login(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      final user = authCubit.state;
      if (user == null) {
        _showError('بيانات غير صحيحة');
        return;
      }
      _navigateByRole(user.role);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateByRole(UserRole role) {
    Widget destination;
    switch (role) {
      case UserRole.admin:
        destination = const AdminDashboard();
        break;
      case UserRole.office:
        destination = const OfficeDashboard();
        break;
      case UserRole.driver:
        destination = const DriverDashboard();
        break;
      case UserRole.accountant:
        destination = const AccountantDashboard();
        break;
      case UserRole.store:
        destination = const StoreDashboard();
        break;
      case UserRole.customer:
        destination = const CustomerDashboard();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية الصورة تمتد على كامل الشاشة
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/images/gg.png',
                fit: BoxFit.cover,
              ),
            ),
            // تراكب متدرج لتحسين وضوح النصوص
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _primaryColor.withOpacity(0.75),
                    const Color(0xFF43C1CF).withOpacity(0.7),
                    _primaryColor.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: size.height * 0.04),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _BrandHeader(primaryColor: _primaryColor),
                      SizedBox(height: size.height * 0.06),
                      _LoginCard(
                        phoneController: _phoneController,
                        passwordController: _passwordController,
                        onLogin: _handleLogin,
                        loading: _loading,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        primaryColor: _primaryColor,
                      ),
                      const SizedBox(height: 24),
                      _FooterHint(primaryColor: _primaryColor),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// رأس العلامة التجارية (محسّن)
class _BrandHeader extends StatelessWidget {
  final Color primaryColor;
  const _BrandHeader({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Colors.white, Color(0xFFE0F7FA)],
              center: Alignment.center,
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            size: 50,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'مرحباً بك',
          style: TextStyle(
            fontSize: 32,
            fontFamily: 'OsamaFont',
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(1, 2)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'نظام إدارة التوصيل المتكامل',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'OsamaFont',
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ELK Delivery Al-Swaida',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// بطاقة تسجيل الدخول الزجاجية (Glassmorphism محسّن)
class _LoginCard extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool loading;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Color primaryColor;

  const _LoginCard({
    required this.phoneController,
    required this.passwordController,
    required this.onLogin,
    required this.loading,
    required this.obscure,
    required this.onToggleObscure,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: Colors.white,
            border: Border.all(
              color: primaryColor.withOpacity(0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: primaryColor.withOpacity(0.9)),
                  prefixIcon: Icon(Icons.phone_android, color:primaryColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.6)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: obscure,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: TextStyle(color:primaryColor),
                  prefixIcon: Icon(Icons.lock_outline, color:primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color:  primaryColor,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.6)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: loading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.5),
                ),
                child: loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'تسجيل دخول',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// التذييل التحفيزي
class _FooterHint extends StatelessWidget {
  final Color primaryColor;
  const _FooterHint({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, size: 22, color: Colors.white.withOpacity(0.95)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "ابدأ الآن وكن جزءاً من نظام توصيل سريع وموثوق",
              style: TextStyle(
                fontFamily: 'OsamaFont',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// تعريف اللون الأساسي داخل الملف للوصول إليه في _LoginCard (لأنه const)
const Color _primaryColor = Color(0xFF54d4dd);