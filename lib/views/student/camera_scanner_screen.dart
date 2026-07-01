import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/onnx_predictor.dart';
import '../../core/theme/app_theme.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  Timer? _scanTimer;
  String _predictionText = "Mengidentifikasi...";
  double _confidence = 0.0;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _predictionText = "Kamera tidak ditemukan";
        });
        return;
      }

      final backCam = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _startScanTimer();
    } catch (e) {
      print("Camera initialization error: $e");
      if (mounted) {
        setState(() {
          _predictionText = "Error kamera: $e";
        });
      }
    }
  }

  void _startScanTimer() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_isProcessing || !_isInitialized || _controller == null || !_controller!.value.isInitialized) {
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      String? tempPath;
      try {
        final XFile file = await _controller!.takePicture();
        tempPath = file.path;

        final result = await OnnxPredictor().predict(tempPath);
        if (mounted && result['success'] == true) {
          setState(() {
            _predictionText = "${result['class_name']}";
            _confidence = result['confidence'] as double;
            _lastResult = result;
          });
        }
      } catch (e) {
        print("Real-time scan prediction error: $e");
      } finally {
        if (tempPath != null) {
          final fileToDelete = File(tempPath);
          if (await fileToDelete.exists()) {
            await fileToDelete.delete();
          }
        }
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    });
  }

  Future<void> _captureAndReturn() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _scanTimer?.cancel();
    _scanTimer = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
    );

    try {
      final XFile file = await _controller!.takePicture();
      final String finalPath = file.path;

      final result = await OnnxPredictor().predict(finalPath);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        Navigator.pop(context, {
          'imagePath': finalPath,
          'prediction': result,
        });
      }
    } catch (e) {
      print("Capture failed: $e");
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil foto: $e")),
        );
        _startScanTimer(); // Resume scan timer
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                _predictionText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Transform.scale(
            scale: 1 / (_controller!.value.aspectRatio * deviceRatio),
            alignment: Alignment.topCenter,
            child: CameraPreview(_controller!),
          ),

          Center(
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryGreen, width: 3.0),
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),

          Positioned(
            top: 60.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Pindai Sampah Real-Time",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _confidence > 0.0
                              ? "$_predictionText (${(_confidence * 100).toStringAsFixed(1)}%)"
                              : "Mengidentifikasi...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 40.0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Arahkan kamera ke sampah lalu jepret foto",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    GestureDetector(
                      onTap: _captureAndReturn,
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
