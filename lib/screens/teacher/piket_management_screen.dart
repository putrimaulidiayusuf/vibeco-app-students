import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/app_config.dart';

class PiketManagementScreen extends StatefulWidget {
  const PiketManagementScreen({super.key});

  @override
  State<PiketManagementScreen> createState() => _PiketManagementScreenState();
}

class _PiketManagementScreenState extends State<PiketManagementScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  // Schedule & Class Info
  List<Map<String, dynamic>> _schedules = [];
  List<dynamic> _classStudents = [];
  int? _teacherClassId;
  String? _teacherClassName;

  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      // 1. Fetch class monitor data (to get class name, class id, and student list)
      final monitorData = await _apiService.getClassMonitor(token);
      _teacherClassName = monitorData['class_name']?.toString();
      _teacherClassId = monitorData['class_id'] != null
          ? (monitorData['class_id'] is int
              ? monitorData['class_id']
              : int.tryParse(monitorData['class_id'].toString()))
          : null;
      _classStudents = monitorData['students'] ?? [];

      // 2. Fetch schedules directly from API to get raw JSON structure
      final rawResponse = await http.get(
        Uri.parse(AppConfig.buildUrl('/schedule')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (rawResponse.statusCode == 200) {
        final List<dynamic> allClassSchedules = jsonDecode(rawResponse.body);
        // Find teacher's class schedule
        final myClassSched = allClassSchedules.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['class_id'] == _teacherClassId,
          orElse: () => null,
        );

        if (myClassSched != null) {
          final List<dynamic> teams = myClassSched['teams'] ?? [];
          setState(() {
            _schedules = teams.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _schedules = [];
          });
        }
      } else {
        throw Exception('Gagal mengambil jadwal piket.');
      }

    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSchedulesForDay(String day) {
    return _schedules.where((s) => s['day_of_week']?.toString().toLowerCase() == day.toLowerCase()).toList();
  }

  Future<void> _showAssignDialog(String day) async {
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
                    _classStudents.isEmpty
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
                            items: _classStudents.map<DropdownMenuItem<int>>((student) {
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
                            // Use initialValue-safe pattern
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

    if (confirm == true && selectedStudentId != null && _teacherClassId != null && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final token = auth.token;
        if (token == null) return;

        await _apiService.updateStudentSchedule(
          token,
          schoolClassId: _teacherClassId!,
          studentId: selectedStudentId!,
          dayOfWeek: day,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jadwal hari ${translateDay(day)} berhasil diperbarui!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
        _fetchData();
      } catch (e) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

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
      default:
        return engDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _schedules.isEmpty && _classStudents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _error != null
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
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
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
                                  'Kelola Jadwal Piket Kelas $_teacherClassName',
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
                  ..._daysOfWeek.map((day) {
                    final daySchedules = _getSchedulesForDay(day);

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
                              onPressed: () => _showAssignDialog(day),
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
  }
}
