import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';

final adminSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchSettings();
});

class AdminSettingsScreen extends HookConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final thresholdCtrl = useTextEditingController();
    final versionCtrl = useTextEditingController();
    final maintenanceState = useState<bool>(false);
    final isSaving = useState<bool>(false);

    useEffect(() {
      settingsAsync.whenData((s) {
        thresholdCtrl.text = (s['confidence_threshold'] ?? '0.5').toString();
        versionCtrl.text = (s['min_supported_app_version'] ?? '1.0.0').toString();
        maintenanceState.value = s['maintenance_mode'] == true;
      });
      return null;
    }, [settingsAsync]);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI & Inference Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: thresholdCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Confidence Threshold (0.0 to 1.0)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      helperText: 'Scans below this confidence level are flagged as low confidence.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Maintenance & Versioning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: versionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Min Supported App Version',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Temporarily restrict user scans during system upgrades.'),
                    value: maintenanceState.value,
                    onChanged: (val) => maintenanceState.value = val,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSaving.value
                  ? null
                  : () async {
                      isSaving.value = true;
                      try {
                        final val = double.tryParse(thresholdCtrl.text.trim()) ?? 0.5;
                        await ref.read(adminRepositoryProvider).updateSettings({
                          'confidence_threshold': val,
                          'min_supported_app_version': versionCtrl.text.trim(),
                          'maintenance_mode': maintenanceState.value,
                        });
                        ref.invalidate(adminSettingsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings updated successfully!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update settings: $e')),
                          );
                        }
                      } finally {
                        isSaving.value = false;
                      }
                    },
              icon: isSaving.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
