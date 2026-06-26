import 'package:flutter/foundation.dart';
import '../../core/models/submission_model.dart';
import '../../core/services/api_service.dart';

class VerificationQueueViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<PiketSubmission> _pendingSubmissions = [];
  List<PiketSubmission> get pendingSubmissions => _pendingSubmissions;

  Future<void> fetchQueue(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getPendingVerifications(token);
      _pendingSubmissions = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
