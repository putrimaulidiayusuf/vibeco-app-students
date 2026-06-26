import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/service_locator.dart';
import '../../core/models/settings_model.dart';
import '../../core/models/piket_team_model.dart';

class SmartCheckScreen extends StatefulWidget {
  const SmartCheckScreen({super.key});

  @override
  State<SmartCheckScreen> createState() => _SmartCheckScreenState();
}

class _SmartCheckScreenState extends State<SmartCheckScreen> {
  final _apiService = ApiService();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Configuration & Status
  AppSettings? _settings;
  PiketTeam? _myPiketTeam;
  double? _distance;
  bool _isInsideGeofence = false;
  bool _isWithinTimeWindow = false;
  bool _isHoliday = false;
  bool _isOnDutyToday = false;
  String _todayDayName = '';

  // Selected Images
  final List<XFile> _selectedImages = [];

  // Submission Result
  int? _aiScore;
  List<String> _findings = [];

  @override
  void initState() {
    super.initState();
    _loadStatusAndConfig();
  }

  Future<void> _loadStatusAndConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiScore = null;
      _findings = [];
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      // 1. Get Settings & Holidays
      _settings = await _apiService.getSettings(token);
      final holidays = await _apiService.getHolidays(token);

      // 2. Get Student's Piket Team for today
      _todayDayName = DateFormat('EEEE').format(DateTime.now()); // e.g. "Monday"
      
      try {
        _myPiketTeam = await _apiService.getMyTeam(token);
        // Check if student is on duty today
        if (_myPiketTeam != null) {
          _isOnDutyToday = _myPiketTeam!.day?.toLowerCase() == _todayDayName.toLowerCase();
        }
      } catch (_) {
        // If no team schedule is found, treat as not on duty
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maksimal foto yang dapat diunggah adalah 5.'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      
      if (image != null) {
        setState(() {
          if (_selectedImages.length >= 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maksimal foto yang dapat diunggah adalah 5.'),
                backgroundColor: AppTheme.warning,
              ),
            );
          } else {
            _selectedImages.add(image);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 3 foto piket kelas harus diunggah.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

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

      setState(() {
        _aiScore = result['ai_score'];
        final rawFindings = result['findings'];
        if (rawFindings is List) {
          _findings = rawFindings.map((f) => f.toString()).toList();
        } else {
          _findings = [];
        }
        _selectedImages.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto piket berhasil dikirim! Hasil analisis AI siap.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isValid,
    String? helper,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isValid ? AppTheme.success : AppTheme.error,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isValid ? AppTheme.primaryDark : AppTheme.error,
                    ),
                  ),
                  if (helper != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      helper,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isValid ? AppTheme.success : AppTheme.error,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool canUpload = _isInsideGeofence && _isWithinTimeWindow && !_isHoliday && _isOnDutyToday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'ZieClean SmartCheck',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kirim foto hasil piket kelas Anda hari ini untuk dianalisis oleh AI ZieClean.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Status Cards
          _buildStatusCard(
            icon: Icons.my_location_rounded,
            title: 'Lokasi Anda (Geofence)',
            value: _isInsideGeofence
                ? 'Di Sekolah'
                : 'Di luar sekolah (${_distance?.toStringAsFixed(1) ?? "-"}m)',
            isValid: _isInsideGeofence,
            helper: _settings != null ? 'Maksimal ${_settings!.radius.toStringAsFixed(0)} meter dari koordinat sekolah' : null,
          ),
          const SizedBox(height: 10),
          _buildStatusCard(
            icon: Icons.access_time_rounded,
            title: 'Waktu Pengiriman',
            value: _isWithinTimeWindow ? 'Buka' : 'Tutup',
            isValid: _isWithinTimeWindow,
            helper: _settings != null ? 'Batas waktu: ${_settings!.startTime} s/d ${_settings!.endTime} WIB' : null,
          ),
          const SizedBox(height: 10),
          _buildStatusCard(
            icon: Icons.calendar_today_rounded,
            title: 'Hari Kerja / Libur',
            value: _isHoliday ? 'Hari Libur / Minggu' : 'Hari Sekolah',
            isValid: !_isHoliday,
            helper: 'Pengiriman dinonaktifkan pada hari libur dan hari Minggu',
          ),
          const SizedBox(height: 10),
          _buildStatusCard(
            icon: Icons.assignment_ind_rounded,
            title: 'Jadwal Piket Anda',
            value: _isOnDutyToday ? 'Hari Ini Piket' : 'Tidak Piket Hari Ini',
            isValid: _isOnDutyToday,
            helper: 'Hari Ini: $_todayDayName',
          ),
          const SizedBox(height: 24),

          // Upload Section
          if (canUpload && _aiScore == null) ...[
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Foto Hasil Piket Kelas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unggah 3 sampai 5 foto kebersihan kelas (contoh: lantai, meja, sudut kelas).',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Photo preview grid
                    if (_selectedImages.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Capture / Select Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Kamera'),
                            onPressed: _captureImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Galeri'),
                            onPressed: _pickImages,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _selectedImages.length >= 3 ? _handleSubmit : null,
                            child: Text('KIRIM JADWAL PIKET (${_selectedImages.length} Foto)'),
                          ),
                  ],
                ),
              ),
            ),
          ] else if (_aiScore != null) ...[
            // AI Analysis Result Card
            Card(
              elevation: 4,
              color: AppTheme.surfaceGreen,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analisis AI Selesai!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 20),

                    // Score Display
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _aiScore.toString(),
                          key: const ValueKey('ai_score_text'),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _aiScore! >= 75 ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Score (Skor Awal)',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Findings
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Temuan Kebersihan (AI Findings):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _findings.isEmpty
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '✓ Kelas sangat bersih! Tidak ada masalah ditemukan.',
                              style: TextStyle(color: AppTheme.success, fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _findings.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _findings[index],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                    const Text(
                      '*Skor ini bersifat sementara dan akan divalidasi oleh Guru PLH untuk mendapatkan skor akhir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _aiScore = null;
                          _findings = [];
                        });
                      },
                      child: const Text('KIRIM ULANG / LANJUTKAN'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Can't upload message
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.lock_rounded, color: AppTheme.error, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Piket Cek Dinonaktifkan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.error),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pengiriman foto piket hanya dapat dilakukan jika Anda berada di sekolah, dalam batas waktu piket, pada hari sekolah, dan Anda terdaftar piket hari ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
