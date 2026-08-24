import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController = useAnimationController(duration: const Duration(milliseconds: 1200))..forward();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 1200));

        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'access_token');
        final dynamic connectivityResult = await Connectivity().checkConnectivity();
        final isOnline = connectivityResult is List<ConnectivityResult>
            ? connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none)
            : connectivityResult != ConnectivityResult.none;

        if (token != null) {
          await ref.read(authProvider.notifier).loadCurrentUser(isOnline: isOnline);
          final user = ref.read(authProvider).user;
          if (user != null) {
            final route = await ref.read(localSettingsProvider.notifier).nextRouteAfterAuth(user);
            if (context.mounted) context.go(route);
            return;
          }
        }

        // No token or session expired
        final route = await ref.read(localSettingsProvider.notifier).nextRouteAfterAuth(null);
        if (context.mounted) {
          if (route == '/dashboard' || route == '/admin/dashboard') {
            context.go('/login');
          } else {
            context.go(route);
          }
        }
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: animationController,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, size: 84, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'AgriVision AI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Smart Crop Disease Detection',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

