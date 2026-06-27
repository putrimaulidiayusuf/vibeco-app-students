import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/services/service_locator.dart';

class CameraUploadViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _frontPhoto;
  XFile? _backPhoto;
  XFile? _extraPhoto;

  XFile? get frontPhoto => _frontPhoto;
  XFile? get backPhoto => _backPhoto;
  XFile? get extraPhoto => _extraPhoto;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _aiScore;
  int? get aiScore => _aiScore;

  List<String> _findings = [];
  List<String> get findings => _findings;

  bool get isReadyToSubmit => _frontPhoto != null && _backPhoto != null && _extraPhoto != null;

  Future<String?> pickPhoto(String slot, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (image != null) {
        if (slot == 'front') {
          _frontPhoto = image;
        } else if (slot == 'back') {
          _backPhoto = image;
        } else if (slot == 'extra') {
          _extraPhoto = image;
        }
        notifyListeners();
      }
    } catch (e) {
      return 'Gagal mengambil foto: $e';
    }
    return null;
  }

  void removePhoto(String slot) {
    if (slot == 'front') {
      _frontPhoto = null;
    } else if (slot == 'back') {
      _backPhoto = null;
    } else if (slot == 'extra') {
      _extraPhoto = null;
    }
    notifyListeners();
  }

  Future<bool> submitPhotos(String token) async {
    if (!isReadyToSubmit) {
      _errorMessage = 'Semua 3 slot foto (tampak depan, tampak belakang, dan foto tambahan) harus diisi.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await locator.locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Gagal mendapatkan lokasi GPS Anda. Aktifkan GPS Anda.');
      }

      final imagePaths = [
        _frontPhoto!.path,
        _backPhoto!.path,
        _extraPhoto!.path,
      ];

      final result = await _apiService.submitPhotos(
        token,
        imagePaths,
        position.latitude,
        position.longitude,
      );

      _aiScore = result['ai_score'];
      final rawFindings = result['findings'];
      if (rawFindings is List) {
        _findings = rawFindings.map((f) => f.toString()).toList();
      } else {
        _findings = [];
      }
      
      // Clear photos upon successful submission
      _frontPhoto = null;
      _backPhoto = null;
      _extraPhoto = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _frontPhoto = null;
    _backPhoto = null;
    _extraPhoto = null;
    _aiScore = null;
    _findings = [];
    _errorMessage = null;
    notifyListeners();
  }
}
