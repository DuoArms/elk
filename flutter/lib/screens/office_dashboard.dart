import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/notificationCubit.dart';
import '../cubits/notification_state.dart';
import 'customer_directory.dart';
import 'add_order_form.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'office_notifications_screen.dart';

class OfficeDashboard extends StatelessWidget {
  const OfficeDashboard({super.key});

  static const Color primaryTeal = Color(0xFF54d4dd);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationCubit(),
      child: const _OfficeDashboardContent(),
    );
  }
}

class _OfficeDashboardContent extends StatefulWidget {
  const _OfficeDashboardContent();

  @override
  State<_OfficeDashboardContent> createState() => _OfficeDashboardContentState();
}

class _OfficeDashboardContentState extends State<_OfficeDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCubit>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/dash.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  _buildTopIcon(),
                  const SizedBox(height: 15),
                  _buildWelcomeHeader(),
                  const SizedBox(height: 35),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العمود الأيمن
                          Expanded(
                            child: Column(
                              children: [
                                _buildTeal3DCard(
                                  title: 'إدارة الطلبات',
                                  icon: Icons.assignment_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen())),
                                ),
                                const SizedBox(height: 18),
                                _buildTeal3DCard(
                                  title: 'أداء التوصيل',
                                  icon: Icons.speed_outlined,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // العمود الأوسط
                          Expanded(
                            child: Column(
                              children: [
                                _buildWhiteProminentCard(
                                  title: 'دليل الهاتف',
                                  subtitle: 'البحث السريع عن العملاء',
                                  icon: Icons.contact_phone,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDirectory())),
                                ),
                                const SizedBox(height: 18),
                                _buildWhiteProminentCard(
                                  title: 'إضافة طلب جديد',
                                  icon: Icons.add_shopping_cart,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOrderForm())),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // العمود الأيسر
                          Expanded(
                            child: Column(
                              children: [
                                _buildNotificationsCard(),
                                const SizedBox(height: 18),
                                _buildLogoutCard(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationsLoaded) {
          unreadCount = state.unreadCount;
        }
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfficeNotificationsScreen()),
            );
          },
          child: Container(
            height: 155,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OfficeDashboard.primaryTeal, OfficeDashboard.primaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: OfficeDashboard.primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active, size: 38, color: Colors.white),
                const SizedBox(height: 10),
                const Text('الإشعارات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text('$unreadCount جديد', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhiteProminentCard({required String title, required IconData icon, required VoidCallback onTap, String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: OfficeDashboard.primaryTeal.withOpacity(0.05),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: OfficeDashboard.primaryTeal.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 45, color: OfficeDashboard.primaryTeal),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: OfficeDashboard.primaryTeal, fontWeight: FontWeight.w900, fontSize: 15),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: OfficeDashboard.primaryTeal, fontSize: 9)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeal3DCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 155,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [OfficeDashboard.primaryTeal, OfficeDashboard.primaryTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: OfficeDashboard.primaryTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            _buildQuickSearchTag(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthCubit>().logout();
        if (context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      },
      child: Container(
        height: 155,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Quick-search ', style: TextStyle(color: Colors.white, fontSize: 8)),
          Icon(Icons.search, size: 10, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTopIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
      child: const Icon(Icons.grid_view_rounded, size: 45, color: OfficeDashboard.primaryTeal),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: const [
        Text('مرحباً بك في', style: TextStyle(fontSize: 24, color: OfficeDashboard.primaryTeal, fontWeight: FontWeight.w600)),
        Text('لوحة التحكم', style: TextStyle(fontSize: 34, color: OfficeDashboard.primaryTeal, fontWeight: FontWeight.w900)),
        Text('إدارة الطلبات والمكتب بكفاءة', style: TextStyle(fontSize: 15, color: OfficeDashboard.primaryTeal)),
      ],
    );
  }
}