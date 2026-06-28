class User {
  final int id;
  final String name;
  final String role; // 'student' or 'teacher'
  final String? roleType; // for teacher: 'regular', 'homeroom', 'plh'
  final String? nis; // student identifier
  final String? nip; // teacher identifier
  final String? className; // student's class
  final int? classId;
  final String? email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.roleType,
    this.nis,
    this.nip,
    this.className,
    this.classId,
    this.email,
    this.avatar,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isHomeroom => roleType == 'homeroom';
  bool get isPLH => roleType == 'plh';
  bool get isRegular => roleType == 'regular' || roleType == null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null
          ? (json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0)
          : 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      roleType: json['role_type']?.toString(),
      nis: json['nis']?.toString(),
      nip: json['nip']?.toString(),
      className: json['school_class_name']?.toString() ??
          json['class_name']?.toString() ??
          json['class']?.toString(),
      classId: json['school_class_id'] != null
          ? (json['school_class_id'] is int
              ? json['school_class_id']
              : int.tryParse(json['school_class_id'].toString()))
          : json['class_id'] != null
              ? (json['class_id'] is int
                  ? json['class_id']
                  : int.tryParse(json['class_id'].toString()))
              : null,
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'role_type': roleType,
      'nis': nis,
      'nip': nip,
      'class_name': className,
      'class_id': classId,
      'email': email,
      'avatar': avatar,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, role: $role, roleType: $roleType)';
}
