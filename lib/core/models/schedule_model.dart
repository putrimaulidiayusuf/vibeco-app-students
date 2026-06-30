/// Model for individual schedule entries from the /api/schedule and /api/schedule/my-team APIs.
class ScheduleEntry {
  final int id;
  final String dayOfWeek;
  final int studentId;
  final String studentName;
  final String studentNis;

  ScheduleEntry({
    required this.id,
    required this.dayOfWeek,
    required this.studentId,
    required this.studentName,
    required this.studentNis,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      studentId: json['student_id'] is int
          ? json['student_id']
          : int.tryParse(json['student_id']?.toString() ?? '0') ?? 0,
      studentName: json['student_name']?.toString() ?? '',
      studentNis: json['student_nis']?.toString() ?? '',
    );
  }
}

/// Model for the class schedule from /api/schedule/my-team.
class ClassSchedule {
  final int classId;
  final String className;
  final List<ScheduleEntry> teams;

  ClassSchedule({
    required this.classId,
    required this.className,
    required this.teams,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'] as List<dynamic>? ?? [];
    final teams = rawTeams
        .map((t) => ScheduleEntry.fromJson(t as Map<String, dynamic>))
        .toList();

    return ClassSchedule(
      classId: json['class_id'] is int
          ? json['class_id']
          : int.tryParse(json['class_id']?.toString() ?? '0') ?? 0,
      className: json['class_name']?.toString() ?? '',
      teams: teams,
    );
  }

  /// Group schedule entries by day of week.
  Map<String, List<ScheduleEntry>> get groupedByDay {
    final map = <String, List<ScheduleEntry>>{};
    for (final entry in teams) {
      map.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
    }
    return map;
  }

  /// Get entries for a specific day.
  List<ScheduleEntry> entriesForDay(String dayOfWeek) {
    return teams.where((e) => e.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase()).toList();
  }
}

/// Model for today's duty response from /api/piket/today-duty.
class TodayDuty {
  final String dayOfWeek;
  final List<DutyStudent> students;

  TodayDuty({
    required this.dayOfWeek,
    required this.students,
  });

  factory TodayDuty.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['students'] as List<dynamic>? ?? [];
    final students = rawStudents
        .map((s) => DutyStudent.fromJson(s as Map<String, dynamic>))
        .toList();

    return TodayDuty(
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      students: students,
    );
  }
}

/// Model for a student on duty today.
class DutyStudent {
  final int id;
  final String nis;
  final String name;

  DutyStudent({
    required this.id,
    required this.nis,
    required this.name,
  });

  factory DutyStudent.fromJson(Map<String, dynamic> json) {
    return DutyStudent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nis: json['nis']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
