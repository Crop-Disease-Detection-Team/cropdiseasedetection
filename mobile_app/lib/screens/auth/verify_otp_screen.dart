import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

enum OtpPurpose { emailVerification, passwordReset }

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;

  const VerifyOtpScreen({super.key, required this.email, required this.purpose});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      if (widget.purpose == OtpPurpose.emailVerification) {
        await _authService.resendVerification(widget.email);
      } else {
        await _authService.forgotPassword(widget.email);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A new code has been sent')));
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the 6-digit code')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.purpose == OtpPurpose.emailVerification) {
        await _authService.verifyEmail(email: widget.email, otp: _otpCtrl.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Email verified! Please login.')));
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
      } else {
        // verify-reset-otp just confirms the code; reset-password re-sends it.
        await _authService.verifyResetOtp(email: widget.email, otp: _otpCtrl.text.trim());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(email: widget.email, otp: _otpCtrl.text.trim()),
        ));
      }
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
      appBar: AppBar(backgroundColor: AppColors.green50, title: const Text('Verify code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.mark_email_read_outlined,
                  size: 56, color: AppColors.green700),
              const SizedBox(height: 16),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray700, fontSize: 15),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: '', hintText: '______'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Verify', onPressed: _verify, loading: _loading),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendCooldown == 0 ? _resend : null,
                  child: Text(_resendCooldown == 0
                      ? 'Resend code'
                      : 'Resend code in ${_resendCooldown}s'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
