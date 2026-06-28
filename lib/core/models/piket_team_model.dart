class PiketTeamMember {
  final int id;
  final String name;
  final String? nis;

  PiketTeamMember({
    required this.id,
    required this.name,
    this.nis,
  });

  factory PiketTeamMember.fromJson(Map<String, dynamic> json) {
    return PiketTeamMember(
      id: json['id'] != null
          ? (json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0)
          : 0,
      name: json['name']?.toString() ?? '',
      nis: json['nis']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nis': nis,
    };
  }
}

class PiketTeam {
  final int id;
  final String name;
  final String? day; // 'Monday', 'Tuesday', etc.
  final int? classId;
  final String? className;
  final List<PiketTeamMember> members;
  final String? createdAt;

  PiketTeam({
    required this.id,
    required this.name,
    this.day,
    this.classId,
    this.className,
    this.members = const [],
    this.createdAt,
  });

  factory PiketTeam.fromJson(Map<String, dynamic> json) {
    List<PiketTeamMember> members = [];
    if (json['members'] != null && json['members'] is List) {
      members = (json['members'] as List)
          .map((m) => PiketTeamMember.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (json['students'] != null && json['students'] is List) {
      members = (json['students'] as List)
          .map((m) => PiketTeamMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return PiketTeam(
      id: json['id'] != null
          ? (json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0)
          : 0,
      name: json['name']?.toString() ?? 'Regu Piket',
      day: json['day']?.toString() ?? json['day_of_week']?.toString(),
      classId: json['class_id'] != null
          ? (json['class_id'] is int
              ? json['class_id']
              : int.tryParse(json['class_id'].toString()))
          : null,
      className: json['class_name']?.toString(),
      members: members,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'day': day,
      'class_id': classId,
      'class_name': className,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}

class StudentAttendance {
  final int studentId;
  final String name;
  String status; // 'piket', 'kabur', 'tidak sekolah'
  String? reason;

  StudentAttendance({
    required this.studentId,
    required this.name,
    this.status = 'piket',
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'status': status,
      'reason': reason,
    };
  }
}
