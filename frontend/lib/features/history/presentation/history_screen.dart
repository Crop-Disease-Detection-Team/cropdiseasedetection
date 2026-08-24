import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../scan/data/scan_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final history = ref.watch(scanHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('history')), backgroundColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(scanHistoryProvider),
        child: history.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.history_rounded, size: 54, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(strings.t('noHistory'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(strings.t('historyHint'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) => _HistoryItem(scan: items[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [Text(error.toString(), style: const TextStyle(color: AppColors.error))],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  const _HistoryItem({required this.scan});

  final Map<String, dynamic> scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannedAt = DateTime.tryParse((scan['scanned_at'] ?? scan['created_at'] ?? '').toString())?.toLocal();
    final confidence = ((num.tryParse(scan['confidence'].toString()) ?? 0) * 100).clamp(0, 100).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/result', extra: scan),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Thumbnail(url: scan['image_url']?.toString() ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan['disease_name']?.toString() ?? 'Unknown disease', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Confidence: $confidence%', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                    if (scannedAt != null)
                      Text(
                        '${DateFormat('MMM d, y').format(scannedAt)}  ${DateFormat('h:mm a').format(scannedAt)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete scan?'),
                      content: const Text('This scan history item will be permanently removed.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(scanRepositoryProvider).deleteScan(int.parse(scan['id'].toString()));
                    ref.invalidate(scanHistoryProvider);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.eco_rounded, color: AppColors.primary),
    );
  }
}
