import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
    required AuthService authService,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(
        identifier.trim(),
        password,
      );

      final String token = result['token'];
      final User user = result['user'];

      await authService.saveSession(token, user);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceAll('Exception: ', '').toLowerCase();
    if (msg.contains('invalid') ||
        msg.contains('credentials') ||
        msg.contains('unauthorized') ||
        msg.contains('401') ||
        msg.contains('password') ||
        msg.contains('wrong') ||
        msg.contains('incorrect')) {
      return 'NIS atau kata sandi salah. Silakan periksa kembali.';
    } else if (msg.contains('not found') ||
        msg.contains('404') ||
        msg.contains('no user') ||
        msg.contains('nis')) {
      return 'NIS tidak ditemukan. Pastikan NIS sudah benar.';
    } else if (msg.contains('too many') ||
        msg.contains('429') ||
        msg.contains('throttle')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    } else if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('timed out')) {
      return 'Koneksi gagal. Periksa jaringan internet kamu.';
    } else if (msg.contains('server') || msg.contains('500')) {
      return 'Server sedang bermasalah. Coba beberapa saat lagi.';
    }
    return 'Login gagal. Pastikan NIS dan kata sandi benar.';
  }
}
