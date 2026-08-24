import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final strings = ref.watch(appStringsProvider);
    final usernameCtrl = useTextEditingController();
    final districtCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final currentPassCtrl = useTextEditingController();
    final newPassCtrl = useTextEditingController();
    final confirmPassCtrl = useTextEditingController();
    final profileFormKey = useMemoized(() => GlobalKey<FormState>());
    final passwordFormKey = useMemoized(() => GlobalKey<FormState>());

    useEffect(() {
      Future.microtask(() => ref.read(authProvider.notifier).loadCurrentUser());
      return null;
    }, const []);

    useEffect(() {
      usernameCtrl.text = user?['username']?.toString() ?? '';
      districtCtrl.text = user?['district']?.toString() ?? user?['address']?.toString() ?? '';
      phoneCtrl.text = user?['phone']?.toString() ?? '';
      return null;
    }, [user]);

    final name = user?['name']?.toString() ?? user?['full_name']?.toString() ?? '';
    final email = user?['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('profile')), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: CircleAvatar(radius: 44, backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: Colors.white, size: 38))),
          const SizedBox(height: 12),
          Center(child: Text(name.isEmpty ? 'Signed-in user' : name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGreen))),
          Center(child: Text(email, style: const TextStyle(color: Colors.black54))),
          const SizedBox(height: 18),
          if (authState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(authState.error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          _card(
            child: Form(
              key: profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 14),
                  _readOnly('Full Name', name),
                  _readOnly('Email', email),
                  TextFormField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextFormField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'District')),
                  const SizedBox(height: 12),
                  TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Update Profile',
                    isLoading: authState.isLoading,
                    onTap: () async {
                      if (!profileFormKey.currentState!.validate()) return;
                      final ok = await ref.read(authProvider.notifier).updateProfile(
                            username: usernameCtrl.text.trim(),
                            district: districtCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('language'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(_languageLabel(ref.watch(localSettingsProvider).valueOrNull ?? 'en')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLanguageSheet(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Form(
              key: passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.t('changePassword'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 14),
                  TextFormField(controller: currentPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password'), validator: _required),
                  const SizedBox(height: 12),
                  TextFormField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password'), validator: (value) => (value ?? '').length < 8 ? 'Password must be at least 8 characters' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                    validator: (value) => value != newPassCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Change Password',
                    isLoading: authState.isLoading,
                    onTap: () async {
                      if (!passwordFormKey.currentState!.validate()) return;
                      final ok = await ref.read(authProvider.notifier).changePassword(
                            currentPassword: currentPassCtrl.text,
                            newPassword: newPassCtrl.text,
                            confirmPassword: confirmPassCtrl.text,
                          );
                      if (ok && context.mounted) {
                        currentPassCtrl.clear();
                        newPassCtrl.clear();
                        confirmPassCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: child));
  }

  Widget _readOnly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white),
        child: Text(value.isEmpty ? '-' : value),
      ),
    );
  }

  String? _required(String? value) => (value == null || value.isEmpty) ? 'Required' : null;

  String _languageLabel(String code) {
    return supportedLanguages.firstWhere((language) => language.code == code, orElse: () => supportedLanguages.first).label;
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: supportedLanguages.map((language) {
          return ListTile(
            title: Text(language.label),
            onTap: () async {
              await ref.read(localSettingsProvider.notifier).saveLanguage(language.code);
              if (context.mounted) Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
