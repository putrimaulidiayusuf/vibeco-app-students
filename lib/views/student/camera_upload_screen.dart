import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/student/camera_upload_viewmodel.dart';
import '../../viewmodels/student/smart_check_viewmodel.dart';

class CameraUploadScreen extends StatefulWidget {
  final VoidCallback onViewHistory;
  const CameraUploadScreen({super.key, required this.onViewHistory});

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.token != null) {
        Provider.of<SmartCheckViewModel>(context, listen: false)
            .loadStatusAndConfig(auth.token!);
      }
    });
  }

  Future<void> _pickImage(CameraUploadViewModel vm, String slot, ImageSource source) async {
    final error = await vm.pickPhoto(slot, source);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  Future<void> _handleSubmit(CameraUploadViewModel vm, String token) async {
    final success = await vm.submitPhotos(token);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto piket berhasil dikirim! Hasil analisis AI siap.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Provider.of<SmartCheckViewModel>(context, listen: false).loadStatusAndConfig(token);
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
          color: file != null ? AppTheme.primaryGreen.withValues(alpha: 0.5) : Colors.grey.shade200,
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
                  file != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                  color: file != null ? AppTheme.success : AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
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
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.values[0]),
                ),
                 child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(vm, slotKey, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Ambil Foto Kamera (Real-time)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: AppTheme.primaryGreen,
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
      ],
      child: Consumer2<CameraUploadViewModel, SmartCheckViewModel>(
        builder: (context, uploadVm, statusVm, child) {
          if (statusVm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // If AI Score has been received in this session, show results!
          if (uploadVm.aiScore != null) {
            return SingleChildScrollView(
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
                        uploadVm.aiScore.toString(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: uploadVm.aiScore! >= 75 ? AppTheme.success : AppTheme.warning,
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
                  uploadVm.findings.isEmpty
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
                          itemCount: uploadVm.findings.length,
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        uploadVm.reset();
                        widget.onViewHistory();
                      },
                      child: const Text('LIHAT RIWAYAT & GRAFIK'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => uploadVm.reset(),
                      child: const Text('KIRIM LAPORAN BARU'),
                    ),
                  ),
                ],
              ),
            );
          }

          // Check upload permissions/status
          if (!statusVm.canUpload) {
            final isAlreadySubmitted = statusVm.isAlreadySubmittedToday;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: isAlreadySubmitted ? AppTheme.success.withValues(alpha: 0.1) : Colors.red.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAlreadySubmitted ? Icons.check_circle_rounded : Icons.lock_rounded,
                          color: isAlreadySubmitted ? AppTheme.success : AppTheme.error,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAlreadySubmitted ? 'Piket Hari Ini Selesai' : 'Piket Cek Dinonaktifkan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAlreadySubmitted ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAlreadySubmitted
                              ? 'Laporan piket hari ini sudah dikirim oleh ${statusVm.submittedByName ?? "anggota regu Anda"}.\nSetiap regu hanya perlu mengirim 1 laporan per hari.'
                              : 'Pengiriman foto piket hanya dapat dilakukan jika Anda memenuhi syarat berikut:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        if (!isAlreadySubmitted) ...[
                          const SizedBox(height: 16),
                          _buildStatusIndicator('Lokasi di Sekolah', statusVm.isInsideGeofence),
                          _buildStatusIndicator('Dalam Batas Waktu Piket', statusVm.isWithinTimeWindow),
                          _buildStatusIndicator('Hari Sekolah (Senin-Sabtu)', !statusVm.isHoliday),
                          _buildStatusIndicator('Jadwal Piket Anda Hari Ini', statusVm.isOnDutyToday),
                        ],
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => statusVm.loadStatusAndConfig(token),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh Status'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (statusVm.myPiketTeam != null) {
            uploadVm.initAttendance(statusVm.myPiketTeam!.members);
          }

          if (!uploadVm.showCamera) {
            return RefreshIndicator(
              onRefresh: () => statusVm.loadStatusAndConfig(token),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Daftar Kehadiran Regu Piket',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi status kehadiran setiap anggota regu piket hari ini sebelum mengambil foto.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildStatusOption(
                                    label: 'Piket',
                                    isSelected: att.status == 'piket',
                                    color: AppTheme.success,
                                    onTap: () => uploadVm.updateStudentStatus(att.studentId, 'piket'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusOption(
                                    label: 'Kabur',
                                    isSelected: att.status == 'kabur',
                                    color: AppTheme.warning,
                                    onTap: () => uploadVm.updateStudentStatus(att.studentId, 'kabur'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusOption(
                                    label: 'Absen',
                                    isSelected: att.status == 'tidak sekolah',
                                    color: AppTheme.error,
                                    onTap: () => uploadVm.updateStudentStatus(att.studentId, 'tidak sekolah'),
                                  ),
                                ],
                              ),
                              if (att.status != 'piket') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Alasan ${att.status == 'kabur' ? "Kabur" : "Absen"} (Opsional)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    labelStyle: const TextStyle(fontSize: 13),
                                  ),
                                  onChanged: (val) => uploadVm.updateStudentReason(att.studentId, val),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: uploadVm.attendanceList.isNotEmpty
                          ? () => uploadVm.proceedToCamera()
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('LANJUT KE KAMERA'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => statusVm.loadStatusAndConfig(token),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => uploadVm.reset(),
                      ),
                      const Expanded(
                        child: Text(
                          'Unggah Foto Piket Kelas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance back button
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Wajib mengunggah semua 3 foto dengan sudut pandang berbeda untuk dianalisis oleh AI.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // The 3 Photo Slots
                  _buildPhotoSlot(
                    title: 'Tampak Depan Kelas',
                    subtitle: 'Ambil foto dari arah pintu masuk menghadap papan tulis',
                    file: uploadVm.frontPhoto,
                    slotKey: 'front',
                    vm: uploadVm,
                  ),
                  _buildPhotoSlot(
                    title: 'Tampak Belakang Kelas',
                    subtitle: 'Ambil foto dari depan kelas menghadap ke arah belakang',
                    file: uploadVm.backPhoto,
                    slotKey: 'back',
                    vm: uploadVm,
                  ),
                  _buildPhotoSlot(
                    title: 'Foto Tambahan',
                    subtitle: 'Ambil foto alat kebersihan atau kebersihan lantai kelas',
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        uploadVm.errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  uploadVm.isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: uploadVm.isReadyToSubmit ? () => _handleSubmit(uploadVm, token) : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('KIRIM LAPORAN PIKET'),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String title, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: isValid ? AppTheme.success : AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.black87 : Colors.black54,
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
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
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
}
