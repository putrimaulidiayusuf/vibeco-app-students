import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../core/services/onnx_predictor.dart';
import '../../core/theme/app_theme.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  String _predictionText = "Arahkan kamera ke objek...";
  double _confidence = 0.0;
  Timer? _scanTimer;
  bool _streamActive = false;
  CameraImage? _latestFrame;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _predictionText = "Kamera tidak ditemukan");
        }
        return;
      }

      final backCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCam,
        ResolutionPreset.medium, // medium for preview quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isInitialized = true);

      // Start the image stream for real-time scanning
      _startImageStream();
    } catch (e) {
      if (mounted) {
        setState(() => _predictionText = "Error kamera: $e");
      }
    }
  }

  void _startImageStream() {
    if (_streamActive || _controller == null) return;

    _controller!.startImageStream((CameraImage frame) {
      // Just store the latest frame, don't process every one
      _latestFrame = frame;
    });
    _streamActive = true;

    // Process a frame every 2.5 seconds
    _scanTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _processLatestFrame();
    });

    // Also process the first frame after a short delay
    Future.delayed(const Duration(milliseconds: 800), _processLatestFrame);
  }

  Future<void> _processLatestFrame() async {
    if (_isProcessing || _isCapturing || _latestFrame == null || !mounted) return;

    _isProcessing = true;
    final frame = _latestFrame!;

    try {
      // Convert CameraImage (YUV420) to RGB Image, then center-crop
      final img.Image? rgbImage = _convertYUV420toImage(frame);
      if (rgbImage == null) {
        _isProcessing = false;
        return;
      }

      // Center crop 70% of the image (matching the scan box overlay)
      final int cropSize = (rgbImage.width < rgbImage.height
              ? rgbImage.width
              : rgbImage.height) *
          70 ~/
          100;
      final int offsetX = (rgbImage.width - cropSize) ~/ 2;
      final int offsetY = (rgbImage.height - cropSize) ~/ 2;
      final img.Image cropped = img.copyCrop(
        rgbImage,
        x: offsetX,
        y: offsetY,
        width: cropSize,
        height: cropSize,
      );

      // Save to a temporary file for OnnxPredictor
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/scan_frame_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 85));

      final result = await OnnxPredictor().predict(tempFile.path);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (mounted && result['success'] == true) {
        final double conf = result['confidence'] as double;
        setState(() {
          if (conf < 0.40) {
            _predictionText = "Objek tidak dikenali";
            _confidence = conf;
          } else {
            _predictionText = "${result['class_name']}";
            _confidence = conf;
          }
        });
      }
    } catch (e) {
      // Silently continue scanning on error
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert YUV420 CameraImage to img.Image (RGB)
  img.Image? _convertYUV420toImage(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final yRowStride = yPlane.bytesPerRow;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStride = uPlane.bytesPerPixel ?? 1;

      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          final int yVal = yPlane.bytes[yIndex];
          final int uVal = uPlane.bytes[uvIndex];
          final int vVal = vPlane.bytes[uvIndex];

          // YUV to RGB conversion
          int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
          int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
              .round()
              .clamp(0, 255);
          int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }

      return image;
    } catch (e) {
      return null;
    }
  }

  Future<void> _captureAndReturn() async {
    if (!_isInitialized || _controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    // Stop the image stream before taking a picture
    if (_streamActive) {
      _scanTimer?.cancel();
      _scanTimer = null;
      await _controller!.stopImageStream();
      _streamActive = false;
    }

    // Brief pause to let the camera stabilize after stopping stream
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

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
      final String originalPath = file.path;

      // Crop the captured image in the exact same way as the live frame
      final Uint8List originalBytes = await File(originalPath).readAsBytes();
      final img.Image? decodedImg = img.decodeImage(originalBytes);
      
      String finalPath = originalPath;
      if (decodedImg != null) {
        final int cropSize = (decodedImg.width < decodedImg.height
                ? decodedImg.width
                : decodedImg.height) *
            70 ~/
            100;
        final int offsetX = (decodedImg.width - cropSize) ~/ 2;
        final int offsetY = (decodedImg.height - cropSize) ~/ 2;
        final img.Image croppedImg = img.copyCrop(
          decodedImg,
          x: offsetX,
          y: offsetY,
          width: cropSize,
          height: cropSize,
        );

        // Overwrite the original file with the cropped image
        final File croppedFile = File(originalPath);
        await croppedFile.writeAsBytes(img.encodeJpg(croppedImg, quality: 90));
      }

      final result = await OnnxPredictor().predict(finalPath);

      if (mounted) {
        Navigator.pop(context); // Dismiss spinner
        Navigator.pop(context, {
          'imagePath': finalPath,
          'prediction': result,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil foto: $e")),
        );
        setState(() => _isCapturing = false);
        // Restart stream
        _startImageStream();
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    if (_streamActive && _controller != null) {
      _controller!.stopImageStream().catchError((_) {});
    }
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
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
          // Camera preview
          Transform.scale(
            scale: 1 / (_controller!.value.aspectRatio * deviceRatio),
            alignment: Alignment.topCenter,
            child: CameraPreview(_controller!),
          ),

          // Scan box overlay
          Center(
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _confidence >= 0.40
                      ? AppTheme.primaryGreen
                      : Colors.orange,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),

          // Top status bar
          Positioned(
            top: 60.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _confidence >= 0.40
                        ? Icons.auto_awesome
                        : Icons.search,
                    color: _confidence >= 0.40
                        ? AppTheme.primaryGreen
                        : Colors.orange,
                  ),
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
                              : "Arahkan kamera ke objek...",
                          style: TextStyle(
                            color: _confidence >= 0.40
                                ? Colors.white
                                : Colors.orange.shade200,
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

          // Bottom controls
          Positioned(
            bottom: 40.0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _confidence < 0.40 && _confidence > 0
                      ? "Confidence rendah - dekatkan objek ke kotak scan"
                      : "Arahkan kamera ke sampah lalu jepret foto",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
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
