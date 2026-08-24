import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../scan/data/scan_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authProvider).user;
    final history = ref.watch(scanHistoryProvider);
    final isOnline = ref.watch(connectivityProvider);
    
    final name = (user?['full_name'] ?? user?['name'] ?? user?['email'] ?? 'Farmer').toString();
    final district = (user?['district'] ?? user?['address'] ?? 'Nepal').toString();
    final role = (user?['role'] ?? 'user').toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (isOnline) {
              ref.invalidate(scanHistoryProvider);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (!isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are offline. Scans will be analyzed locally or synced when online.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AgriVision AI',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: role == 'ADMIN' ? Colors.purple.shade100 : AppColors.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: role == 'ADMIN' ? Colors.purple.shade800 : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strings.t('welcome')}, $name! 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '📍 $district',
                          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.secondary,
                        child: Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Main CTA Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crop Disease Detection',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.t('instruction'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Scan Crop Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.center_focus_strong_rounded, size: 48, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Shortcuts Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/library'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                      label: const Text('Disease Library', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/favourites'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
                      label: const Text('Saved Favourites', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats Cards Row
              history.maybeWhen(
                data: (items) {
                  final totalScans = items.length;
                  final healthyScans = items.where((s) {
                    final d = (s['disease_name'] ?? '').toString().toLowerCase();
                    return s['is_healthy'] == true || d.contains('healthy');
                  }).length;
                  final diseaseScans = totalScans - healthyScans;

                  return Row(
                    children: [
                      _StatCard(
                        title: 'Total Scans',
                        value: totalScans.toString(),
                        icon: Icons.filter_center_focus_rounded,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Healthy',
                        value: healthyScans.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Diseased',
                        value: diseaseScans.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Latest Diagnosis Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.t('latestScan'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              history.when(
                data: (items) {
                  if (items.isEmpty) return _EmptyLatest(strings: strings);
                  return _LatestScanCard(scan: items.first, strings: strings);
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestScanCard extends StatelessWidget {
  const _LatestScanCard({required this.scan, required this.strings});

  final Map<String, dynamic> scan;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse((scan['scanned_at'] ?? scan['created_at'] ?? '').toString())?.toLocal();
    final confidence = ((num.tryParse(scan['confidence'].toString()) ?? 0) * 100).clamp(0, 100).toStringAsFixed(1);
    final diseaseName = scan['disease_name']?.toString() ?? 'Unknown';
    final isHealthy = scan['is_healthy'] == true || diseaseName.toLowerCase().contains('healthy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/result', extra: scan),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isHealthy ? Icons.eco_rounded : Icons.coronavirus_rounded,
                      color: isHealthy ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diseaseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Crop: ${scan['crop_type']?.toString() ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$confidence%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (scan['recommendation'] != null && scan['recommendation'].toString().isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scan['recommendation'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (date != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, y  h:mm a').format(date),
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    const Row(
                      children: [
                        Text('Full Diagnosis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLatest extends StatelessWidget {
  const _EmptyLatest({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
          Text(
            strings.t('noScansTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            strings.t('noScansBody'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
    );
  }
}

