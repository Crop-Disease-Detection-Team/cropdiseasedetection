import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/disease_repository.dart';

final cropsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(diseaseRepositoryProvider).fetchCrops();
});

final diseasesSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final selectedCropIdProvider = StateProvider.autoDispose<int?>((ref) => null);

final diseasesListProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(diseaseRepositoryProvider);
  final search = ref.watch(diseasesSearchProvider);
  final cropId = ref.watch(selectedCropIdProvider);
  return repo.fetchDiseases(cropId: cropId, search: search);
});

class DiseaseLibraryScreen extends HookConsumerWidget {
  const DiseaseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final cropsAsync = ref.watch(cropsProvider);
    final diseasesAsync = ref.watch(diseasesListProvider);
    final selectedCropId = ref.watch(selectedCropIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Disease Library', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: searchCtrl,
                onChanged: (val) => ref.read(diseasesSearchProvider.notifier).state = val,
                decoration: InputDecoration(
                  hintText: 'Search diseases, crops, or symptoms...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchCtrl.clear();
                            ref.read(diseasesSearchProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),

            // Crop Filter Chips
            cropsAsync.maybeWhen(
              data: (crops) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Crops'),
                        selected: selectedCropId == null,
                        onSelected: (_) => ref.read(selectedCropIdProvider.notifier).state = null,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedCropId == null ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      const SizedBox(width: 8),
                      ...crops.map((crop) {
                        final isSelected = selectedCropId == crop['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(crop['name']?.toString() ?? ''),
                            selected: isSelected,
                            onSelected: (_) => ref.read(selectedCropIdProvider.notifier).state = isSelected ? null : crop['id'] as int?,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Diseases Grid / List
            Expanded(
              child: diseasesAsync.when(
                data: (diseases) {
                  if (diseases.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No diseases found', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text('Try adjusting your search query or crop filter.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: diseases.length,
                    itemBuilder: (context, index) {
                      final d = diseases[index];
                      final name = (d['name'] ?? 'Unknown').toString().replaceAll('_', ' ').split('___').last;
                      final cropName = d['crop_name'] ?? d['crop']?['name'] ?? 'Crop';
                      final severity = d['severity']?.toString() ?? 'Medium';
                      final desc = d['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.push('/disease/${d['id']}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.coronavirus_rounded, color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _severityColor(severity).withAlpha(40),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              severity,
                                              style: TextStyle(
                                                color: _severityColor(severity),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Crop: $cropName', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          desc,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading diseases: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return Colors.red;
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'mild':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
