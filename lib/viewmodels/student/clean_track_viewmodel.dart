import 'package:flutter/foundation.dart';
import '../../core/models/submission_model.dart';
import '../../core/services/api_service.dart';

class CleanTrackViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PiketSubmission> _submissions = [];
  List<PiketSubmission> get submissions => _submissions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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
}
