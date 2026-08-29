import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../models/disease_model.dart';
import '../../services/disease_service.dart';
import 'disease_detail_screen.dart';

class DiseaseListScreen extends StatefulWidget {
  const DiseaseListScreen({super.key});

  @override
  State<DiseaseListScreen> createState() => _DiseaseListScreenState();
}

class _DiseaseListScreenState extends State<DiseaseListScreen> {
  final _diseaseService = DiseaseService();
  final _searchCtrl = TextEditingController();
  List<Disease> _diseases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final result = await _diseaseService.getDiseases(search: search);
      setState(() => _diseases = result.diseases);
    } catch (_) {
      // keep list empty on error; a SnackBar could be added here
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Disease library')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search diseases or crops',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onSubmitted: (v) => _load(search: v),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _diseases.isEmpty
                      ? const Center(
                          child: Text('No diseases found', style: TextStyle(color: AppColors.gray500)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _diseases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = _diseases[i];
                            final color = AppColors.severityColor(d.severityLevel);
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: d.sampleImageUrl != null && d.sampleImageUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: ApiConfig.resolveImage(d.sampleImageUrl),
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => const Icon(Icons.eco_outlined),
                                          )
                                        : Container(
                                            color: AppColors.gray100,
                                            child: const Icon(Icons.eco_outlined, color: AppColors.gray500),
                                          ),
                                  ),
                                ),
                                title: Text(d.diseaseName,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(d.cropType ?? '',
                                    style: const TextStyle(color: AppColors.gray500)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(d.severityLevel ?? '-',
                                      style: TextStyle(
                                          color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => DiseaseDetailScreen(diseaseId: d.id!))),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
