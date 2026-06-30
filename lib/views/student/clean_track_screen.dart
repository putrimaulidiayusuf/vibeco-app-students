import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/models/submission_model.dart';
import '../../viewmodels/student/clean_track_viewmodel.dart';

class CleanTrackScreen extends StatefulWidget {
  const CleanTrackScreen({super.key});

  @override
  State<CleanTrackScreen> createState() => _CleanTrackScreenState();
}

class _CleanTrackScreenState extends State<CleanTrackScreen> {
  String _formatDateIndonesian(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      final dayName = days[date.weekday % 7];
      final monthName = months[date.month];
      return '$dayName, ${date.day} $monthName ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? createdAtStr) {
    if (createdAtStr == null) return '--:--';
    try {
      final dateTime = DateTime.parse(createdAtStr).toLocal();
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return '--:--';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        text = 'Disetujui';
        break;
      case 'adjusted':
        color = AppColors.info;
        text = 'Disesuaikan';
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Ditolak';
        break;
      default:
        color = AppColors.warning;
        text = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.emeraldGradient,
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Laporan Piket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Daftar bukti kebersihan kelas Anda',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ChangeNotifierProvider<CleanTrackViewModel>(
        create: (context) {
          final vm = CleanTrackViewModel();
          if (token != null) {
            vm.fetchHistory(token);
          }
          return vm;
        },
        child: Consumer<CleanTrackViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.submissions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: 16),
                    Text('Memuat riwayat laporan...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            if (viewModel.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (token != null) viewModel.fetchHistory(token);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (viewModel.submissions.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  if (token != null) await viewModel.fetchHistory(token);
                },
                color: AppColors.primaryGreen,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 56,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Belum Ada Riwayat Piket',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Unggah bukti piket hari ini sekarang juga!',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (token != null) await viewModel.fetchHistory(token);
              },
              color: AppColors.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: viewModel.submissions.length,
                itemBuilder: (context, index) {
                  final sub = viewModel.submissions[index];
                  final displayScore = sub.displayScore;
                  final timeStr = _formatTime(sub.createdAt);
                  final hasScoreDetails = sub.dailyClassScore != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDateIndonesian(sub.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.emeraldDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pengirim: ${sub.submittedBy ?? "Siswa"} • $timeStr WIB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(sub.status),
                            ],
                          ),
                        ),

                        // Photo Gallery (Thumbnails)
                        if (sub.photoUrls.isNotEmpty) ...[
                          SizedBox(
                            height: 96,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: sub.photoUrls.length,
                              itemBuilder: (context, pIndex) {
                                final path = sub.photoUrls[pIndex];
                                final imageUrl = path.startsWith('http')
                                    ? path
                                    : '${AppConfig.baseUrl}/storage/$path';

                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.network(
                                        imageUrl,
                                        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                                        width: 110,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 110,
                                            height: 96,
                                            color: Colors.grey.shade100,
                                            child: const Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Main info footer (Scores & AI summary)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8EFE8)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Score: ${sub.aiScore ?? "-"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text(
                                            'Skor Akhir: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.emeraldDark,
                                            ),
                                          ),
                                          Text(
                                            sub.isPending ? 'Menunggu Validasi' : displayScore.toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: sub.isPending
                                                  ? Colors.orange
                                                  : (displayScore >= 75
                                                      ? AppColors.success
                                                      : AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Score badge circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: sub.isPending
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : (displayScore >= 75
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.1)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: sub.isPending
                                          ? Colors.orange.withValues(alpha: 0.3)
                                          : (displayScore >= 75
                                              ? AppColors.success.withValues(alpha: 0.3)
                                              : AppColors.error.withValues(alpha: 0.3)),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      sub.isPending ? '?' : displayScore.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: sub.isPending
                                            ? Colors.orange
                                            : (displayScore >= 75
                                                ? AppColors.success
                                                : AppColors.error),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action button & notes
                        if (hasScoreDetails || (sub.notes != null && sub.notes!.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                if (hasScoreDetails)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryGreen,
                                        side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _showScoreDetailsSheet(context, sub),
                                      icon: const Icon(Icons.assessment_rounded, size: 18),
                                      label: const Text(
                                        'Rincian Penilaian',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showScoreDetailsSheet(BuildContext context, PiketSubmission sub) {
    final scoreData = sub.dailyClassScore!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rincian Penilaian Kebersihan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                              Text(
                                _formatDateIndonesian(sub.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Content List
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        // Grade and Category Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.emeraldDark, AppColors.emeraldMid],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kategori Kebersihan',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      scoreData.kategori,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    scoreData.score.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Aspects of cleanliness
                        const Text(
                          'Aspek Penilaian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...scoreData.aspekPenilaian.entries.map((item) {
                          final key = item.key;
                          final aspect = item.value;

                          // Human readable aspect names
                          String displayName = key;
                          IconData aspectIcon = Icons.cleaning_services_rounded;
                          if (key == 'kebersihan_lantai') {
                            displayName = 'Kebersihan Lantai';
                            aspectIcon = Icons.layers_outlined;
                          } else if (key == 'kerapian_meja_kursi') {
                            displayName = 'Kerapian Meja & Kursi';
                            aspectIcon = Icons.table_restaurant_outlined;
                          } else if (key == 'kebersihan_papan_tulis') {
                            displayName = 'Kebersihan Papan Tulis';
                            aspectIcon = Icons.square_foot_outlined;
                          } else if (key == 'manajemen_sampah') {
                            displayName = 'Manajemen Sampah';
                            aspectIcon = Icons.delete_outline_rounded;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(aspectIcon, color: AppColors.primaryGreen, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.emeraldDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${aspect.skor} / 100',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: aspect.skor >= 75 ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: aspect.skor / 100,
                                    backgroundColor: Colors.grey[100],
                                    color: aspect.skor >= 75 ? AppColors.success : AppColors.warning,
                                    minHeight: 6,
                                  ),
                                ),
                                if (aspect.catatan.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    aspect.catatan,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 14),

                        // Object findings / temuan
                        if (sub.findings.isNotEmpty) ...[
                          const Text(
                            'Temuan Kebersihan AI',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFE0B2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sub.findings.map((f) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          f,
                                          style: const TextStyle(
                                            color: Color(0xFFE65100),
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Recommendations / Saran perbaikan
                        if (scoreData.saranPerbaikan.isNotEmpty) ...[
                          const Text(
                            'Saran Perbaikan Kebersihan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              children: scoreData.saranPerbaikan.map((saran) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          saran,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey[700],
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // Homeroom / Verifier notes
                        if (sub.notes != null && sub.notes!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Catatan Guru PLH',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDCEDC8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.rate_review_outlined, color: AppColors.primaryGreen, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Validasi oleh: ${sub.verifiedBy ?? "Guru PLH"}',
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sub.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
