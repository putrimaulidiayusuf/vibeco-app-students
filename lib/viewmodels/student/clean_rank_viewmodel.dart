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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchAllData(String token, {int? schoolClassId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getCleanestDay(token, schoolClassId: schoolClassId),
        _apiService.getRankings(token, 'daily'),
        _apiService.getRankings(token, 'weekly'),
        _apiService.getRankings(token, 'monthly'),
      ]);

      final rawClassRankings = results[0] as List<PiketDayRanking>;
      rawClassRankings.sort((a, b) => b.averageScore.compareTo(a.averageScore));
      _classRankings = List.generate(rawClassRankings.length, (index) {
        final original = rawClassRankings[index];
        return PiketDayRanking(
          rank: index + 1,
          dayOfWeek: original.dayOfWeek,
          dayNameId: original.dayNameId,
          averageScore: original.averageScore,
          maxScore: original.maxScore,
          piketCount: original.piketCount,
        );
      });

      _dailyRankings = results[1] as List<ClassRanking>;
      _weeklyRankings = results[2] as List<ClassRanking>;
      _monthlyRankings = results[3] as List<ClassRanking>;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchClassRankings(String token, {int? schoolClassId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawClassRankings = await _apiService.getCleanestDay(token, schoolClassId: schoolClassId);
      rawClassRankings.sort((a, b) => b.averageScore.compareTo(a.averageScore));
      _classRankings = List.generate(rawClassRankings.length, (index) {
        final original = rawClassRankings[index];
        return PiketDayRanking(
          rank: index + 1,
          dayOfWeek: original.dayOfWeek,
          dayNameId: original.dayNameId,
          averageScore: original.averageScore,
          maxScore: original.maxScore,
          piketCount: original.piketCount,
        );
      });
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
