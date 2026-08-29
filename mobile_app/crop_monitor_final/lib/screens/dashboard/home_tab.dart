import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/disease_service.dart';
import '../disease/disease_list_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;

  const HomeTab({super.key, required this.onScanTap, required this.onHistoryTap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _diseaseService = DiseaseService();
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _diseaseService.getUserStatistics();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      // stats are a nice-to-have; ignore failures on the home screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
        children: [
          Text('Hello, ${user?.name.split(' ').first ?? 'Farmer'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Scan a crop leaf to detect disease instantly',
              style: TextStyle(color: AppColors.gray500)),
          const SizedBox(height: 20),

          // Quick scan CTA
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onScanTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green700,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan a leaf!',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Camera or gallery • instant AI result',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                  child: _statCard('Total scans', '${_stats?['total_scans'] ?? '-'}',
                      Icons.document_scanner_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard(
                      'Avg. confidence',
                      _stats?['average_confidence'] != null
                          ? '${_stats!['average_confidence']}%'
                          : '-',
                      Icons.insights_outlined)),
            ],
          ),
          const SizedBox(height: 32),
          _linkTile(
            icon: Icons.history,
            title: 'Scan history',
            subtitle: 'Review your past detections',
            onTap: widget.onHistoryTap,
          ),
          _linkTile(
            icon: Icons.menu_book_outlined,
            title: 'Disease library',
            subtitle: 'Browse all known crop diseases',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DiseaseListScreen())),
          ),

          if (_stats?['favorite_diseases'] != null &&
              (_stats!['favorite_diseases'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Most frequently detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...(_stats!['favorite_diseases'] as List).map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.local_florist_outlined, color: AppColors.green700),
                    title: Text(d['name'] ?? ''),
                    trailing: Text('${d['count']}x',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green700),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
        ],
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.green100,
          child: Icon(icon, color: AppColors.green700, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray300),
        onTap: onTap,
      ),
    );
  }
}
