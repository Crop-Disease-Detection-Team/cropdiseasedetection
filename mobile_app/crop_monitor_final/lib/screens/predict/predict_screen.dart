import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../services/predict_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/primary_button.dart';
import 'result_screen.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _picker = ImagePicker();
  final _predictService = PredictService();
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() => _loading = true);
    try {
      final result = await _predictService.predict(_selectedImage!);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(disease: result, image: _selectedImage!)),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Prediction failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Scan a leaf!')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _GuidanceCard(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.gray300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image_outlined, size: 64, color: AppColors.gray300),
                          SizedBox(height: 12),
                          Text('No image selected',
                              style: TextStyle(color: AppColors.gray500)),
                          SizedBox(height: 4),
                          Text('Take a clear photo of the affected leaf',
                              style: TextStyle(color: AppColors.gray500, fontSize: 12)),
                        ],
                      )
                    : Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Analyze leaf',
                icon: Icons.auto_awesome,
                loading: _loading,
                onPressed: _selectedImage == null ? null : _analyze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors the "Before you scan" guidance card from the web app's
/// predict page — dataset note, photo tips, and the AI-limitation
/// disclaimer — collapsed by default so it doesn't crowd the small
/// screen, but always visible at the top like on web.
class _GuidanceCard extends StatefulWidget {
  @override
  State<_GuidanceCard> createState() => _GuidanceCardState();
}

class _GuidanceCardState extends State<_GuidanceCard> {
  bool _expanded = false;

  static const _tips = [
    'Photograph a single leaf, not the whole plant',
    'Use natural daylight — avoid harsh shadows or flash glare',
    'Keep the leaf in sharp focus, filling most of the frame',
    'Use a plain, contrasting background (a table or your hand works well)',
    'One leaf per photo gives the most accurate diagnosis',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.green100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.green700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Before you scan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.gray500),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            const Text(
              'This model is trained on the PlantVillage dataset and works best '
              'on crops and diseases represented in that dataset. Results for '
              'other crops or unusual conditions may be less reliable.',
              style: TextStyle(fontSize: 12.5, color: AppColors.gray700, height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text('For best results',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 6),
            ..._tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.green700),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(t,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.gray700))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 8),
          const Text(
            'This tool offers AI-assisted guidance, not a substitute for a '
            'professional agronomist. For valuable crops or uncertain cases, '
            'please confirm with a local expert before acting.',
            style: TextStyle(
                fontSize: 11.5,
                color: AppColors.gray500,
                fontStyle: FontStyle.italic,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}
