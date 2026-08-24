import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchDashboardStats();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Admin Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.purple.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AgriVision Control Center', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('System metrics & database management', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.admin_panel_settings_rounded, size: 48, color: Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('System Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),

              statsAsync.when(
                data: (stats) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          _StatCard(title: 'Total Users', value: stats['total_users'].toString(), icon: Icons.people_alt_rounded, color: Colors.blue),
                          const SizedBox(width: 12),
                          _StatCard(title: 'Active Users', value: stats['active_users'].toString(), icon: Icons.check_circle_rounded, color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(title: 'Total Scans', value: stats['total_scans'].toString(), icon: Icons.center_focus_strong_rounded, color: Colors.purple),
                          const SizedBox(width: 12),
                          _StatCard(title: 'Scans Today', value: stats['today_scans'].toString(), icon: Icons.today_rounded, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        title: 'Diseases in Library',
                        value: stats['total_diseases'].toString(),
                        icon: Icons.local_hospital_rounded,
                        color: Colors.red,
                        isFullWidth: true,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Text('Error loading stats: $err', style: const TextStyle(color: AppColors.error)),
                ),
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
    this.isFullWidth = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) return card;
    return Expanded(child: card);
  }
}

