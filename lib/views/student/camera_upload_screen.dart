import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/student/camera_upload_viewmodel.dart';
import '../../viewmodels/student/smart_check_viewmodel.dart';

class CameraUploadScreen extends StatefulWidget {
  final VoidCallback onViewHistory;
  final ValueChanged<bool>? onShowCameraChanged;
  final bool asRoute;
  const CameraUploadScreen({
    super.key,
    required this.onViewHistory,
    this.onShowCameraChanged,
    this.asRoute = false,
  });

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> {
  SmartCheckViewModel? _statusViewModel;
  bool _lastShowCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.token != null) {
        _statusViewModel?.loadStatusAndConfig(auth.token!);
      }
    });
  }

  Future<void> _pickImage(
    CameraUploadViewModel vm,
    String slot,
    ImageSource source,
  ) async {
    final error = await vm.pickPhoto(slot, source);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.warning),
      );
    }
  }

  Future<void> _handleSubmit(CameraUploadViewModel vm, String token) async {
    final success = await vm.submitPhotos(token);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foto piket berhasil dikirim! Hasil analisis AI siap.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        // Refresh the status and history views
        _statusViewModel?.loadStatusAndConfig(token);
      } else if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPhotoSlot({
    required String title,
    required String subtitle,
    required XFile? file,
    required String slotKey,
    required CameraUploadViewModel vm,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: file != null
              ? AppTheme.success.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  file != null
                      ? Icons.check_circle_rounded
                      : Icons.add_a_photo_rounded,
                  color: file != null ? AppTheme.success : AppColors.emeraldMid,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                    ),
                    onPressed: () => vm.removePhoto(slotKey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.file(
                  File(file.path),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    style: BorderStyle.values[0],
                  ),
                ),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _pickImage(vm, slotKey, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: AppColors.emeraldMid,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final token = auth.token;

    if (token == null) {
      return const Center(child: Text('Sesi habis. Silakan login kembali.'));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CameraUploadViewModel>(
          create: (_) => CameraUploadViewModel(),
        ),
        ChangeNotifierProvider<SmartCheckViewModel>(
          create: (_) {
            final vm = SmartCheckViewModel();
            _statusViewModel = vm;
            vm.loadStatusAndConfig(token);
            return vm;
          },
        ),
      ],
      child: Consumer2<CameraUploadViewModel, SmartCheckViewModel>(
        builder: (context, uploadVm, statusVm, child) {
          final showCamera =
              uploadVm.showCamera &&
              statusVm.canUpload &&
              uploadVm.aiScore == null;
          if (showCamera != _lastShowCamera) {
            _lastShowCamera = showCamera;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onShowCameraChanged?.call(showCamera);
              }
            });
          }

          String headerTitle = 'Unggah Foto Piket Kelas';
          String headerSubtitle =
              'Wajib mengunggah semua 3 foto dengan sudut pandang berbeda untuk dianalisis oleh AI.';
          VoidCallback? onBack = widget.onViewHistory;

          if (statusVm.isLoading) {
            headerTitle = 'Memuat...';
            headerSubtitle = 'Mohon tunggu sebentar.';
          } else if (uploadVm.aiScore != null) {
            headerTitle = 'Hasil Analisis AI';
            headerSubtitle =
                'Berikut adalah hasil penilaian kebersihan kelas Anda hari ini.';
          } else if (!statusVm.canUpload) {
            headerTitle = 'Status Piket';
            headerSubtitle = 'Cek kelayakan untuk melakukan piket hari ini.';
          } else if (!uploadVm.showCamera) {
            headerTitle = 'Daftar Kehadiran Regu Piket';
            headerSubtitle =
                'Isi status kehadiran setiap anggota regu piket hari ini sebelum mengambil foto.';
          }

          if (!uploadVm.showCamera &&
              statusVm.canUpload &&
              uploadVm.aiScore == null) {
            onBack = widget.onViewHistory;
          } else if (uploadVm.showCamera &&
              statusVm.canUpload &&
              uploadVm.aiScore == null) {
            onBack = () => uploadVm.reset();
          }

          Widget bodyWidget;
          if (statusVm.isLoading) {
            bodyWidget = const Center(child: CircularProgressIndicator());
          } else if (uploadVm.aiScore != null) {
            bodyWidget = SingleChildScrollView(
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
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
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        uploadVm.aiScore.toString(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: uploadVm.aiScore! >= 75
                              ? AppTheme.success
                              : AppTheme.warning,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  uploadVm.findings.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '✓ Kelas sangat bersih! Tidak ada masalah ditemukan.',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: uploadVm.findings.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      uploadVm.findings[index],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                  _buildGradientButton(
                    text: 'LIHAT RIWAYAT & GRAFIK',
                    onPressed: () {
                      uploadVm.reset();
                      widget.onViewHistory();
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => uploadVm.reset(),
                      child: const Text('KIRIM LAPORAN BARU'),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          } else if (!statusVm.canUpload) {
            final isAlreadySubmitted = statusVm.isAlreadySubmittedToday;
            bodyWidget = Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isAlreadySubmitted
                              ? AppColors.primaryGreen.withValues(alpha: 0.1)
                              : Colors.red.shade100,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isAlreadySubmitted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/maskotbingung.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_rounded, size: 14, color: AppColors.error),
                                        SizedBox(width: 4),
                                        Text(
                                          'TERKUNCI',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.error,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryGreen,
                                size: 48,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Text(
                            isAlreadySubmitted
                                ? 'Piket Hari Ini Selesai'
                                : 'Pengiriman Terkunci',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isAlreadySubmitted
                                  ? AppColors.emeraldDark
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAlreadySubmitted
                                ? 'Laporan piket kelas Anda hari ini telah berhasil dikirim oleh ${statusVm.submittedByName ?? "anggota regu Anda"}.\n\nSetiap regu hanya perlu mengirimkan 1 laporan per hari.'
                                : 'Anda belum dapat mengirimkan laporan piket. Pastikan semua persyaratan berikut terpenuhi:',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          if (!isAlreadySubmitted) ...[
                            const SizedBox(height: 20),
                            _buildStatusIndicator(
                              'Lokasi berada di Sekolah',
                              statusVm.isInsideGeofence,
                            ),
                            _buildStatusIndicator(
                              'Waktu piket sesuai jadwal',
                              statusVm.isWithinTimeWindow,
                            ),
                            _buildStatusIndicator(
                              'Hari sekolah (Senin - Jumat)',
                              !statusVm.isHoliday,
                            ),
                            _buildStatusIndicator(
                              'Jadwal piket Anda hari ini',
                              statusVm.isOnDutyToday,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  statusVm.loadStatusAndConfig(token),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Refresh Status'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emeraldMid,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          } else if (!uploadVm.showCamera) {
            if (statusVm.myPiketTeam != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  uploadVm.initAttendance(statusVm.myPiketTeam!.members);
                }
              });
            }
            bodyWidget = RefreshIndicator(
              onRefresh: () => statusVm.loadStatusAndConfig(token),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...uploadVm.attendanceList.map((att) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                att.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildStatusOption(
                                    label: 'Piket',
                                    isSelected: att.status == 'piket',
                                    color: AppTheme.success,
                                    onTap: () => uploadVm.updateStudentStatus(
                                      att.studentId,
                                      'piket',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusOption(
                                    label: 'Kabur',
                                    isSelected: att.status == 'kabur',
                                    color: AppTheme.warning,
                                    onTap: () => uploadVm.updateStudentStatus(
                                      att.studentId,
                                      'kabur',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusOption(
                                    label: 'Absen',
                                    isSelected: att.status == 'tidak sekolah',
                                    color: AppTheme.error,
                                    onTap: () => uploadVm.updateStudentStatus(
                                      att.studentId,
                                      'tidak sekolah',
                                    ),
                                  ),
                                ],
                              ),
                              if (att.status != 'piket') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText:
                                        'Alasan ${att.status == 'kabur' ? "Kabur" : "Absen"} (Opsional)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    labelStyle: const TextStyle(fontSize: 13),
                                  ),
                                  onChanged: (val) => uploadVm
                                      .updateStudentReason(att.studentId, val),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    _buildGradientButton(
                      text: 'LANJUT KE KAMERA',
                      onPressed: uploadVm.attendanceList.isNotEmpty
                          ? () => uploadVm.proceedToCamera()
                          : null,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          } else {
            bodyWidget = RefreshIndicator(
              onRefresh: () => statusVm.loadStatusAndConfig(token),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The 3 Photo Slots
                    _buildPhotoSlot(
                      title: 'Tampak Depan Kelas',
                      subtitle:
                          'Ambil foto dari arah pintu masuk menghadap papan tulis',
                      file: uploadVm.frontPhoto,
                      slotKey: 'front',
                      vm: uploadVm,
                    ),
                    _buildPhotoSlot(
                      title: 'Tampak Belakang Kelas',
                      subtitle:
                          'Ambil foto dari depan kelas menghadap ke arah belakang',
                      file: uploadVm.backPhoto,
                      slotKey: 'back',
                      vm: uploadVm,
                    ),
                    _buildPhotoSlot(
                      title: 'Foto Tambahan',
                      subtitle:
                          'Ambil foto alat kebersihan atau kebersihan lantai kelas',
                      file: uploadVm.extraPhoto,
                      slotKey: 'extra',
                      vm: uploadVm,
                    ),

                    if (uploadVm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          uploadVm.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    uploadVm.isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : _buildGradientButton(
                            text: 'KIRIM LAPORAN PIKET',
                            onPressed: uploadVm.isReadyToSubmit
                                ? () => _handleSubmit(uploadVm, token)
                                : null,
                          ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAF8),
            body: Column(
              children: [
                // FIXED EMERALD GRADIENT HEADER
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (showCamera || widget.asRoute)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: onBack,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 48, height: 48),
                              Expanded(
                                child: Text(
                                  headerTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 48, height: 48), // spacer
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            headerSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: bodyWidget),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String title, bool isValid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFFF1F8F5) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? const Color(0xFFE2F0EA) : const Color(0xFFFFE5E5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isValid ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isValid ? AppColors.emeraldDark : AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isEnabled ? AppColors.emeraldGradient : null,
        color: isEnabled ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.emeraldDark.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
