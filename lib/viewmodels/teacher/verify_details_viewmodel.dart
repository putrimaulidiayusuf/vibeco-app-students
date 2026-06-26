import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';

class VerifyDetailsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  String _selectedAction = 'approved'; // 'approved', 'rejected', 'adjusted'
  String get selectedAction => _selectedAction;

  void setSelectedAction(String action) {
    _selectedAction = action;
    notifyListeners();
  }

  Future<bool> verifySubmission({
    required String token,
    required int submissionId,
    required String status,
    int? score,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.verifySubmission(
        token,
        submissionId,
        status,
        score: score,
        notes: notes,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
