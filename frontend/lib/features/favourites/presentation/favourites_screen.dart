import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/favourites_repository.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouritesAsync = ref.watch(favouritesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favourites'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(favouritesListProvider),
          ),
        ],
      ),
      body: favouritesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved favourites yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save crop diseases for quick reference',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favouritesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final fav = items[index];
                final favId = fav['id'] as int;
                final disease = fav['disease_detail'] as Map<String, dynamic>? ?? {};
                final diseaseId = disease['id'] ?? fav['disease'];
                final diseaseName = disease['name'] ?? 'Crop Disease';
                final cropName = disease['crop_name'] ?? (disease['crop'] is Map ? disease['crop']['name'] : '');
                final notes = fav['notes']?.toString() ?? '';
                final severity = disease['severity']?.toString() ?? 'Medium';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(Icons.eco, color: AppColors.primary),
                    ),
                    title: Text(
                      diseaseName.toString().replaceAll('___', ' — ').replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cropName.isNotEmpty)
                          Text('Crop: $cropName', style: const TextStyle(fontSize: 13)),
                        Text('Severity: $severity', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                        if (notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Note: $notes',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await ref.read(favouritesRepositoryProvider).removeFavourite(favId);
                          ref.invalidate(favouritesListProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from favourites')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                    onTap: () {
                      if (diseaseId != null) {
                        context.push('/disease/$diseaseId');
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(favouritesListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
