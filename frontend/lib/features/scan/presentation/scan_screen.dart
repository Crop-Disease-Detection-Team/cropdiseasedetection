import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/scan_repository.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String? _error;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera unavailable: $e');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final image = await _controller!.takePicture();
      if (mounted) setState(() => _capturedImage = image);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() => _capturedImage = image);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not select image: $e');
    }
  }

  Future<void> _analyze() async {
    final image = _capturedImage;
    if (image == null) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final result = await ref.read(scanRepositoryProvider).predict(image);
      ref.invalidate(scanHistoryProvider);
      final scan = result['history'] is Map ? Map<String, dynamic>.from(result['history'] as Map) : result;
      if (mounted) context.push('/result', extra: scan);
    } catch (e) {
      if (mounted) setState(() => _error = 'Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCapture = _capturedImage != null;
    final isOnline = ref.watch(connectivityProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Leaf'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are offline. AI Analysis requires an internet connection.',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: AppColors.darkGreen,
                    child: _cameraContent(),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (!hasCapture)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isCameraInitialized ? _capture : null,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 5)),
                            child: Center(child: Container(width: 54, height: 54, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary))),
                          ),
                        ),
                        const SizedBox(width: 60), // Spacer balancing Gallery button
                      ],
                    )
                  else ...[
                    PrimaryButton(label: 'Scan / Analyze', isLoading: _isAnalyzing, onTap: (_isAnalyzing || !isOnline) ? null : _analyze),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : () => setState(() => _capturedImage = null),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _cameraContent() {
    if (_capturedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<dynamic>(
            future: _capturedImage!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data, fit: BoxFit.cover);
              }
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black70, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 6),
                  Text('Leaf Selected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_isCameraInitialized && _controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 3), borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
