import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../favourites/data/favourites_repository.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, this.scan});

  final Map<String, dynamic>? scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = scan ?? {};
    
    final raw = data['raw_response'] is Map 
        ? Map<String, dynamic>.from(data['raw_response'] as Map) 
        : data;

    final bool isLowConfidence = data['low_confidence'] == true || raw['low_confidence'] == true;
    final bool isHealthy = data['is_healthy'] == true || raw['is_healthy'] == true || (data['disease_name'] ?? '').toString().toLowerCase() == 'healthy';
    
    final String crop = (data['crop_name'] ?? data['crop_type'] ?? raw['crop_name'] ?? 'Unknown Crop').toString();
    final String disease = (data['disease_name'] ?? raw['disease_name'] ?? 'Unknown Disease').toString();
    final int? diseaseId = data['disease'] is int ? data['disease'] : (data['disease_id'] ?? raw['disease_id']);
    
    double confidenceVal = 0.0;
    final dynamic rawConf = data['confidence'] ?? raw['confidence'];
    if (rawConf != null) {
      final double parsed = double.tryParse(rawConf.toString()) ?? 0.0;
      confidenceVal = parsed <= 1.0 ? parsed * 100 : parsed;
    }
    final String confidence = confidenceVal.toStringAsFixed(1);
    
    final DateTime? scannedAt = DateTime.tryParse((data['scanned_at'] ?? data['created_at'] ?? '').toString())?.toLocal();

    void shareDiagnosis() {
      final shareText = '''
🌱 AgriVision AI — Crop Diagnosis Report
----------------------------------------
Crop: $crop
Diagnosis: $disease
Confidence: $confidence%
Scanned: ${scannedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(scannedAt) : 'N/A'}

Recommendation:
${data['recommendation'] ?? raw['recommendation'] ?? 'Consult AgriVision AI app for full treatment steps.'}

Analyzed by AgriVision AI Nepal.
''';
      Share.share(shareText, subject: 'AgriVision AI Diagnosis — $disease');
    }

    void saveFavourite() async {
      if (diseaseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disease details not found for saving.')),
        );
        return;
      }
      try {
        await ref.read(favouritesRepositoryProvider).addFavourite(diseaseId);
        ref.invalidate(favouritesListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Favourites!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save favourite: $e')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Analysis Results', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (diseaseId != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.primary),
              onPressed: saveFavourite,
              tooltip: 'Save Favourite',
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            onPressed: shareDiagnosis,
            tooltip: 'Share Diagnosis',
          ),
        ],
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // 1. Status / Header Card
          if (isLowConfidence)
            _buildLowConfidenceHeader(context, data, confidence)
          else if (isHealthy)
            _buildHealthyHeader(crop)
          else
            _buildDiseaseHeader(disease, crop, confidence, scannedAt),

          const SizedBox(height: 16),

          // 2. Image Display
          _buildImageSection(data),

          const SizedBox(height: 16),

          // 3. Body Content
          if (isLowConfidence)
            ..._buildLowConfidenceBody(context, data)
          else if (isHealthy)
            ..._buildHealthyBody(data, crop)
          else
            ..._buildDiseaseBody(data, raw),
            
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── Header Cards ────────────────────────────────────────────────────────

  Widget _buildLowConfidenceHeader(BuildContext context, Map<String, dynamic> data, String confidence) {
    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.warning.withAlpha(128), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.warning.withAlpha(51), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Low Confidence Scan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                  const SizedBox(height: 6),
                  Text(
                    'Inference confidence is only $confidence%. We cannot reliably identify the plant condition.',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthyHeader(String crop) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.healthy.withAlpha(128), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.healthy.withAlpha(51), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.healthy, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$crop is Healthy!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                  const SizedBox(height: 6),
                  const Text(
                    'No plant diseases detected. Keep up the good work!',
                    style: TextStyle(color: AppColors.darkGreen, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseHeader(String disease, String crop, String confidence, DateTime? scannedAt) {
    final cleanDisease = disease.contains('___') ? disease.split('___').last.replaceAll('_', ' ') : disease;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cleanDisease,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Text('$confidence%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text('Crop: $crop', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            if (scannedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(DateFormat('MMM d, y  h:mm a').format(scannedAt), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Image Section ───────────────────────────────────────────────────────

  Widget _buildImageSection(Map<String, dynamic> data) {
    final String imgUrl = (data['image_url'] ?? data['image'] ?? '').toString();
    if (imgUrl.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Image.network(
            imgUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Scanned Image', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Low Confidence Body ───────────────────────────────────────────────

  List<Widget> _buildLowConfidenceBody(BuildContext context, Map<String, dynamic> data) {
    final predictions = data['top_predictions'] as List? ?? [];
    return [
      _section(
        'Instructions',
        data['message'] ?? 'The system was unable to identify the crop leaf condition with high confidence.',
        icon: Icons.info_outline_rounded,
      ),
      if (predictions.isNotEmpty)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Possible Matches', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGreen, fontSize: 16)),
                const SizedBox(height: 12),
                ...predictions.map((p) {
                  final name = (p['name'] ?? p['class_label'] ?? '').toString().replaceAll('_', ' ').split('___').last;
                  final confVal = double.tryParse((p['confidence'] ?? '0').toString()) ?? 0.0;
                  final percentage = confVal <= 1.0 ? confVal * 100 : confVal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Retake Photo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
      ),
    ];
  }

  // ─── Healthy Body ──────────────────────────────────────────────────────

  List<Widget> _buildHealthyBody(Map<String, dynamic> data, String crop) {
    final careTips = data['general_care'] as List? ?? [
      'Water regularly and maintain consistent soil moisture.',
      'Use balanced NPK fertilizer during the growing season.',
      'Monitor for pests and remove any damaged leaves promptly.',
      'Ensure adequate spacing between plants for air circulation.',
    ];

    return [
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General Care for $crop', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGreen, fontSize: 17)),
              const SizedBox(height: 12),
              ...careTips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.healthy, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tip.toString(), style: const TextStyle(height: 1.3))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    ];
  }

  // ─── Disease Body ──────────────────────────────────────────────────────

  List<Widget> _buildDiseaseBody(Map<String, dynamic> data, Map<String, dynamic> raw) {
    final recommendation = data['recommendation'] ?? raw['recommendation'] ?? raw['treatment'];
    final medicines = data['medicines'] as List? ?? [];
    
    return [
      _optionalSection('Description', raw['description'], icon: Icons.description_outlined),
      _optionalSection('Symptoms', raw['symptoms'], icon: Icons.sick_outlined),
      _optionalSection('Causes', raw['causes'], icon: Icons.biotech_outlined),
      _optionalSection('Prevention Tips', raw['prevention'] ?? raw['prevention_tips'], icon: Icons.shield_outlined),
      _optionalSection('Organic Treatments', raw['organic_treatments'], icon: Icons.eco_outlined),
      _optionalSection('Chemical Treatments', raw['chemical_treatments'], icon: Icons.science_outlined),
      _optionalSection('cultivation Regions (Nepal)', raw['regional_recommendation'], icon: Icons.map_outlined),
      
      if (recommendation != null && recommendation.toString().isNotEmpty)
        _section('Summary Recommendation', _text(recommendation), icon: Icons.lightbulb_outline_rounded),

      if (medicines.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text('Recommended Medicines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        ),
        ...medicines.map((m) => _buildMedicineCard(Map<String, dynamic>.from(m as Map))),
      ],
    ];
  }

  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final bool isChemical = (med['type'] ?? '').toString().toLowerCase() == 'chemical';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    med['name'] ?? 'Unknown Medicine',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isChemical ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isChemical ? Colors.blue.shade200 : Colors.green.shade200),
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
            const SizedBox(height: 8),
            if ((med['active_ingredients'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Active Ingredient: ${med['active_ingredients']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
            const Divider(),
            _buildMedicineDetailRow(Icons.pin_drop_outlined, 'Dosage', med['dosage_guidance'] ?? med['dosage']),
            _buildMedicineDetailRow(Icons.layers_outlined, 'Method', med['application_method']),
            _buildMedicineDetailRow(Icons.security_outlined, 'Precautions', med['safety_precautions'], isWarning: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineDetailRow(IconData icon, String title, Object? value, {bool isWarning = false}) {
    final text = _text(value);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isWarning ? Colors.red.shade400 : AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _optionalSection(String title, Object? value, {IconData? icon}) {
    final text = _text(value);
    if (text.isEmpty) return const SizedBox.shrink();
    return _section(title, text, icon: icon);
  }

  Widget _section(String title, String body, {IconData? icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            Text(body, style: const TextStyle(height: 1.45, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  String _text(Object? value) {
    if (value == null) return '';
    if (value is List) return value.map((item) => item.toString()).where((item) => item.isNotEmpty).join('\n• ').trim().let((s) => s.isNotEmpty ? '• $s' : '');
    return value.toString().trim();
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

