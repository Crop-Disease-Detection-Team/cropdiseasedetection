import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'providers/auth_provider.dart';

class OtpScreen extends HookConsumerWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpCtrl = useTextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Verify OTP', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text('Enter the 6-digit code sent to ${authState.tempEmail ?? 'your email'}.'),
          const SizedBox(height: 24),
          if (authState.error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(authState.error!, style: const TextStyle(color: Colors.red))),
          AppTextField(controller: otpCtrl, hint: '6-digit OTP Code', icon: Icons.password_rounded),
          const SizedBox(height: 28),
          PrimaryButton(
            label: authState.isLoading ? 'Verifying...' : 'Verify & Continue', 
            onTap: authState.isLoading 
              ? null 
              : () async {
                  final success = await ref.read(authProvider.notifier).verifyOtp(otpCtrl.text);
                  if (success && context.mounted) {
                    final user = ref.read(authProvider).user;
                    final route = await ref.read(localSettingsProvider.notifier).nextRouteAfterAuth(user);
                    if (!context.mounted) return;
                    final role = user?['role']?.toString().toLowerCase();
                    final message = role == 'admin'
                        ? 'OTP verified. Logged in as admin.'
                        : 'OTP verified. Logged in successfully.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    if (context.mounted) context.go(route);
                  }
                }
          ),
          TextButton(onPressed: () {}, child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary))),
        ]),
      ),
    );
  }
}
