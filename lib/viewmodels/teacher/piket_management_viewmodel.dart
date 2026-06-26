import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';

class PiketManagementViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> get schedules => _schedules;

  List<dynamic> _classStudents = [];
  List<dynamic> get classStudents => _classStudents;

  int? _teacherClassId;
  int? get teacherClassId => _teacherClassId;

  String? _teacherClassName;
  String? get teacherClassName => _teacherClassName;

  final List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  List<Map<String, dynamic>> getSchedulesForDay(String day) {
    return _schedules.where((s) => s['day_of_week']?.toString().toLowerCase() == day.toLowerCase()).toList();
  }

  Future<void> fetchData(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
        final myClassSched = allClassSchedules.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['class_id'] == _teacherClassId,
          orElse: () => null,
        );

        if (myClassSched != null) {
          final List<dynamic> teams = myClassSched['teams'] ?? [];
          _schedules = teams.cast<Map<String, dynamic>>();
        } else {
          _schedules = [];
        }
      } else {
        throw Exception('Gagal mengambil jadwal piket.');
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudentSchedule({
    required String token,
    required int schoolClassId,
    required int studentId,
    required String dayOfWeek,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateStudentSchedule(
        token,
        schoolClassId: schoolClassId,
        studentId: studentId,
        dayOfWeek: dayOfWeek,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
