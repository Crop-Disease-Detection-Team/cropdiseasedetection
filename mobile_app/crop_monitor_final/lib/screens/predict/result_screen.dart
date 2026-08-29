import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/disease_model.dart';

class ResultScreen extends StatelessWidget {
  final Disease disease;
  final File image;

  const ResultScreen({super.key, required this.disease, required this.image});

  /// Backend confidence values are inconsistently scaled in places (0–1 vs
  /// 0–100) depending on which code path produced them — the web app
  /// itself normalizes this client-side the same way, so we mirror that
  /// here rather than trusting the raw number.
  static double? _displayConfidence(double? raw) {
    if (raw == null) return null;
    return raw <= 1 ? raw * 100 : raw;
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = AppColors.severityColor(disease.severityLevel);
    final confidencePct = _displayConfidence(disease.confidence);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Scan result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.file(image, height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    disease.diseaseName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${confidencePct?.toStringAsFixed(1) ?? '--'}%',
                    style: const TextStyle(
                        color: AppColors.green700, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (disease.cropType != null) _tag(disease.cropType!, AppColors.gray100, AppColors.gray700),
                const SizedBox(width: 8),
                if (disease.severityLevel != null)
                  _tag('${disease.severityLevel} severity', severityColor.withValues(alpha: 0.12), severityColor),
              ],
            ),
            const SizedBox(height: 20),
            _section('Description', disease.description),
            _section('Symptoms', disease.symptoms),
            _section('Causes', disease.causes),
            _section('Organic treatment', disease.organicTreatment, icon: Icons.eco_outlined),
            _section('Chemical treatment', disease.chemicalTreatment, icon: Icons.science_outlined),
            _section('Prevention tips', disease.preventionTips, icon: Icons.shield_outlined),
            if (disease.medicines.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recommended medicines',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...disease.medicines.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.medicineName,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (m.dosagePerLiter != null)
                            Text('Dosage: ${m.dosagePerLiter}',
                                style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                          if (m.type != null)
                            Text('Type: ${m.type}',
                                style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                        ],
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _section(String title, String? content, {IconData? icon}) {
    if (content == null || content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.green700),
                const SizedBox(width: 6),
              ],
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(color: AppColors.gray700, height: 1.4)),
        ],
      ),
    );
  }
}
