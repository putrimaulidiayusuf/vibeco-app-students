import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/student/smart_check_viewmodel.dart';

class SmartCheckScreen extends StatefulWidget {
  const SmartCheckScreen({super.key});

  @override
  State<SmartCheckScreen> createState() => _SmartCheckScreenState();
}

class _SmartCheckScreenState extends State<SmartCheckScreen> {
  String translateDay(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return englishDay;
    }
  }

  Future<void> _handleImagePick(SmartCheckViewModel viewModel) async {
    final error = await viewModel.pickImages();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  Future<void> _handleCapture(SmartCheckViewModel viewModel) async {
    final error = await viewModel.captureImage();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  Future<void> _handleSubmit(SmartCheckViewModel viewModel) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final success = await viewModel.submitPhotos(token);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto piket berhasil dikirim! Hasil analisis AI siap.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;

    return ChangeNotifierProvider<SmartCheckViewModel>(
      create: (context) {
        final vm = SmartCheckViewModel();
        if (token != null) {
          vm.loadStatusAndConfig(token);
        }
        return vm;
      },
      child: Consumer<SmartCheckViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                  value: viewModel.isInsideGeofence
                      ? 'Di Sekolah'
                      : 'Di luar sekolah (${viewModel.distance?.toStringAsFixed(1) ?? "-"}m)',
                  isValid: viewModel.isInsideGeofence,
                  helper: viewModel.settings != null ? 'Maksimal ${viewModel.settings!.radius.toStringAsFixed(0)} meter dari koordinat sekolah' : null,
                ),
                const SizedBox(height: 10),
                _buildStatusCard(
                  icon: Icons.access_time_rounded,
                  title: 'Waktu Pengiriman',
                  value: viewModel.isWithinTimeWindow ? 'Buka' : 'Tutup',
                  isValid: viewModel.isWithinTimeWindow,
                  helper: viewModel.settings != null ? 'Batas waktu: ${viewModel.settings!.startTime} s/d ${viewModel.settings!.endTime} WIB' : null,
                ),
                const SizedBox(height: 10),
                _buildStatusCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Hari Kerja / Libur',
                  value: viewModel.isHoliday ? 'Hari Libur / Minggu' : 'Hari Sekolah',
                  isValid: !viewModel.isHoliday,
                  helper: 'Pengiriman dinonaktifkan pada hari libur dan hari Minggu',
                ),
                const SizedBox(height: 10),
                _buildStatusCard(
                  icon: Icons.assignment_ind_rounded,
                  title: 'Jadwal Piket Anda',
                  value: viewModel.isOnDutyToday ? 'Hari Ini Piket' : 'Tidak Piket Hari Ini',
                  isValid: viewModel.isOnDutyToday,
                  helper: 'Hari Ini: ${translateDay(viewModel.todayDayName)}',
                ),
                const SizedBox(height: 24),

                // Upload Section
                if (viewModel.canUpload && viewModel.aiScore == null) ...[
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
                          if (viewModel.selectedImages.isNotEmpty) ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: viewModel.selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      child: Image.file(
                                        File(viewModel.selectedImages[index].path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => viewModel.removeImage(index),
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
                                  onPressed: () => _handleCapture(viewModel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_rounded),
                                  label: const Text('Galeri'),
                                  onPressed: () => _handleImagePick(viewModel),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          viewModel.isSubmitting
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: viewModel.selectedImages.length >= 3 ? () => _handleSubmit(viewModel) : null,
                                  child: Text('KIRIM JADWAL PIKET (${viewModel.selectedImages.length} Foto)'),
                                ),
                        ],
                      ),
                    ),
                  ),
                ] else if (viewModel.aiScore != null) ...[
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
                                viewModel.aiScore.toString(),
                                key: const ValueKey('ai_score_text'),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: viewModel.aiScore! >= 75 ? AppTheme.success : AppTheme.warning,
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
                          viewModel.findings.isEmpty
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
                                  itemCount: viewModel.findings.length,
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
                                              viewModel.findings[index],
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
                            onPressed: viewModel.resetSubmission,
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

                if (viewModel.errorMessage != null) ...[
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
                            viewModel.errorMessage!,
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
        },
      ),
    );
  }
}

