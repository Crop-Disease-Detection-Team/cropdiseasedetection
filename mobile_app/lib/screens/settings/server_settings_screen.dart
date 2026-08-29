import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Lets the user point the app at whatever backend address is currently
/// reachable, without touching code or rebuilding the app. This is the
/// fix for "I have to change the IP every time I switch Wi-Fi": now you
/// just open this screen and update it in a few seconds.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _testing = false;
  String? _testResult;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _testing = true;
      _testResult = null;
      _testOk = null;
    });
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      setState(() {
        _testOk = res.statusCode < 500;
        _testResult = 'Server responded (HTTP ${res.statusCode}). Looks reachable.';
      });
    } on TimeoutException {
      setState(() {
        _testOk = false;
        _testResult =
            'Timed out. Make sure your phone and PC are on the same Wi-Fi, '
            'the Flask server is running, and the IP/port are correct.';
      });
    } on SocketException catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Could not connect: ${e.message}. Double-check the '
            'address and that the server is running.';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Could not connect: $e';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    await ApiConfig.setBaseUrl(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server address saved')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Server settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Point the app at your backend',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you switched Wi-Fi networks, or your PC\'s IP changed, '
              'update the address below. No rebuild needed — it\'s saved '
              'on this phone and used immediately.',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _urlCtrl,
              label: 'Server URL (e.g. http://192.168.1.42:5000)',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            _HintCard(),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _testing ? null : _testConnection,
              child: _testing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Test connection'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_testOk ?? false) ? AppColors.green50 : AppColors.red100,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (_testOk ?? false) ? Icons.check_circle : Icons.error_outline,
                      color: (_testOk ?? false) ? AppColors.green700 : AppColors.red600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_testResult!,
                            style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        '• Android emulator + Flask on same PC → http://10.0.2.2:5000\n'
        '• Real phone, same Wi-Fi as your PC     → http://<PC LAN IP>:5000\n'
        '• Using ngrok or a deployed backend      → https://your-url',
        style: TextStyle(fontSize: 12, color: AppColors.gray700, height: 1.5),
      ),
    );
  }
}
