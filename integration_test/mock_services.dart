import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vibeco_app/core/services/http_service.dart';
import 'package:vibeco_app/core/services/location_service.dart';

class MockLocationService implements LocationService {
  double latitude = -6.200000;
  double longitude = 106.816666;

  void setCoordinates(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }

  @override
  Future<Position?> getCurrentPosition() async {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }

  @override
  double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    const double r = 6371000.0; // Earth radius in meters
    final double lat1 = startLatitude * math.pi / 180.0;
    final double lat2 = endLatitude * math.pi / 180.0;
    final double dLat = (endLatitude - startLatitude) * math.pi / 180.0;
    final double dLng = (endLongitude - startLongitude) * math.pi / 180.0;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}

class MockHttpService implements HttpService {
  final Map<String, dynamic> settings = {
    'latitude': -6.200000,
    'longitude': 106.816666,
    'radius': 50.0,
    'start_time': '06:00',
    'end_time': '08:00',
  };

  final List<String> holidays = ['2026-06-29'];
  final List<Map<String, dynamic>> submissions = [];
  final List<Map<String, dynamic>> teams = [];
  final List<Map<String, dynamic>> schedules = [];

  final List<Map<String, dynamic>> rankings = [
    {'class_name': '10-A', 'score': 0.0},
    {'class_name': '11-A', 'score': 80.0},
    {'class_name': '12-A', 'score': 75.0},
  ];

  String? token;
  Map<String, dynamic>? currentUser;

  @override
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    final path = uri.path;

    if (path == '/api/settings') {
      return http.Response(jsonEncode(settings), 200);
    } else if (path == '/api/settings/holidays') {
      return http.Response(jsonEncode(holidays), 200);
    } else if (path == '/api/piket/submissions') {
      return http.Response(jsonEncode(submissions), 200);
    } else if (path == '/api/piket/verifications/pending') {
      final pending = submissions.where((s) => s['status'] == 'pending').toList();
      return http.Response(jsonEncode(pending), 200);
    } else if (path.startsWith('/api/rankings/')) {
      rankings.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));
      return http.Response(jsonEncode(rankings), 200);
    } else if (path == '/api/piket/schedule') {
      return http.Response(jsonEncode(schedules), 200);
    } else if (path == '/api/me') {
      if (currentUser != null) {
        return http.Response(jsonEncode(currentUser), 200);
      }
      return http.Response(jsonEncode({'message': 'Unauthenticated'}), 401);
    }

    return http.Response(jsonEncode({'message': 'Not Found'}), 404);
  }

  @override
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body}) async {
    final uri = Uri.parse(url);
    final path = uri.path;
    final Map<String, dynamic> data = body is String 
        ? jsonDecode(body) 
        : (body as Map<String, dynamic>? ?? {});

    if (path == '/api/login') {
      final nis = data['nis'];
      final nip = data['nip'];
      final pass = data['password'];

      if (nis == '12345' && pass == 'password') {
        currentUser = {'id': 1, 'name': 'Student Ten', 'role': 'student', 'class': '10-A', 'nis': '12345'};
      } else if (nis == '54321' && pass == 'password') {
        currentUser = {'id': 2, 'name': 'Student Y', 'role': 'student', 'class': '10-A', 'nis': '54321'};
      } else if (nip == '11111' && pass == 'password') {
        currentUser = {'id': 3, 'name': 'Homeroom Guru', 'role': 'teacher', 'role_type': 'homeroom', 'class': '10-A', 'nip': '11111'};
      } else if (nip == '22222' && pass == 'password') {
        currentUser = {'id': 4, 'name': 'Teacher B', 'role': 'teacher', 'role_type': 'homeroom', 'class': '11-A', 'nip': '22222'};
      } else if (nip == '33333' && pass == 'password') {
        currentUser = {'id': 5, 'name': 'PLH Guru', 'role': 'teacher', 'role_type': 'plh', 'nip': '33333'};
      } else if (nip == '44444' && pass == 'password') {
        currentUser = {'id': 6, 'name': 'Regular Guru', 'role': 'teacher', 'role_type': 'regular', 'nip': '44444'};
      } else {
        return http.Response(jsonEncode({'message': 'Invalid credentials'}), 401);
      }
      token = 'mock_token_${currentUser!['id']}';
      return http.Response(jsonEncode({'token': token, 'user': currentUser}), 200);
    } else if (path == '/api/logout') {
      token = null;
      currentUser = null;
      return http.Response(jsonEncode({'message': 'Logged out'}), 200);
    } else if (path == '/api/piket/submissions') {
      final double? lat = data['latitude'] as double?;
      final double? lng = data['longitude'] as double?;
      final int photoCount = data['photo_count'] as int? ?? 3;

      if (lat == null || lng == null) {
        return http.Response(jsonEncode({'message': 'Coordinates required'}), 422);
      }
      if (photoCount < 3) {
        return http.Response(jsonEncode({'message': 'minimum 3 photos required'}), 422);
      }
      if (photoCount > 5) {
        return http.Response(jsonEncode({'message': 'maximum 5 photos allowed'}), 422);
      }

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final hasDuplicate = submissions.any((s) => s['date'] == todayStr && s['class_name'] == currentUser?['class']);
      if (hasDuplicate) {
        return http.Response(jsonEncode({'message': 'class has already submitted today'}), 400);
      }

      final submission = {
        'id': submissions.length + 1,
        'class_name': currentUser?['class'] ?? '10-A',
        'date': todayStr,
        'ai_score': 85,
        'findings': ['lantai kotor'],
        'status': 'pending',
        'notes': '',
        'final_score': null,
      };
      submissions.add(submission);
      return http.Response(jsonEncode(submission), 201);
    } else if (path == '/api/piket/verify') {
      final subId = data['submission_id'] as int?;
      final status = data['status'];
      final score = data['score'] as int?;
      final notes = data['notes'] as String?;

      if (subId == null || status == null) {
        return http.Response(jsonEncode({'message': 'Missing parameters'}), 422);
      }

      final index = submissions.indexWhere((s) => s['id'] == subId);
      if (index == -1) {
        return http.Response(jsonEncode({'message': 'Submission not found'}), 404);
      }

      if (score != null && (score < 0 || score > 100)) {
        return http.Response(jsonEncode({'message': 'score override must be between 0 and 100'}), 422);
      }

      if (notes != null && notes.length > 1000) {
        return http.Response(jsonEncode({'message': 'notes field too long'}), 422);
      }

      final submission = submissions[index];
      if (submission['status'] == 'approved' || submission['status'] == 'adjusted' || submission['status'] == 'rejected') {
        return http.Response(jsonEncode({'message': 'submission is already completed'}), 400);
      }

      submission['status'] = status;
      submission['notes'] = notes ?? '';
      submission['final_score'] = status == 'approved' 
          ? submission['ai_score'] 
          : (status == 'rejected' ? 0 : score);

      final double finalScoreVal = (submission['final_score'] as num).toDouble();
      final rIdx = rankings.indexWhere((r) => r['class_name'] == submission['class_name']);
      if (rIdx != -1) {
        rankings[rIdx]['score'] = finalScoreVal;
      }

      return http.Response(jsonEncode(submission), 200);
    } else if (path == '/api/piket/teams') {
      final team = {
        'id': teams.length + 1,
        'name': data['name'],
        'class_name': currentUser?['class'] ?? '10-A',
        'students': data['students'] ?? [],
      };
      teams.add(team);
      return http.Response(jsonEncode(team), 201);
    } else if (path == '/api/piket/schedule') {
      final schedule = {
        'id': schedules.length + 1,
        'team_id': data['team_id'],
        'day': data['day'],
      };
      schedules.add(schedule);
      return http.Response(jsonEncode(schedule), 200);
    } else if (path == '/api/settings/geofence') {
      settings['latitude'] = data['latitude'];
      settings['longitude'] = data['longitude'];
      settings['radius'] = data['radius'];
      return http.Response(jsonEncode(settings), 200);
    } else if (path == '/api/settings/time-window') {
      settings['start_time'] = data['start_time'];
      settings['end_time'] = data['end_time'];
      return http.Response(jsonEncode(settings), 200);
    } else if (path == '/api/settings/holidays') {
      holidays.add(data['date'] as String);
      return http.Response(jsonEncode({'message': 'Holiday registered'}), 201);
    }

    return http.Response(jsonEncode({'message': 'Not Found'}), 404);
  }

  @override
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body}) async {
    final uri = Uri.parse(url);
    final path = uri.path;
    final Map<String, dynamic> data = body is String ? jsonDecode(body) : (body as Map<String, dynamic>? ?? {});

    if (path.startsWith('/api/piket/schedule/')) {
      final id = int.tryParse(path.split('/').last);
      final idx = schedules.indexWhere((s) => s['id'] == id);
      if (idx != -1) {
        schedules[idx]['day'] = data['day'];
        return http.Response(jsonEncode(schedules[idx]), 200);
      }
      return http.Response(jsonEncode({'message': 'Schedule not found'}), 404);
    }
    return http.Response(jsonEncode({'message': 'Not Found'}), 404);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.MultipartRequest) {
      final String path = request.url.path;
      if (path == '/api/piket/submissions') {
        final double? lat = double.tryParse(request.fields['latitude'] ?? '');
        final double? lng = double.tryParse(request.fields['longitude'] ?? '');
        final int photoCount = request.files.length;
        
        final response = await post(
          request.url.toString(),
          body: {
            'latitude': lat,
            'longitude': lng,
            'photo_count': photoCount,
          },
        );

        final stream = Stream.value(response.bodyBytes);
        return http.StreamedResponse(stream, response.statusCode);
      }
    }
    return http.StreamedResponse(Stream.empty(), 404);
  }
}
