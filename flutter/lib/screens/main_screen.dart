import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() => runApp(
  MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen()),
);

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Container مع صورة خلفية
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/screen1.png'), // الخلفية
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // النص الجديد أعلى الصورة
                 Text(
                  'مرحباً بك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'OsamaFont', // الخط العربي الأنيق
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0xFF48C3D0),
                          Color(0xFF1E909B),
                        ],
                      ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
                ),
                const SizedBox(height: 100),

                // الصورة gg.png
                Image.asset(
                  'assets/images/gg.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 10),

                // العنوان الرئيسي
                const Text(
                  "نظام إدارة التوصيل",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35,
                    fontFamily: 'OsamaFont', // الخط العربي الأنيق
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E909B),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 5),

                // العنوان الفرعي
                const Text(
                  "ELK Delivery Al-Swaida",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E909B),
                  ),
                ),

                const Spacer(),

                // زر تسجيل الدخول
                _buildActionButton(
                  text: "تسجيل دخول",
                  icon: Icons.login,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // زر إنشاء حساب
                _buildActionButton(
                  text: "إنشاء حساب",
                  icon: Icons.person_add_alt_1,
                  onPressed: () {},
                ),

                const Spacer(),

                // شريط التقدم
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1E909B),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // الأيقونات السفلية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Icon(Icons.motorcycle, size: 40, color: Color(0xFF48C3D0)),
                      Icon(Icons.location_on_outlined, size: 60, color: Color(0xFF1E909B)),
                      Icon(Icons.directions_car_filled, size: 35, color: Color(0xFF48C3D0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // زر مع Animation + Gradient + Glassmorphism
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return _AnimatedButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (details) {
          _onTapUp(details);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: Container(
          width: 280,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            // Gradient
            gradient: LinearGradient(
              colors: [
                const Color(0xFF48C3D0).withOpacity(0.9),
                const Color(0xFF1E909B).withOpacity(0.9),
              ],
            ),
            // Glass effect border
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            // Shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(widget.icon, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}