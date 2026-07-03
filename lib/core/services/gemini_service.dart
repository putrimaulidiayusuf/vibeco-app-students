import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Sends the current message along with history to Gemini API.
  /// Filters history to only include text messages, formats them to alternate between 'user' and 'model',
  /// and applies strict system instructions to keep discussion on-topic (waste and cleanliness).
  Future<String> chat({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    try {
      final List<Map<String, dynamic>> contents = [];

      // Extract and clean history (only text content, ensure user/model alternating)
      for (final msg in history) {
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
          "2. Jika pengguna memasukkan prompt atau membicarakan hal yang KELUAR dari topik sampah, daur ulang, dan kebersihan (misalnya tentang coding, matematika, resep makanan umum, musik, game, curhat pribadi yang tidak relevan, dll.), Anda harus menolak dengan sopan dan ramah, lalu meminta pengguna agar HANYA menginput prompt/pertanyaan yang berkaitan dengan sampah dan kebersihan.\n"
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
        }
      };

      // Try gemini-2.5-flash first
      try {
        final reply = await _callModel('gemini-2.5-flash', requestBody);
        if (reply != null) return reply;
      } catch (e) {
        debugPrint("Failed to call gemini-2.5-flash: $e. Falling back to gemini-1.5-flash...");
      }

      // Fallback to gemini-1.5-flash
      try {
        final reply = await _callModel('gemini-1.5-flash', requestBody);
        if (reply != null) return reply;
      } catch (e) {
        debugPrint("Failed to call gemini-1.5-flash: $e");
      }

      return "Waduh, terjadi gangguan saat menghubungi asisten AI 😅\n\nSilakan coba lagi dalam beberapa saat.";
    } catch (e) {
      debugPrint("Gemini Service Exception: $e");
      return "Waduh, terjadi gangguan teknis saat menghubungi asisten AI 😅\n\nSilakan coba lagi dalam beberapa saat.";
    }
  }

  Future<String?> _callModel(String model, Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 25));

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
      debugPrint("API Error for model $model: ${response.statusCode} - ${response.body}");
      return null;
    }
  }
}
