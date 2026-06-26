import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/models/settings_model.dart';
import '../../core/models/piket_team_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/service_locator.dart';

class SmartCheckViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AppSettings? _settings;
  AppSettings? get settings => _settings;

  PiketTeam? _myPiketTeam;
  PiketTeam? get myPiketTeam => _myPiketTeam;

  double? _distance;
  double? get distance => _distance;

  bool _isInsideGeofence = false;
  bool get isInsideGeofence => _isInsideGeofence;

  bool _isWithinTimeWindow = false;
  bool get isWithinTimeWindow => _isWithinTimeWindow;

  bool _isHoliday = false;
  bool get isHoliday => _isHoliday;

  bool _isOnDutyToday = false;
  bool get isOnDutyToday => _isOnDutyToday;

  String _todayDayName = '';
  String get todayDayName => _todayDayName;

  final List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  int? _aiScore;
  int? get aiScore => _aiScore;

  List<String> _findings = [];
  List<String> get findings => _findings;

  bool get canUpload => _isInsideGeofence && _isWithinTimeWindow && !_isHoliday && _isOnDutyToday;

  Future<void> loadStatusAndConfig(String token) async {
    _isLoading = true;
    _errorMessage = null;
    _aiScore = null;
    _findings = [];
    notifyListeners();

    try {
      // 1. Get Settings & Holidays
      _settings = await _apiService.getSettings(token);
      final holidays = await _apiService.getHolidays(token);

      // 2. Get Student's Piket Team for today
      _todayDayName = DateFormat('EEEE').format(DateTime.now()); // e.g. "Monday"
      
      try {
        _myPiketTeam = await _apiService.getMyTeam(token);
        if (_myPiketTeam != null) {
          _isOnDutyToday = _myPiketTeam!.day?.toLowerCase() == _todayDayName.toLowerCase();
        }
      } catch (_) {
        _isOnDutyToday = false;
      }

      // 3. Get Current Position & Calculate Distance
      final position = await locator.locationService.getCurrentPosition();
      if (position != null && _settings != null) {
        _distance = locator.locationService.distanceBetween(
          position.latitude,
          position.longitude,
          _settings!.latitude,
          _settings!.longitude,
        );
        _isInsideGeofence = _distance! <= _settings!.radius;
      } else {
        _isInsideGeofence = false;
      }

      // 4. Verify Time Window
      if (_settings != null) {
        final now = DateTime.now();
        final startParts = _settings!.startTime.split(':');
        final endParts = _settings!.endTime.split(':');
        if (startParts.length >= 2 && endParts.length >= 2) {
          final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          final nowMin = now.hour * 60 + now.minute;
          _isWithinTimeWindow = nowMin >= startMin && nowMin <= endMin;
        }
      }

      // 5. Verify Holiday / Sunday
      final todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final isSunday = DateTime.now().weekday == DateTime.sunday;
      final isHolidayRegistered = holidays.any((h) => h['date'] == todayDateStr);
      _isHoliday = isSunday || isHolidayRegistered;

    } catch (e) {
      _errorMessage = 'Gagal memuat status & konfigurasi: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
      );
      
      if (images.isNotEmpty) {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages.removeRange(5, _selectedImages.length);
          notifyListeners();
          return 'Maksimal foto yang dapat diunggah adalah 5.';
        }
        notifyListeners();
      }
    } catch (e) {
      return 'Gagal mengambil foto: $e';
    }
    return null;
  }

  Future<String?> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      
      if (image != null) {
        if (_selectedImages.length >= 5) {
          return 'Maksimal foto yang dapat diunggah adalah 5.';
        } else {
          _selectedImages.add(image);
          notifyListeners();
        }
      }
    } catch (e) {
      return 'Gagal mengambil foto: $e';
    }
    return null;
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitPhotos(String token) async {
    if (_selectedImages.length < 3) {
      _errorMessage = 'Minimal 3 foto piket kelas harus diunggah.';
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

      final imagePaths = _selectedImages.map((img) => img.path).toList();
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
      _selectedImages.clear();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void resetSubmission() {
    _aiScore = null;
    _findings = [];
    _errorMessage = null;
    notifyListeners();
  }
}
