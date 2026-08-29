import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../models/scan_model.dart';
import '../../services/api_exception.dart';
import '../../services/history_service.dart';
import '../predict/predict_screen.dart';
import '../settings/server_settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  List<ScanRecord> _scans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _historyService.getHistory(perPage: 50);
      setState(() => _scans = result.scans);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not load history: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(ScanRecord s) {
    final color = AppColors.severityColor(s.severity);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.resolveImage(s.imageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.gray100,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(s.diseaseName,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _detailRow('Confidence', '${s.displayConfidence.toStringAsFixed(1)}%'),
              _detailRow(
                'Severity',
                s.severity ?? '-',
                valueColor: color,
                chip: true,
              ),
              _detailRow(
                'Scanned on',
                s.scannedAt != null
                    ? DateFormat('MMM d, y • h:mm a')
                        .format(DateTime.parse(s.scannedAt!).toLocal())
                    : '-',
              ),
              if (s.recommendation != null && s.recommendation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recommendation',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.gray700)),
                const SizedBox(height: 6),
                Text(s.recommendation!,
                    style: const TextStyle(color: AppColors.gray700, height: 1.4)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const PredictScreen()));
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Scan again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor, bool chip = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
          ),
          Expanded(
            child: chip
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (valueColor ?? AppColors.gray500)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(value,
                          style: TextStyle(
                              color: valueColor ?? AppColors.gray900,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  )
                : Text(value,
                    style: TextStyle(
                        color: valueColor ?? AppColors.gray900,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('This deletes all your scan records. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.red600))),
        ],
      ),
    );
    if (confirm == true) {
      await _historyService.clearHistory();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Scan history'),
        actions: [
          if (_scans.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearAll),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 40, color: AppColors.gray300),
                          const SizedBox(height: 12),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.gray700)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final changed = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                          builder: (_) => const ServerSettingsScreen()));
                                  if (changed == true) _load();
                                },
                                child: const Text('Server settings'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : _scans.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.history, size: 56, color: AppColors.gray300),
                          SizedBox(height: 12),
                          Center(
                              child: Text('No scans yet',
                                  style: TextStyle(color: AppColors.gray500))),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _scans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _scans[i];
                          final color = AppColors.severityColor(s.severity);
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showDetail(s),
                              child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: s.imageUrl != null && s.imageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: ApiConfig.resolveImage(s.imageUrl),
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(Icons.image_not_supported_outlined),
                                            )
                                          : Container(
                                              color: AppColors.gray100,
                                              child: const Icon(Icons.eco_outlined,
                                                  color: AppColors.gray500),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.diseaseName,
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 3),
                                        Text(
                                          s.scannedAt != null
                                              ? DateFormat('MMM d, y • h:mm a')
                                                  .format(DateTime.parse(s.scannedAt!).toLocal())
                                              : '',
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.gray500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${s.displayConfidence.toStringAsFixed(1)}%',
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(AppRadius.full),
                                        ),
                                        child: Text(s.severity ?? '-',
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
