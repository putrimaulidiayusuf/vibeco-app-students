import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Sends the current message along with history to Gemini API.
  /// Filters history to only include text messages, formats them to alternate between 'user' and 'model',
  /// and applies strict system instructions to keep discussion on-topic (waste and cleanliness).
  Future<String> chat({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key') ?? '';
      if (apiKey.isEmpty) {
        return "API Key Gemini belum diatur 😅\n\nSilakan masukkan API Key Anda di menu profil terlebih dahulu.";
      }
      final List<Map<String, dynamic>> contents = [];

      // Limit history to the last 12 messages to keep payload small and generation fast
      final limitedHistory = history.length > 12 
          ? history.sublist(history.length - 12) 
          : history;

      // Extract and clean history (only text content, ensure user/model alternating)
      for (final msg in limitedHistory) {
        final String? text = msg['text'];
        if (text == null || text.trim().isEmpty) continue;
        
        // Skip messages that are local ONNX scanner notifications to avoid polluting context
        if (text.startsWith("Mengirim foto") || text.startsWith("Memindai sampah") || text.contains("Saya mendeteksi objek ini sebagai sampah")) {
          continue;
        }

        final bool isUser = msg['isUser'] ?? false;
        final String role = isUser ? 'user' : 'model';

        if (contents.isNotEmpty && contents.last['role'] == role) {
          // Merge text content if the same role repeats consecutively
          final lastPart = contents.last['parts'][0];
          lastPart['text'] = "${lastPart['text']}\n$text";
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text}
            ]
          });
        }
      }

      // Add the current user message if it is not already at the end of the history
      const String currentRole = 'user';
      if (contents.isNotEmpty && contents.last['role'] == currentRole) {
        final lastPart = contents.last['parts'][0];
        if (lastPart['text'] != message) {
          lastPart['text'] = "${lastPart['text']}\n$message";
        }
      } else {
        contents.add({
          'role': currentRole,
          'parts': [
            {'text': message}
          ]
        });
      }

      // Make sure first role is always 'user'
      while (contents.isNotEmpty && contents.first['role'] != 'user') {
        contents.removeAt(0);
      }

      if (contents.isEmpty) {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': message}
          ]
        });
      }

      // Define strict system instructions
      const String systemInstruction = 
          "Anda adalah PRABA AI, sebuah kecerdasan buatan (chatbot) yang khusus melayani diskusi seputar kebersihan lingkungan sekolah dan pengelolaan sampah. Wawasan Anda tentang sampah (seperti kertas, plastik, kaca, logam, organik, tekstil, B3, daur ulang, komposting, cara membuang, bank sampah, kebersihan kelas, piket, peringkat CleanRank, dll.) sangat luas.\n"
          "Anda sangat mengerti gaya bahasa manusia, termasuk bahasa gaul, singkatan (seperti mager, gmn, lu, gue, nyapu, ngepel, dll.), bahasa informal, dan salah ketik (typos).\n\n"
          "PERATURAN PENTING:\n"
          "1. Anda HANYA boleh menjawab pertanyaan atau berdiskusi tentang topik yang berkaitan dengan sampah, daur ulang, kebersihan, pemilahan limbah, kelestarian lingkungan sekolah, piket kelas, atau topik kebersihan sekolah yang relevan.\n"
          "2. Jika pengguna memasukkan prompt atau membicarakan hal yang KELUAR dari topik sampah, daur ulang, dan kebersihan (misalnya tentang coding, matematika, resep makanan umum, musik, game, curhat pribadi yang tidak relevan, dll.), Anda harus menolak dengan sopan dan ramah, lalu meminta pengguna agar HANYA menginput prompt/pertanyaan yang berkaitan dengan sampah and kebersihan.\n"
          "Contoh respon penolakan: 'Mohon maaf ya 🙏, saya PRABA AI — asisten yang khusus membantu seputar kebersihan sekolah dan pengelolaan sampah. Silakan tanyakan hal-hal yang berkaitan dengan topik tersebut! 😊'\n"
          "3. Berbicaralah dengan nada yang ramah, hangat, komunikatif, dan menggunakan bahasa Indonesia yang santai tapi tetap sopan, seolah-olah Anda sedang mengobrol dengan teman sekolah.\n"
          "4. Hindari penggunaan format markdown kompleks seperti tanda bintang ganda untuk teks tebal (**teks** atau *teks*), header (#), atau markdown list. Gunakan teks biasa yang rapi dan gunakan emoji (seperti •, 🗑️, ♻️, dll.) untuk membuat poin-poin agar mudah dibaca.";

      final Map<String, dynamic> requestBody = {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {
              'text': systemInstruction
            }
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        }
      };

      // Try gemini-3.1-flash-lite first (fastest/lowest latency)
      try {
        final reply = await _callModel('gemini-3.1-flash-lite', requestBody, apiKey);
        if (reply != null) return reply;
      } catch (e) {
        debugPrint("Failed to call gemini-3.1-flash-lite: $e. Falling back to gemini-3.5-flash...");
      }

      // Try gemini-3.5-flash next
      try {
        final reply = await _callModel('gemini-3.5-flash', requestBody, apiKey);
        if (reply != null) return reply;
      } catch (e) {
        debugPrint("Failed to call gemini-3.5-flash: $e. Falling back to gemini-2.5-pro...");
      }

      // Fallback to gemini-2.5-pro
      try {
        final reply = await _callModel('gemini-2.5-pro', requestBody, apiKey);
        if (reply != null) return reply;
      } catch (e) {
        debugPrint("Failed to call gemini-2.5-pro: $e");
        // If the last model also throws, rethrow to get a meaningful error message
        rethrow;
      }

      return "Waduh, terjadi gangguan saat menghubungi asisten AI 😅\n\nSilakan coba lagi dalam beberapa saat.";
    } catch (e) {
      debugPrint("Gemini Service Exception: $e");
      final errorStr = e.toString();
      if (errorStr.contains('API_KEY_INVALID') || errorStr.contains('API key not valid')) {
        return "API Key yang Anda masukkan tidak valid 🔑❌\n\nSilakan periksa kembali API Key di menu Profil. Pastikan API Key disalin dengan benar dari Google AI Studio.";
      } else if (errorStr.contains('QUOTA') || errorStr.contains('quota') || errorStr.contains('429')) {
        return "Kuota API Key Anda sudah habis untuk saat ini 📊\n\nSilakan tunggu beberapa menit atau buat API Key baru di Google AI Studio.";
      } else if (errorStr.contains('PERMISSION_DENIED')) {
        return "API Key tidak memiliki izin untuk menggunakan layanan ini 🔒\n\nSilakan buat API Key baru di Google AI Studio (https://aistudio.google.com/).";
      } else if (errorStr.contains('TimeoutException') || errorStr.contains('timed out')) {
        return "Koneksi ke server AI terlalu lama ⏳\n\nSilakan periksa koneksi internet Anda dan coba lagi.";
      }
      return "Waduh, terjadi gangguan teknis saat menghubungi asisten AI 😅\n\nDetail: ${_sanitizeError(errorStr)}\n\nSilakan coba lagi dalam beberapa saat.";
    }
  }

  /// Sanitize error string for user display
  String _sanitizeError(String error) {
    // Remove 'Exception: ' prefix and limit length
    String cleaned = error.replaceAll('Exception: ', '').trim();
    if (cleaned.length > 150) {
      cleaned = '${cleaned.substring(0, 150)}...';
    }
    return cleaned;
  }

  Future<String?> _callModel(String model, Map<String, dynamic> requestBody, String apiKey) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic>? candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'];
        if (parts != null && parts.isNotEmpty) {
          final String? replyText = parts[0]['text'];
          if (replyText != null && replyText.isNotEmpty) {
            return replyText.trim();
          }
        }
      }
      return null;
    } else {
      // Parse error detail from API response
      String errorDetail = '';
      try {
        final errorData = jsonDecode(response.body);
        errorDetail = errorData['error']?['message']?.toString() ?? response.body;
      } catch (_) {
        errorDetail = response.body;
      }
      debugPrint("API Error for model $model: ${response.statusCode} - $errorDetail");
      // Throw with status code and detail so the caller can give specific user feedback
      throw Exception('${response.statusCode}: $errorDetail');
    }
  }
}
