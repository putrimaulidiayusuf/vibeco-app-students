import 'package:flutter/foundation.dart';
import '../../core/models/submission_model.dart';
import '../../core/models/monthly_class_score_model.dart';
import '../../core/services/api_service.dart';

class CleanTrackViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PiketSubmission> _submissions = [];
  List<PiketSubmission> get submissions => _submissions;

  List<MonthlyClassScore> _monthlyScores = [];
  List<MonthlyClassScore> get monthlyScores => _monthlyScores;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoadingMonthly = true;
  bool get isLoadingMonthly => _isLoadingMonthly;

  String? _error;
  String? get error => _error;

  String? _errorMonthly;
  String? get errorMonthly => _errorMonthly;

  Future<void> fetchHistory(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getSubmissions(token);
      _submissions = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyScores(String token) async {
    _isLoadingMonthly = true;
    _errorMonthly = null;
    notifyListeners();

    try {
      final data = await _apiService.getMonthlyClassScores(token);
      _monthlyScores = data;
    } catch (e) {
      _errorMonthly = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMonthly = false;
      notifyListeners();
    }
  }
}
