import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/config/app_config.dart';

final adminDiseasesProvider = StateNotifierProvider.autoDispose<AdminDiseasesNotifier, AsyncValue<List<dynamic>>>((ref) {
  return AdminDiseasesNotifier();
});

class AdminDiseasesNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  AdminDiseasesNotifier() : super(const AsyncValue.loading()) {
    fetchDiseases();
  }

  final ApiClient _api = ApiClient(AppConfig.apiBaseUrl);
  String _searchQuery = '';
  String _cropFilter = '';

  void setSearch(String q) {
    _searchQuery = q;
    fetchDiseases();
  }

  void setCrop(String c) {
    _cropFilter = c;
    fetchDiseases();
  }

  Future<void> fetchDiseases() async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_cropFilter.isNotEmpty) queryParams['crop'] = _cropFilter;

      final response = await _api.dio.get('scans/admin/diseases/', queryParameters: queryParams);
      state = AsyncValue.data(response.data as List);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> saveDisease(Map<String, dynamic> data, {int? id}) async {
    try {
      if (id != null) {
        await _api.dio.put('scans/admin/diseases/$id/', data: data);
      } else {
        await _api.dio.post('scans/admin/diseases/', data: data);
      }
      await fetchDiseases();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDisease(int id) async {
    try {
      await _api.dio.delete('scans/admin/diseases/$id/');
      await fetchDiseases();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AdminDiseasesScreen extends HookConsumerWidget {
  const AdminDiseasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diseasesAsync = ref.watch(adminDiseasesProvider);
    final searchController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Diseases', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showDiseaseForm(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search diseases...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (val) {
                ref.read(adminDiseasesProvider.notifier).setSearch(val.trim());
              },
            ),
          ),
          Expanded(
            child: diseasesAsync.when(
              data: (diseases) {
                if (diseases.isEmpty) {
                  return const Center(child: Text('No diseases found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(adminDiseasesProvider.notifier).fetchDiseases(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: diseases.length,
                    itemBuilder: (context, index) {
                      final d = diseases[index] as Map<String, dynamic>;
                      final id = d['id'] as int;
                      final String rawName = d['name'] ?? 'Unknown';
                      final String cleanName = rawName.contains('___') ? rawName.split('___').last.replaceAll('_', ' ') : rawName;
                      final String cropName = d['crop_name'] ?? 'Unknown Crop';
                      final String severity = d['severity'] ?? 'Medium';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ExpansionTile(
                          title: Text(cleanName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Crop: $cropName | Severity: $severity'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (d['scientific_name'] != null && d['scientific_name'].toString().isNotEmpty)
                                    Text('Scientific Name: ${d['scientific_name']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  if (d['description'] != null && d['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(d['description'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showDiseaseForm(context, ref, disease: d),
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final success = await ref.read(adminDiseasesProvider.notifier).deleteDisease(id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(success ? 'Disease deleted.' : 'Failed to delete.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                        label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiseaseForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? disease}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: _DiseaseFormWidget(
            disease: disease,
            onSave: (data) async {
              final success = await ref.read(adminDiseasesProvider.notifier).saveDisease(data, id: disease?['id'] as int?);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Disease saved successfully.' : 'Failed to save.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class _DiseaseFormWidget extends HookWidget {
  const _DiseaseFormWidget({this.disease, required this.onSave});

  final Map<String, dynamic>? disease;
  final Function(Map<String, dynamic>) onSave;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: disease?['name'] ?? '');
    final sciNameController = useTextEditingController(text: disease?['scientific_name'] ?? '');
    final descController = useTextEditingController(text: disease?['description'] ?? '');
    final severity = useState<String>(disease?['severity'] ?? 'Medium');
    final cropId = useState<int?>(disease?['crop'] as int?);

    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              disease == null ? 'Add Disease' : 'Edit Disease',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Disease Class Label (e.g. Tomato___Early_blight)'),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: sciNameController,
              decoration: const InputDecoration(labelText: 'Scientific Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: severity.value,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
                DropdownMenuItem(value: 'Critical', child: Text('Critical')),
              ],
              onChanged: (val) {
                if (val != null) severity.value = val;
              },
            ),
            const SizedBox(height: 12),
            // For simplicity in the admin panel, we accept a crop ID directly. 
            // In a production app, this would be a dropdown populated with crops.
            TextFormField(
              initialValue: cropId.value?.toString() ?? '',
              decoration: const InputDecoration(labelText: 'Crop ID'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                cropId.value = int.tryParse(val);
              },
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onSave({
                    'name': nameController.text.trim(),
                    'scientific_name': sciNameController.text.trim(),
                    'description': descController.text.trim(),
                    'severity': severity.value,
                    'crop': cropId.value,
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

