import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/models/piket_team_model.dart';
import '../../viewmodels/student/smart_check_viewmodel.dart';
import '../../widgets/universal_image/universal_image.dart';

class SmartCheckScreen extends StatefulWidget {
  const SmartCheckScreen({super.key});

  @override
  State<SmartCheckScreen> createState() => _SmartCheckScreenState();
}

class _SmartCheckScreenState extends State<SmartCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    if (locationStatus.isDenied || cameraStatus.isDenied) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Izin Akses Aplikasi'),
              ],
            ),
            content: const Text(
              'Aplikasi VibEco memerlukan izin Lokasi (untuk memverifikasi kehadiran di geofence sekolah) dan Kamera (bila Anda mengunggah bukti foto piket).',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  // Request permissions
                  await [
                    Permission.locationWhenInUse,
                    Permission.camera,
                  ].request();

                  if (!mounted) return;
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final token = auth.token;
                  if (token != null && mounted) {
                    final vm = Provider.of<SmartCheckViewModel>(
                      context,
                      listen: false,
                    );
                    vm.loadStatusAndConfig(token);
                  }
                },
                child: const Text('Izinkan'),
              ),
            ],
          ),
        );
      }
    }
  }

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

  String _getEnglishDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getTeamMembersStr(String dateStr, List<PiketTeam> schedules) {
    try {
      final date = DateTime.parse(dateStr);
      final englishDay = _getEnglishDayName(date.weekday);
      final team = schedules.firstWhere(
        (t) => t.day?.toLowerCase() == englishDay.toLowerCase(),
      );
      if (team.members.isEmpty) return 'Tidak ada jadwal piket';
      return team.members.map((m) => m.name).join(', ');
    } catch (_) {
      return 'Tidak terjadwal';
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

  String _formatFullDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayName = _getDayNameIndonesian(date.weekday);
      final monthName = _getMonthNameIndonesian(date.month);
      return '$dayName, ${date.day} $monthName ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getDayNameIndonesian(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _getMonthNameIndonesian(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = AppTheme.success;
        text = 'Disetujui';
        break;
      case 'adjusted':
        color = AppTheme.primaryLight;
        text = 'Disesuaikan';
        break;
      case 'rejected':
        color = AppTheme.error;
        text = 'Ditolak';
        break;
      default:
        color = AppTheme.warning;
        text = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
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
                color: isValid
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
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

    if (token == null) {
      return const Center(child: Text('Sesi habis. Silakan login kembali.'));
    }

    return ChangeNotifierProvider<SmartCheckViewModel>(
      create: (context) {
        final vm = SmartCheckViewModel();
        vm.loadStatusAndConfig(token);
        return vm;
      },
      child: Consumer<SmartCheckViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadStatusAndConfig(token),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'VibEco SmartCheck',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Status kelayakan piket dan riwayat laporan kebersihan mingguan kelas Anda.',
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
                    helper: viewModel.settings != null
                        ? 'Maksimal ${viewModel.settings!.radius.toStringAsFixed(0)} meter dari koordinat sekolah'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildStatusCard(
                    icon: Icons.access_time_rounded,
                    title: 'Waktu Pengiriman',
                    value: viewModel.isWithinTimeWindow ? 'Buka' : 'Tutup',
                    isValid: viewModel.isWithinTimeWindow,
                    helper: viewModel.settings != null
                        ? 'Batas waktu: ${viewModel.settings!.startTime} s/d ${viewModel.settings!.endTime} WIB'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildStatusCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Hari Kerja / Libur',
                    value: viewModel.isHoliday
                        ? 'Hari Libur / Akhir Pekan'
                        : 'Hari Sekolah',
                    isValid: !viewModel.isHoliday,
                    helper:
                        'Pengiriman dinonaktifkan pada hari libur dan akhir pekan',
                  ),
                  const SizedBox(height: 10),
                  _buildStatusCard(
                    icon: Icons.assignment_ind_rounded,
                    title: 'Jadwal Piket Anda',
                    value: viewModel.isOnDutyToday
                        ? 'Hari Ini Piket'
                        : 'Tidak Piket Hari Ini',
                    isValid: viewModel.isOnDutyToday,
                    helper: 'Hari Ini: ${translateDay(viewModel.todayDayName)}',
                  ),
                  const SizedBox(height: 24),

                  // Weekly Bar Chart Widget
                  WeeklyBarChart(scores: viewModel.weeklyScores),
                  const SizedBox(height: 24),

                  // History Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Riwayat Laporan Minggu Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),

                  if (viewModel.weeklySubmissions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada laporan minggu ini.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...viewModel.weeklySubmissions.map((sub) {
                      final teamMembers = _getTeamMembersStr(
                        sub.date,
                        viewModel.schedules,
                      );
                      final uploadTime = _formatTime(sub.createdAt);
                      final displayScore = sub.displayScore;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatFullDate(sub.date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Diunggah oleh: ${sub.submittedBy ?? "Siswa"} • Jam $uploadTime WIB',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(sub.status),
                                ],
                              ),
                              const Divider(height: 20),

                              // Photo thumbnails
                              if (sub.photoUrls.isNotEmpty) ...[
                                const Text(
                                  'Foto Dokumentasi:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: sub.photoUrls.length,
                                    itemBuilder: (context, pIndex) {
                                      final path = sub.photoUrls[pIndex];
                                      final imageUrl = path.startsWith('http')
                                          ? path
                                          : '${AppConfig.baseUrl}/storage/$path';

                                      // Label of the photo based on index
                                      String slotLabel = 'Foto ${pIndex + 1}';
                                      if (pIndex == 0) slotLabel = 'Depan';
                                      if (pIndex == 1) slotLabel = 'Belakang';
                                      if (pIndex == 2) slotLabel = 'Tambahan';

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppTheme.radiusSmall,
                                                    ),
                                                child: UniversalImage(
                                                  imageUrl: imageUrl,
                                                  width: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 80,
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          child: const Icon(
                                                            Icons
                                                                .broken_image_rounded,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              slotLabel,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Duty team info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.group_rounded,
                                    size: 16,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Petugas Piket Hari Itu: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: teamMembers),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Score section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Score: ${sub.aiScore ?? "-"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Text(
                                            'Skor Akhir: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            sub.isPending
                                                ? 'Menunggu Validasi'
                                                : displayScore.toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: sub.isPending
                                                  ? Colors.orange
                                                  : (displayScore >= 75
                                                        ? AppTheme.success
                                                        : AppTheme.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      displayScore.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // AI Findings
                              if (sub.findings.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: sub.findings.map((finding) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        finding,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Validation notes
                              if (!sub.isPending &&
                                  sub.notes != null &&
                                  sub.notes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.rate_review_rounded,
                                            size: 14,
                                            color: AppTheme.primaryGreen,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Catatan Guru PLH (${sub.verifiedBy ?? "PLH"}):',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: AppTheme.primaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sub.notes!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WeeklyBarChart extends StatelessWidget {
  final Map<String, double> scores;
  const WeeklyBarChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    // Find the maximum score to highlight it
    double maxScore = 0.0;
    String maxDay = '';
    scores.forEach((day, score) {
      if (score > maxScore) {
        maxScore = score;
        maxDay = day;
      }
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Grafik Piket Minggu Ini (Senin - Jumat)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: scores.entries.map((entry) {
                final day = entry.key;
                final score = entry.value;
                final isMax = day == maxDay && score > 0;

                return Column(
                  children: [
                    // Score Text
                    Text(
                      score > 0 ? '${score.toInt()}%' : '0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                        color: score > 0
                            ? (isMax ? AppTheme.primaryGreen : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bar
                    Container(
                      height:
                          120 *
                          (score / 100).clamp(
                            0.05,
                            1.0,
                          ), // Min height so it's visible as a tiny base if 0
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: score > 0
                            ? (isMax
                                  ? const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0xFF1B5E20),
                                        Color(0xFF43A047),
                                      ],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0xFF43A047),
                                        Color(0xFF81C784),
                                      ],
                                    ))
                            : null,
                        color: score == 0 ? Colors.grey.shade200 : null,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: isMax
                            ? Border.all(color: Colors.amber, width: 2)
                            : null,
                        boxShadow: isMax
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day Label
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isMax ? FontWeight.bold : FontWeight.w500,
                        color: isMax ? AppTheme.primaryGreen : Colors.black54,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
