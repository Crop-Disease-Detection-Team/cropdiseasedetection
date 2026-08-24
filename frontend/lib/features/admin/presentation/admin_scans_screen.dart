import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/config/app_config.dart';

final adminScansProvider = StateNotifierProvider.autoDispose<AdminScansNotifier, AsyncValue<List<dynamic>>>((ref) {
  return AdminScansNotifier();
});

class AdminScansNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  AdminScansNotifier() : super(const AsyncValue.loading()) {
    fetchScans();
  }

  final ApiClient _api = ApiClient(AppConfig.apiBaseUrl);
  String _searchQuery = '';

  void setSearch(String q) {
    _searchQuery = q;
    fetchScans();
  }

  Future<void> fetchScans() async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final response = await _api.dio.get('scans/admin/scans/', queryParameters: queryParams);
      state = AsyncValue.data(response.data as List);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteScan(int scanId) async {
    try {
      await _api.dio.delete('scans/admin/scans/$scanId/');
      await fetchScans();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdminScansScreen extends HookConsumerWidget {
  const AdminScansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(adminScansProvider);
    final searchController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Scans', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search header
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by user email or disease...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (val) {
                ref.read(adminScansProvider.notifier).setSearch(val.trim());
              },
            ),
          ),
          
          Expanded(
            child: scansAsync.when(
              data: (scans) {
                if (scans.isEmpty) {
                  return const Center(child: Text('No scans found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminScansProvider.notifier).fetchScans(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan = scans[index] as Map<String, dynamic>;
                      final scanId = scan['id'] as int;
                      final String cropType = scan['crop_type'] ?? 'Unknown';
                      final String diseaseName = scan['disease_name'] ?? 'Pending/Unknown';
                      double confidence = double.tryParse((scan['confidence'] ?? 0).toString()) ?? 0.0;
                      confidence = (confidence * 100).clamp(0.0, 100.0).toDouble();
                      final String userEmail = scan['raw_response']?['user_email'] ?? 'User';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFE0B2),
                            child: Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                          ),
                          title: Text('$cropType - $diseaseName', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Confidence: ${confidence.toStringAsFixed(1)}% | By: $userEmail'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                                onPressed: () {
                                  context.push('/result', extra: scan);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                onPressed: () async {
                                  final success = await ref.read(adminScansProvider.notifier).deleteScan(scanId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(success ? 'Scan deleted successfully.' : 'Failed to delete scan.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          )
        ],
      ),
    );
  }
}


