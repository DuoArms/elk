import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../cubits/auth_cubit.dart';
import 'login_screen.dart';
import 'office_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initVideoAndNavigate();
  }

  Future<void> _initVideoAndNavigate() async {
    // تهيئة الفيديو
    _controller = VideoPlayerController.asset('assets/videos/elk.mp4');
    await _controller.initialize();
    _controller.setLooping(true); // تشغيل متكرر حتى انتهاء التايمر
    _controller.play();

    // تحقق من حالة تسجيل الدخول
    final authCubit = context.read<AuthCubit>();
    await authCubit.isLoggedIn();

    // تأخير الانتقال (يمكن أن يكون بنفس طول الفيديو أو ثابت)
    _timer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      _controller.pause(); // إيقاف الفيديو عند الانتقال
      final user = authCubit.state;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user != null ? const OfficeDashboard() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // فيديو كخلفية
          VideoPlayer(_controller),
          // يمكن إضافة تراكب شفاف إذا أردت
          Container(color: Colors.black.withOpacity(0.2)),
          // شعار أو نص فوق الفيديو (اختياري)

        ],
      ),
    );
  }
}