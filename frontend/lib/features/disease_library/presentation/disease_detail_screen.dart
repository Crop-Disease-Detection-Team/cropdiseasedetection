import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/disease_repository.dart';

final diseaseDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, int>((ref, diseaseId) async {
  return ref.watch(diseaseRepositoryProvider).fetchDiseaseDetail(diseaseId);
});

class DiseaseDetailScreen extends ConsumerWidget {
  const DiseaseDetailScreen({super.key, required this.diseaseId});

  final int diseaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(diseaseDetailProvider(diseaseId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Disease Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        data: (d) {
          final name = (d['name'] ?? 'Disease Detail').toString().replaceAll('_', ' ').split('___').last;
          final cropName = d['crop']?['name'] ?? d['crop_name'] ?? 'Crop';
          final sciName = d['scientific_name'] ?? '';
          final severity = d['severity']?.toString() ?? 'Medium';

          final symptoms = d['symptoms']?.toString() ?? '';
          final causes = d['causes']?.toString() ?? '';
          final organic = d['organic_treatments']?.toString() ?? '';
          final chemical = d['chemical_treatments']?.toString() ?? '';
          final prevention = d['prevention_tips']?.toString() ?? '';
          final regional = d['regional_recommendation']?.toString() ?? '';
          final medicines = d['medicines'] as List? ?? d['medicine_mappings'] as List? ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            severity,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Crop: $cropName', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (sciName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Scientific: $sciName',
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (d['description'] != null && d['description'].toString().isNotEmpty)
                _section('Overview', d['description'].toString(), icon: Icons.description_outlined),

              if (symptoms.isNotEmpty)
                _section('Symptoms', symptoms, icon: Icons.sick_outlined),

              if (causes.isNotEmpty)
                _section('Causes', causes, icon: Icons.biotech_outlined),

              if (prevention.isNotEmpty)
                _section('Prevention Tips', prevention, icon: Icons.shield_outlined),

              if (organic.isNotEmpty)
                _section('Organic Remedies', organic, icon: Icons.eco_outlined),

              if (chemical.isNotEmpty)
                _section('Chemical Treatments', chemical, icon: Icons.science_outlined),

              if (regional.isNotEmpty)
                _section('Nepal Regional Recommendations', regional, icon: Icons.map_outlined),

              if (medicines.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Recommended Medicines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                const SizedBox(height: 10),
                ...medicines.map((m) {
                  final med = m is Map && m.containsKey('medicine') ? Map<String, dynamic>.from(m['medicine'] as Map) : Map<String, dynamic>.from(m as Map);
                  return _buildMedicineCard(med);
                }),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading details: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _section(String title, String body, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGreen, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(height: 1.4, color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final bool isChemical = (med['type'] ?? '').toString().toLowerCase() == 'chemical';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  med['name'] ?? 'Medicine',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isChemical ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isChemical ? 'Chemical' : 'Organic',
                  style: TextStyle(
                    color: isChemical ? Colors.blue.shade800 : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (med['dosage_guidance'] != null || med['dosage'] != null)
            Text('Dosage: ${med['dosage_guidance'] ?? med['dosage']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          if (med['application_method'] != null)
            Text('Method: ${med['application_method']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
