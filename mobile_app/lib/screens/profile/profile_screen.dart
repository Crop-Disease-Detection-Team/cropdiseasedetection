import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../settings/server_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _saving = false;
  bool _uploadingPic = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final result = await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      final updated = AppUser.fromJson(result['user'] as Map<String, dynamic>);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePicture() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPic = true);
    try {
      final result = await _authService.uploadProfilePic(File(picked.path));
      final updated = AppUser.fromJson(result['user'] as Map<String, dynamic>);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  Future<void> _changePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Current password', controller: oldCtrl, obscureText: true),
            const SizedBox(height: 12),
            AppTextField(label: 'New password', controller: newCtrl, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _authService.changePassword(
            oldPassword: oldCtrl.text, newPassword: newCtrl.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password changed')));
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: AppColors.red600))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server settings',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.green100,
                    backgroundImage: (user?.profilePic != null && user!.profilePic!.isNotEmpty)
                        ? CachedNetworkImageProvider(ApiConfig.resolveImage(user.profilePic))
                        : null,
                    child: (user?.profilePic == null || user!.profilePic!.isEmpty)
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 32, color: AppColors.green700, fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _uploadingPic ? null : _changePicture,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppColors.green700, shape: BoxShape.circle),
                        child: _uploadingPic
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(user?.email ?? '',
                  style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            AppTextField(label: 'Full name', controller: _nameCtrl, prefixIcon: Icons.person_outline),
            const SizedBox(height: 14),
            AppTextField(label: 'Phone', controller: _phoneCtrl, prefixIcon: Icons.phone_outlined),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Address', controller: _addressCtrl, prefixIcon: Icons.location_on_outlined),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save changes', onPressed: _saveProfile, loading: _saving),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _changePasswordDialog,
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red600,
                  side: const BorderSide(color: AppColors.red600)),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
