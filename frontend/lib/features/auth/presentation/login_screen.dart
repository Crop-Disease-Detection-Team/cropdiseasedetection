import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/primary_button.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_field.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_background.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailCtrl = useTextEditingController();
    final passCtrl = useTextEditingController();
    final rememberMe = useState(false);
    final authState = ref.watch(authProvider);

    void onLogin() async {
      if (formKey.currentState!.validate()) {
        FocusScope.of(context).unfocus();
        final success = await ref.read(authProvider.notifier).login(emailCtrl.text.trim(), passCtrl.text);
        if (success && context.mounted) {
          final user = ref.read(authProvider).user;
          final route = await ref.read(localSettingsProvider.notifier).nextRouteAfterAuth(user);
          if (!context.mounted) return;
          final role = user?['role']?.toString().toLowerCase();
          final message = role == 'admin'
              ? 'Successfully logged in as admin.'
              : 'Successfully logged in.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.primary,
            ),
          );
          if (context.mounted) context.go(route);
        }
      }
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AuthBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Top Transparent Header
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    alignment: Alignment.centerLeft,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to continue to AgriVision AI.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom White Card
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (authState.error != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authState.error!,
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              AuthTextField(
                                controller: emailCtrl,
                                hintText: 'Email address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Email is required';
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              PasswordField(
                                controller: passCtrl,
                                hintText: 'Password',
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Password is required';
                                  if (val.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: rememberMe.value,
                                          onChanged: (val) => rememberMe.value = val ?? false,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Remember Me', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                                ),
                                child: const Text(
                                  'Admin default login: admin@agrivision.ai / Admin@123',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 20),
                              PrimaryButton(
                                label: 'Sign In',
                                isLoading: authState.isLoading,
                                onTap: onLogin,
                              ),
                              
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              AuthFooter(
                                text: "Don't have an account?",
                                actionText: 'Register',
                                onActionTap: () => context.go('/signup'),
                              ),
                            ],
                          ),
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

