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
import 'widgets/glass_card.dart';
import 'widgets/password_strength_indicator.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameCtrl = useTextEditingController();
    final usernameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final districtCtrl = useTextEditingController();
    final passCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final passwordText = useValueListenable(passCtrl);
    final authState = ref.watch(authProvider);

    void onSignup() async {
      if (formKey.currentState!.validate()) {
        FocusScope.of(context).unfocus();
        final success = await ref.read(authProvider.notifier).signup({
          'name': nameCtrl.text.trim(),
          'full_name': nameCtrl.text.trim(),
          'username': usernameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'district': districtCtrl.text.trim(),
          'address': districtCtrl.text.trim(),
          'password': passCtrl.text,
          'confirm_password': confirmCtrl.text,
        });

        if (success && context.mounted) {
          final user = ref.read(authProvider).user;
          if (user != null) {
            final route = await ref.read(localSettingsProvider.notifier).nextRouteAfterAuth(user);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully.'),
                backgroundColor: AppColors.primary,
              ),
            );
            if (context.mounted) context.go(route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created. Please verify the OTP sent to your email.'),
                backgroundColor: AppColors.primary,
              ),
            );
            if (context.mounted) context.go('/otp');
          }
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
                // Top Transparent Header with Glass Cards
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withAlpha(128)),
                          ),
                          child: const Text(
                            '🇳🇵 CROP DISEASE AI — NEPAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Protect your crops with intelligent diagnostics.',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Glass Cards Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFeatureCard(Icons.document_scanner_outlined, 'AI Detection'),
                              const SizedBox(width: 12),
                              _buildFeatureCard(Icons.health_and_safety_outlined, 'Instant Medicine'),
                              const SizedBox(width: 12),
                              _buildFeatureCard(Icons.history_rounded, 'Track History'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom White Card Form
                Expanded(
                  flex: 6,
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
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Registration Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
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
                                controller: nameCtrl,
                                hintText: 'Full Name',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (val) => (val == null || val.isEmpty) ? 'Full Name is required' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              AuthTextField(
                                controller: usernameCtrl,
                                hintText: 'Username (Optional)',
                                prefixIcon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 16),
                              
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
                              
                              AuthTextField(
                                controller: phoneCtrl,
                                hintText: 'Phone Number',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Phone number is required';
                                  if (val.length < 10) return 'Enter a valid phone number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              AuthTextField(
                                controller: districtCtrl,
                                hintText: 'District / Address',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (val) => (val == null || val.isEmpty) ? 'Address is required' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              PasswordField(
                                controller: passCtrl,
                                hintText: 'Password',
                                onChanged: (_) {}, // Triggered by useValueListenable above implicitly
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Password is required';
                                  if (val.length < 8) return 'Password must be at least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              PasswordStrengthIndicator(password: passwordText.text),
                              const SizedBox(height: 16),
                              
                              PasswordField(
                                controller: confirmCtrl,
                                hintText: 'Confirm Password',
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Confirm your password';
                                  if (val != passCtrl.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              
                              PrimaryButton(
                                label: 'Create Account',
                                isLoading: authState.isLoading,
                                onTap: onSignup,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              AuthFooter(
                                text: "Already have an account?",
                                actionText: 'Login',
                                onActionTap: () => context.go('/login'),
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

  Widget _buildFeatureCard(IconData icon, String text) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

