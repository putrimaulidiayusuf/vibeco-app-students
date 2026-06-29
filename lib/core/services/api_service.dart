import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/submission_model.dart';
import '../models/ranking_model.dart';
import '../models/piket_team_model.dart';
import '../models/settings_model.dart';
import 'service_locator.dart';

class ApiService {
  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Authenticate user and return token & user details.
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    // Determine the key based on the identifier format:
    String key;
    if (identifier.contains('@')) {
      key = 'email';
    } else if (identifier.toUpperCase().startsWith('T') || RegExp(r'^[a-zA-Z]').hasMatch(identifier)) {
      key = 'nip';
    } else {
      key = 'nis';
    }

    final endpoint = (key == 'nis') ? '/student/login' : '/teacher/login';
    final url = AppConfig.buildUrl(endpoint);

    final response = await locator.httpService.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({
        key: identifier,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return {
        'token': token,
        'user': user,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal masuk. Silakan coba lagi.');
    }
  }

  /// Logout current user session.
  Future<void> logout(String token) async {
    final url = AppConfig.buildUrl('/logout');
    final response = await locator.httpService.post(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal keluar.');
    }
  }

  /// Get current user profile details.
  Future<User> getMe(String token) async {
    final url = AppConfig.buildUrl('/me');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Gagal mengambil profil.');
    }
  }

  /// Submit class cleanliness photos (Multipart).
  Future<Map<String, dynamic>> submitPhotos(
    String token,
    List<String> imagePaths,
    double latitude,
    double longitude, {
    List<StudentAttendance>? attendance,
  }) async {
    final url = Uri.parse(AppConfig.buildUrl('/piket/submissions'));
    final request = http.MultipartRequest('POST', url);

    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final isoStr = now.toIso8601String();

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Timezone': 'Asia/Jakarta',
      'X-Client-Time': isoStr,
    });

    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['submitted_at'] = isoStr;
    request.fields['client_time'] = timeStr;
    request.fields['time'] = timeStr;
    request.fields['timezone'] = 'Asia/Jakarta';

    if (attendance != null && attendance.isNotEmpty) {
      // 1. JSON String format
      final List<Map<String, dynamic>> attJson = attendance.map((a) => a.toJson()).toList();
      request.fields['attendance'] = jsonEncode(attJson);
      request.fields['attendance_json'] = jsonEncode(attJson);

      // 2. Bracket notation format (Laravel standard)
      for (int i = 0; i < attendance.length; i++) {
        final item = attendance[i];
        request.fields['attendance[$i][student_id]'] = item.studentId.toString();
        request.fields['attendance[$i][status]'] = item.status;
        request.fields['attendance[$i][reason]'] = item.reason ?? '';

        // 3. Parallel fields format
        request.fields['student_ids[$i]'] = item.studentId.toString();
        request.fields['statuses[$i]'] = item.status;
        request.fields['reasons[$i]'] = item.reason ?? '';
      }
    }

    for (int i = 0; i < imagePaths.length; i++) {
      final file = await http.MultipartFile.fromPath('photos[]', imagePaths[i]);
      request.files.add(file);
    }

    final streamedResponse = await locator.httpService.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal mengirim foto piket.');
    }
  }

  /// Get submission history for students/classes.
  Future<List<PiketSubmission>> getSubmissions(String token) async {
    final url = AppConfig.buildUrl('/piket/submissions');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => PiketSubmission.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Gagal mengambil riwayat piket.');
    }
  }

  /// Get specific submission details.
  Future<PiketSubmission> getSubmissionById(String token, int id) async {
    final url = AppConfig.buildUrl('/piket/submissions/$id');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return PiketSubmission.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Gagal mengambil detail piket.');
    }
  }

  /// Get clean rankings (daily, weekly, monthly).
  Future<List<ClassRanking>> getRankings(String token, String interval) async {
    final url = AppConfig.buildUrl('/rankings/$interval');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .asMap()
          .map((index, item) => MapEntry(
                index,
                ClassRanking.fromJson(item as Map<String, dynamic>, index: index),
              ))
          .values
          .toList();
    } else {
      throw Exception('Gagal mengambil peringkat.');
    }
  }

  /// Get classroom piket schedules.
  Future<List<PiketTeam>> getSchedules(String token) async {
    final url = AppConfig.buildUrl('/schedule');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => PiketTeam.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Gagal mengambil jadwal piket.');
    }
  }

  /// Update piket schedule day for a student.
  Future<void> updateStudentSchedule(
    String token, {
    required int schoolClassId,
    required int studentId,
    required String dayOfWeek,
  }) async {
    final url = AppConfig.buildUrl('/piket/schedule');
    final response = await locator.httpService.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'school_class_id': schoolClassId,
        'student_id': studentId,
        'day_of_week': dayOfWeek,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal memperbarui jadwal piket.');
    }
  }

  /// Get today's piket team for the logged-in student.
  Future<PiketTeam?> getMyTeam(String token) async {
    final url = AppConfig.buildUrl('/schedule/my-team');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null || (data is Map && data.isEmpty)) return null;
      return PiketTeam.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Gagal mengambil tim piket Anda.');
    }
  }

  /// Get today's scheduled picket verification details (student).
  Future<PiketTeam> verifyPiketToday(String token) async {
    final url = AppConfig.buildUrl('/piket/today-duty');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PiketTeam.fromJson(data);
    } else {
      throw Exception('Gagal memverifikasi jadwal piket hari ini.');
    }
  }

  /// Get current student profile details.
  Future<User> getStudentProfile(String token) async {
    final url = AppConfig.buildUrl('/student/profile');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson({
        ...json,
        'role': 'student',
      });
    } else {
      throw Exception('Gagal mengambil profil siswa.');
    }
  }

  /// Get app settings (upload time, geofence, etc.).
  Future<AppSettings> getSettings(String token) async {
    final url = AppConfig.buildUrl('/settings');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Map the key/value list from Laravel index endpoint
      // Laravel returns pluck('value', 'key'), which is {"school_latitude": "-6.200000", ...}
      return AppSettings(
        latitude: double.tryParse(data['school_latitude']?.toString() ?? data['latitude']?.toString() ?? '0') ?? 0.0,
        longitude: double.tryParse(data['school_longitude']?.toString() ?? data['longitude']?.toString() ?? '0') ?? 0.0,
        radius: double.tryParse(data['school_radius']?.toString() ?? data['radius']?.toString() ?? '100') ?? 100.0,
        startTime: data['upload_start_time']?.toString() ?? data['start_time']?.toString() ?? data['piket_start_time']?.toString() ?? '08:00',
        endTime: data['upload_end_time']?.toString() ?? data['end_time']?.toString() ?? data['piket_end_time']?.toString() ?? '17:00',
      );
    } else {
      throw Exception('Gagal mengambil konfigurasi aplikasi.');
    }
  }

  /// Get registered holidays.
  Future<List<Map<String, dynamic>>> getHolidays(String token) async {
    final url = AppConfig.buildUrl('/settings/holidays');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception('Gagal mengambil hari libur.');
    }
  }

  /// PLH Teacher: Get submissions waiting for verification.
  Future<List<PiketSubmission>> getPendingVerifications(String token) async {
    final url = AppConfig.buildUrl('/piket/verification-queue');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => PiketSubmission.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Gagal mengambil antrean verifikasi.');
    }
  }

  /// PLH Teacher: Verify a submission.
  Future<void> verifySubmission(
    String token,
    int submissionId,
    String status, {
    int? score,
    String? notes,
  }) async {
    final url = AppConfig.buildUrl('/piket/verify');
    final response = await locator.httpService.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'submission_id': submissionId,
        'status': status,
        'score': score,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal memverifikasi piket.');
    }
  }

  /// Homeroom Teacher: Get class monitor performance breakdown.
  Future<Map<String, dynamic>> getClassMonitor(String token) async {
    final url = AppConfig.buildUrl('/class/monitor');
    final response = await locator.httpService.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Gagal memantau kebersihan kelas.');
    }
  }
}
