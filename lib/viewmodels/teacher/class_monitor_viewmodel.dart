import 'package:flutter/foundation.dart';
import '../../core/models/submission_model.dart';
import '../../core/services/api_service.dart';

class ClassMonitorViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _className;
  String? get className => _className;

  int _totalSubmissions = 0;
  int get totalSubmissions => _totalSubmissions;

  int _averageScore = 0;
  int get averageScore => _averageScore;

  List<PiketSubmission> _classSubmissions = [];
  List<PiketSubmission> get classSubmissions => _classSubmissions;

  Future<void> fetchMonitorData(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getClassMonitor(token);
      
      _className = data['class_name']?.toString() ?? 'Kelas';
      final summary = data['performance_summary'];
      if (summary != null) {
        _totalSubmissions = summary['total_submissions'] is int 
            ? summary['total_submissions'] 
            : int.tryParse(summary['total_submissions'].toString()) ?? 0;
        _averageScore = summary['average_score'] is int 
            ? summary['average_score'] 
            : (summary['average_score'] as num?)?.toInt() ?? 0;
      }

      final rawSubs = data['submissions'] as List<dynamic>?;
      if (rawSubs != null) {
        _classSubmissions = rawSubs
            .map((item) => PiketSubmission.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _classSubmissions = [];
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
