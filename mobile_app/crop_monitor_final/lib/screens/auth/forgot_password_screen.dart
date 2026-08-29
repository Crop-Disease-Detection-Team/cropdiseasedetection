import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(
          email: _emailCtrl.text.trim(),
          purpose: OtpPurpose.passwordReset,
        ),
      ));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green50,
      appBar: AppBar(backgroundColor: AppColors.green50, title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Enter the email linked to your account and we'll send a reset code.",
                  style: TextStyle(color: AppColors.gray500),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Send code', onPressed: _submit, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
