import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/models/schedule_model.dart';
import '../../core/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoadingSchedule = false;
  bool get isLoadingSchedule => _isLoadingSchedule;

  String? _scheduleError;
  String? get scheduleError => _scheduleError;

  ClassSchedule? _myClassSchedule;
  ClassSchedule? get myClassSchedule => _myClassSchedule;

  TodayDuty? _todayDuty;
  TodayDuty? get todayDuty => _todayDuty;

  /// The current day name in English (e.g. "Monday").
  String get todayEnglish => DateFormat('EEEE').format(DateTime.now());

  /// The current day name in Indonesian.
  String get todayIndonesian => _translateDay(todayEnglish);

  /// Ordered days of the week for display.
  static const List<String> orderedDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  /// Load both my-team schedule and today's duty.
  Future<void> loadScheduleData(String token) async {
    _isLoadingSchedule = true;
    _scheduleError = null;
    notifyListeners();

    try {
      // Load both in parallel
      final results = await Future.wait([
        _apiService.getMyClassSchedule(token),
        _apiService.getTodayDuty(token),
      ]);

      _myClassSchedule = results[0] as ClassSchedule?;
      _todayDuty = results[1] as TodayDuty?;
    } catch (e) {
      _scheduleError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingSchedule = false;
      notifyListeners();
    }
  }

  /// Get entries for a specific day from my class schedule.
  List<ScheduleEntry> getEntriesForDay(String dayOfWeek) {
    if (_myClassSchedule == null) return [];
    return _myClassSchedule!.entriesForDay(dayOfWeek);
  }

  /// Get the days that actually have schedule entries.
  List<String> get activeDays {
    if (_myClassSchedule == null) return [];
    final grouped = _myClassSchedule!.groupedByDay;
    return orderedDays.where((day) => grouped.containsKey(day)).toList();
  }

  /// Check if a student is on duty today.
  bool isStudentOnDutyToday(String nis) {
    if (_todayDuty == null) return false;
    return _todayDuty!.students.any((s) => s.nis == nis);
  }

  /// Translate English day name to Indonesian.
  String _translateDay(String englishDay) {
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

  /// Public helper for views to translate day names.
  String translateDay(String englishDay) => _translateDay(englishDay);

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
