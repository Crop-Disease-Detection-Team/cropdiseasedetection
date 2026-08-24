import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_field.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState<int>(1); // 1 = Enter Email, 2 = Enter OTP & New Password
    final emailCtrl = useTextEditingController();
    final otpCtrl = useTextEditingController();
    final newPassCtrl = useTextEditingController();
    final confirmPassCtrl = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final authState = ref.watch(authProvider);

    void onRequestOtp() async {
      if (!formKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      final success = await ref.read(authProvider.notifier).forgotPassword(emailCtrl.text.trim());
      if (success && context.mounted) {
        step.value = 2;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset OTP sent to your email.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }

    void onResetPassword() async {
      if (!formKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      final success = await ref.read(authProvider.notifier).resetPassword(
            code: otpCtrl.text.trim(),
            password: newPassCtrl.text,
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. Please login with your new password.'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/login');
      }
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AuthBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => step.value == 2 ? step.value = 1 : context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.value == 1 ? 'Forgot Password?' : 'Reset Password',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.value == 1
                              ? 'Enter your registered email address to receive a password reset code.'
                              : 'Enter the verification code sent to ${emailCtrl.text} and your new password.',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (authState.error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(authState.error!, style: const TextStyle(color: Colors.red)),
                              ),

                            if (step.value == 1) ...[
                              AuthTextField(
                                controller: emailCtrl,
                                hintText: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) => (val == null || val.isEmpty) ? 'Email is required' : null,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'Send Reset Code',
                                isLoading: authState.isLoading,
                                onTap: onRequestOtp,
                              ),
                            ] else ...[
                              AuthTextField(
                                controller: otpCtrl,
                                hintText: '6-Digit Reset Code',
                                prefixIcon: Icons.pin_outlined,
                                keyboardType: TextInputType.number,
                                validator: (val) => (val == null || val.length != 6) ? 'Enter valid 6-digit code' : null,
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                controller: newPassCtrl,
                                hintText: 'New Password',
                                validator: (val) => (val == null || val.length < 8) ? 'Minimum 8 characters' : null,
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                controller: confirmPassCtrl,
                                hintText: 'Confirm New Password',
                                validator: (val) => (val != newPassCtrl.text) ? 'Passwords do not match' : null,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'Reset Password',
                                isLoading: authState.isLoading,
                                onTap: onResetPassword,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
