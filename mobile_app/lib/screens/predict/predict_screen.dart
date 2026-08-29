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
      appBar: AppBar(title: const Text('Scan a leaf')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
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
