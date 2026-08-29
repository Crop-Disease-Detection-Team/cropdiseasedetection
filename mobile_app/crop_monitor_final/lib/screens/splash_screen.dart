import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/user_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;

    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            auth.isAdmin ? const AdminDashboardScreen() : const UserDashboardScreen(),
      ));
    } else {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green700,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, color: AppColors.green700, size: 46),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Crop Monitor',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI-Powered Crop Disease Detection',
              style: TextStyle(color: AppColors.green100.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
