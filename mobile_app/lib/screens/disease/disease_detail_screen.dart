import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/disease_model.dart';
import '../../services/disease_service.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final int diseaseId;
  const DiseaseDetailScreen({super.key, required this.diseaseId});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final _diseaseService = DiseaseService();
  Disease? _disease;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _diseaseService.getDiseaseDetail(widget.diseaseId);
      setState(() => _disease = d);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _section(String title, String? content) {
    if (content == null || content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(color: AppColors.gray700, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: Text(_disease?.diseaseName ?? 'Disease detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _disease == null
              ? const Center(child: Text('Could not load this disease'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_disease!.scientificName != null)
                      Text(_disease!.scientificName!,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, color: AppColors.gray500)),
                    const SizedBox(height: 12),
                    _section('Description', _disease!.description),
                    _section('Symptoms', _disease!.symptoms),
                    _section('Causes', _disease!.causes),
                    _section('Organic treatment', _disease!.organicTreatment),
                    _section('Chemical treatment', _disease!.chemicalTreatment),
                    _section('Prevention tips', _disease!.preventionTips),
                    _section('Cultivation regions (Nepal)', _disease!.cultivationRegions),
                    if (_disease!.medicines.isNotEmpty) ...[
                      const Text('Recommended medicines',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ..._disease!.medicines.map((m) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(m.medicineName,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}
