import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../viewmodels/teacher/piket_management_viewmodel.dart';

class PiketManagementScreen extends StatefulWidget {
  const PiketManagementScreen({super.key});

  @override
  State<PiketManagementScreen> createState() => _PiketManagementScreenState();
}

class _PiketManagementScreenState extends State<PiketManagementScreen> {
  String translateDay(String engDay) {
    switch (engDay.toLowerCase()) {
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
        return engDay;
    }
  }

  Future<void> _showAssignDialog(PiketManagementViewModel viewModel, String day) async {
    int? selectedStudentId;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text('Atur Piket Hari ${translateDay(day)}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Pilih siswa untuk ditugaskan piket pada hari ini:'),
                    const SizedBox(height: 16),
                    viewModel.classStudents.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Tidak ada siswa terdaftar di kelas ini.',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Nama Siswa',
                              border: OutlineInputBorder(),
                            ),
                            items: viewModel.classStudents.map<DropdownMenuItem<int>>((student) {
                              return DropdownMenuItem<int>(
                                value: student['id'] as int,
                                child: Text('${student['name']} (${student['nis']})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateDialog(() {
                                selectedStudentId = val;
                              });
                            },
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedStudentId != null ? () => Navigator.pop(dialogContext, true) : null,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true && selectedStudentId != null && viewModel.teacherClassId != null && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      final success = await viewModel.updateStudentSchedule(
        token: token,
        schoolClassId: viewModel.teacherClassId!,
        studentId: selectedStudentId!,
        dayOfWeek: day,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal hari ${translateDay(day)} berhasil diperbarui!'),
              backgroundColor: AppTheme.success,
            ),
          );
          viewModel.fetchData(token);
        } else if (viewModel.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error!),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;

    return ChangeNotifierProvider<PiketManagementViewModel>(
      create: (context) {
        final vm = PiketManagementViewModel();
        if (token != null) {
          vm.fetchData(token);
        }
        return vm;
      },
      child: Consumer<PiketManagementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.schedules.isEmpty && viewModel.classStudents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                if (token != null) {
                  await viewModel.fetchData(token);
                }
              },
              child: viewModel.error != null
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                                const SizedBox(height: 12),
                                Text(viewModel.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    if (token != null) viewModel.fetchData(token);
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Info Card
                        Card(
                          color: AppTheme.surfaceGreen,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kelola Jadwal Piket Kelas ${viewModel.teacherClassName ?? ""}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Tugaskan satu siswa untuk setiap hari piket (Senin - Jumat). Setiap siswa hanya dapat ditugaskan pada satu hari saja.',
                                        style: TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Monday - Friday Schedule Cards
                        ...viewModel.daysOfWeek.map((day) {
                          final daySchedules = viewModel.getSchedulesForDay(day);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Day Indicator
                                  Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    child: Center(
                                      child: Text(
                                        translateDay(day),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryGreen,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Scheduled Student info
                                  Expanded(
                                    child: daySchedules.isEmpty
                                        ? const Text(
                                            'Belum ada siswa',
                                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: daySchedules.map((s) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: Text(
                                                  s['student_name']?.toString() ?? 'Siswa Tidak Diketahui',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),

                                  // Assign Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryGreen),
                                    onPressed: () => _showAssignDialog(viewModel, day),
                                    tooltip: 'Atur Siswa',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

