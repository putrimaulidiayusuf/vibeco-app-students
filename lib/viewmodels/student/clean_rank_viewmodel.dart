import 'package:flutter/foundation.dart';
import '../../core/models/ranking_model.dart';
import '../../core/services/api_service.dart';

class CleanRankViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ClassRanking> _dailyRankings = [];
  List<ClassRanking> get dailyRankings => _dailyRankings;

  List<ClassRanking> _weeklyRankings = [];
  List<ClassRanking> get weeklyRankings => _weeklyRankings;

  List<ClassRanking> _monthlyRankings = [];
  List<ClassRanking> get monthlyRankings => _monthlyRankings;

  List<PiketDayRanking> _classRankings = [];
  List<PiketDayRanking> get classRankings => _classRankings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchClassRankings(String token, {int? schoolClassId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _classRankings = await _apiService.getCleanestDay(token, schoolClassId: schoolClassId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRankings(String token, String interval) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getRankings(token, interval);
      if (interval == 'daily') {
        _dailyRankings = data;
      } else if (interval == 'weekly') {
        _weeklyRankings = data;
      } else {
        _monthlyRankings = data;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
