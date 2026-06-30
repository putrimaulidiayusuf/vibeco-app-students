import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/student/dashboard_viewmodel.dart';

class PiketScheduleScreen extends StatefulWidget {
  const PiketScheduleScreen({super.key});

  @override
  State<PiketScheduleScreen> createState() => _PiketScheduleScreenState();
}

class _PiketScheduleScreenState extends State<PiketScheduleScreen> {
  String _formatDateIndonesian(DateTime date) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    final dashVm = Provider.of<DashboardViewModel>(context);

    // Reload data if needed
    if (dashVm.myClassSchedule == null && !dashVm.isLoadingSchedule && token != null) {
      dashVm.loadScheduleData(token);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.emeraldGradient,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jadwal Piket Kelas ${dashVm.myClassSchedule?.className ?? ""}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Hari ini: ${dashVm.todayIndonesian}, ${_formatDateIndonesian(DateTime.now())}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Piket Hari Ini'),
              Tab(text: 'Jadwal Keseluruhan'),
            ],
          ),
        ),
        body: dashVm.isLoadingSchedule
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    SizedBox(height: 16),
                    Text('Memuat jadwal piket...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : dashVm.scheduleError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            dashVm.scheduleError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (token != null) {
                                dashVm.loadScheduleData(token);
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      if (token != null) {
                        await dashVm.loadScheduleData(token);
                      }
                    },
                    color: AppColors.primaryGreen,
                    child: TabBarView(
                      children: [
                        // TAB 1: Piket Hari Ini
                        _buildTodayDutyTab(dashVm),
                        // TAB 2: Jadwal Keseluruhan
                        _buildScheduleContent(dashVm),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTodayDutyTab(DashboardViewModel vm) {
    final todayDuty = vm.todayDuty;
    final hasToday = todayDuty != null && todayDuty.students.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        if (hasToday) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.emeraldDark, AppColors.emeraldMid],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emeraldDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Regu Piket Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            vm.todayIndonesian,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todayDuty.students.length} Siswa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Anggota Regu Piket:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayDuty.students.length,
                  itemBuilder: (context, idx) {
                    final student = todayDuty.students[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                student.name.isNotEmpty ? student.name[0] : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'NIS: ${student.nis}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.cleaning_services_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                    Icons.event_busy_rounded,
                    size: 64,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tidak Ada Piket Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selamat beristirahat! Pastikan tetap menjaga kebersihan kelas ya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleContent(DashboardViewModel vm) {
    if (vm.myClassSchedule == null) return const SizedBox.shrink();

    final todayEnglish = vm.todayEnglish;
    final allDays = DashboardViewModel.orderedDays;
    final grouped = vm.myClassSchedule!.groupedByDay;

    // Filter to only days that have entries
    final activeDays = allDays.where((d) => grouped.containsKey(d)).toList();

    if (activeDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada jadwal piket keseluruhan',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: activeDays.length,
      itemBuilder: (context, index) {
        final day = activeDays[index];
        final entries = grouped[day]!;
        final isToday = day.toLowerCase() == todayEnglish.toLowerCase();
        final dayLabel = vm.translateDay(day);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isToday
                  ? Border.all(color: AppColors.primaryGreen, width: 2)
                  : Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: isToday
                      ? AppColors.primaryGreen.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: isToday ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Day header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primaryGreen.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primaryGreen
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isToday ? Icons.today_rounded : Icons.calendar_view_day_rounded,
                          color: isToday ? Colors.white : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primaryGreen : AppColors.emeraldDark,
                          ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'HARI INI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primaryGreen.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entries.length} siswa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primaryGreen : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student list
                ...entries.asMap().entries.map((mapEntry) {
                  final i = mapEntry.key;
                  final entry = mapEntry.value;
                  final isLast = i == entries.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        // Avatar with number
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                                : const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? AppColors.primaryGreen : Colors.grey[600]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.studentName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                              Text(
                                'NIS: ${entry.studentNis}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isToday)
                          Icon(
                            Icons.cleaning_services_rounded,
                            color: AppColors.primaryGreen.withValues(alpha: 0.5),
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
