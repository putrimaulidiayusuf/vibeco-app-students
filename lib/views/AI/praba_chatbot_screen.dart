import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/onnx_predictor.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';
import 'camera_scanner_screen.dart';

class PrabaChatBotScreen extends StatefulWidget {
  const PrabaChatBotScreen({super.key});

  @override
  State<PrabaChatBotScreen> createState() => _PrabaChatBotScreenState();
}

class _PrabaChatBotScreenState extends State<PrabaChatBotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  bool _isAiResponding = false;

  @override
  void initState() {
    super.initState();
    // Tunggu frame pertama agar context tersedia untuk Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  /// Key unik per akun berdasarkan user ID
  String _chatKey() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.user?.id.toString() ?? 'guest';
    return 'praba_chat_history_$userId';
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString(_chatKey());
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        setState(() {
          _messages.addAll(decoded.cast<Map<String, dynamic>>());
        });
      } else {
        // Welcome message
        _addAiMessage(
          "Halo! Saya PRABA AI, Asisten Cerdas Kebersihan VibEco.\n\n"
          "Kirimkan foto sampah dari Kamera Pemindai (real-time) atau Galeri Anda untuk mengetahui kategori sampah, cara membuang, dampak lingkungan, serta cara mendaur ulangnya!"
        );
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint("Failed to load chat history: $e");
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatKey(), jsonEncode(_messages));
    } catch (e) {
      debugPrint("Failed to save chat history: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addAiMessage(String text, {Map<String, dynamic>? prediction, String? imagePath}) {
    setState(() {
      _messages.add({
        'isUser': false,
        'text': text,
        'imagePath': imagePath,
        'prediction': prediction,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  void _addUserMessage(String text, {String? imagePath}) {
    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'imagePath': imagePath,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  Future<void> _processImageInference(String imagePath) async {
    setState(() {
      _isAiResponding = true;
    });

    try {
      final result = await OnnxPredictor().predict(imagePath);
      
      if (result['success'] == true) {
        final double confPct = (result['confidence'] as double) * 100;
        final String category = result['class_name'];
        
        if (result['low_confidence'] == true) {
          final String responseText = 
              "Saya melihat kemiripan dengan sampah $category (${confPct.toStringAsFixed(1)}%), namun tingkat keyakinan saya masih di bawah batas minimal (40%).\n\n"
              "Mohon pastikan objek sampah berada di tengah frame, memiliki pencahayaan yang cukup, dan tidak terhalang bayangan agar saya dapat mendeteksinya dengan akurat.";
          
          _addAiMessage(
            responseText,
            imagePath: imagePath,
          );
        } else {
          final String responseText = 
              "Saya mendeteksi objek ini sebagai sampah $category dengan tingkat keyakinan ${confPct.toStringAsFixed(1)}%.\n\n"
              "💡 Tips Pembuangan:\n${result['disposal']}\n\n"
              "♻️ Cara Daur Ulang:\n${result['recycling']}\n\n"
              "🌍 Dampak Lingkungan:\n${result['impact']}\n\n"
              "📝 Catatan Tambahan:\n${result['notes']}";
          
          _addAiMessage(
            responseText,
            prediction: result,
            imagePath: imagePath,
          );
        }
      } else {
        _addAiMessage(
          "Maaf ya 🙏, saya tidak berhasil menganalisis foto ini.\n\n"
          "Beberapa kemungkinan penyebabnya:\n"
          "• Foto terlalu gelap atau buram\n"
          "• Objek tidak terlihat jelas\n"
          "• Format gambar tidak didukung\n\n"
          "Coba kirim ulang dengan foto yang lebih jelas ya! 📸"
        );
      }
    } catch (e) {
      _addAiMessage(
        "Waduh, terjadi gangguan teknis saat saya menganalisis foto 😅\n\n"
        "Silakan coba lagi dalam beberapa saat. Pastikan foto sampah terlihat jelas dan tidak terlalu besar ukurannya."
      );
    } finally {
      setState(() {
        _isAiResponding = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

      _addUserMessage("Mengirim foto dari galeri...", imagePath: image.path);
      await _processImageInference(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar dari galeri: $e")),
      );
    }
  }

  Future<void> _openCameraScanner() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScannerScreen()),
      );

      if (result != null && result is Map) {
        final String imagePath = result['imagePath'];
        final Map<String, dynamic> pred = result['prediction'];

        _addUserMessage("Memindai sampah menggunakan kamera...", imagePath: imagePath);

        setState(() {
          _isAiResponding = true;
        });

        if (pred['success'] == true) {
          final double confPct = (pred['confidence'] as double) * 100;
          final String category = pred['class_name'];

          if (pred['low_confidence'] == true) {
            final String responseText = 
                "Hasil jepretan kamera menunjukkan kemiripan dengan sampah $category (${confPct.toStringAsFixed(1)}%), namun tingkat keyakinan saya masih terlalu rendah.\n\n"
                "Coba dekatkan kamera ke objek sampah dan pastikan posisinya berada tepat di tengah kotak pemindai.";
            
            _addAiMessage(
              responseText,
              imagePath: imagePath,
            );
          } else {
            final String responseText = 
                "Saya mendeteksi objek ini sebagai sampah $category dengan tingkat keyakinan ${confPct.toStringAsFixed(1)}%.\n\n"
                "💡 Tips Pembuangan:\n${pred['disposal']}\n\n"
                "♻️ Cara Daur Ulang:\n${pred['recycling']}\n\n"
                "🌍 Dampak Lingkungan:\n${pred['impact']}\n\n"
                "📝 Catatan Tambahan:\n${pred['notes']}";

            _addAiMessage(
              responseText,
              prediction: pred,
              imagePath: imagePath,
            );
          }
        } else {
          _addAiMessage("Gagal mendeteksi sampah pada foto jepretan kamera: ${pred['error']}");
        }

        setState(() {
          _isAiResponding = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error pemindai kamera: $e")),
      );
    }
  }

  Future<void> _handleTextSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addUserMessage(text);

    setState(() {
      _isAiResponding = true;
    });

    try {
      final reply = await _geminiService.chat(
        message: text,
        history: _messages,
      );
      _addAiMessage(reply);
    } catch (e) {
      _addAiMessage(
        "Waduh, terjadi gangguan teknis saat menghubungi asisten AI 😅\n\n"
        "Silakan coba lagi dalam beberapa saat."
      );
    } finally {
      setState(() {
        _isAiResponding = false;
      });
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Riwayat Chat"),
        content: const Text("Apakah Anda yakin ingin menghapus seluruh riwayat obrolan dengan PRABA AI?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_chatKey());
              _addAiMessage(
                "Halo! Saya *PRABA AI*, Asisten Cerdas Kebersihan VibEco.\n\n"
                "Kirimkan foto sampah dari Kamera Pemindai atau Galeri Anda untuk mendeteksi kategori dan mendapatkan panduan pengolahannya!"
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      // resizeToAvoidBottomInset true supaya chat tidak tertumpuk keyboard
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ─── PREMIUM GRADIENT HEADER ───
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F4D3A), Color(0xFF06241B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF06241B),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Row(
                  children: [
                    // Back Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title & online indicator
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Asisten Cerdas Kebersihan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                              SizedBox(width: 5),
                              Text(
                                'Online · Siap membantu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Clear chat action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _clearChat,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── CHAT BODY ───
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.04),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageItem(msg);
                      },
                    ),
                  ),

                  if (_isAiResponding)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: ClipOval(
                              child: Transform.scale(
                                scale: 1.1,
                                child: Image.asset(
                                  'assets/images/maskotbingung.png',
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            " PRABA Sedang menganalisis...",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildInputBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'] ?? false;
    final String text = msg['text'] ?? "";
    final String? imagePath = msg['imagePath'];
    final Map<String, dynamic>? pred = msg['prediction'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI mascot avatar
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.5,
                  child: Image.asset(
                    'assets/images/maskotprofil.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (imagePath != null && imagePath.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF0F4D3A).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.primaryDark,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),

                if (pred != null) ...[
                  const SizedBox(height: 8),
                  _buildIntelligenceCard(pred),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            // User avatar
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntelligenceCard(Map<String, dynamic> pred) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Analisis: ${pred['class_name']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildIntelligenceRow(
                      Icons.delete_outline,
                      "Cara Membuang",
                      pred['disposal'] ?? "N/A",
                      Colors.blue.shade700,
                    ),
                    const Divider(height: 22),
                    _buildIntelligenceRow(
                      Icons.nature_people_outlined,
                      "Dampak Lingkungan",
                      pred['impact'] ?? "N/A",
                      Colors.red.shade700,
                    ),
                    const Divider(height: 22),
                    _buildIntelligenceRow(
                      Icons.autorenew,
                      "Ide Daur Ulang",
                      pred['recycling'] ?? "N/A",
                      Colors.green.shade700,
                    ),
                    const Divider(height: 22),
                    _buildIntelligenceRow(
                      Icons.tips_and_updates_outlined,
                      "Tips Tambahan",
                      pred['notes'] ?? "N/A",
                      Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceRow(IconData icon, String title, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.primaryDark,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera scanner button - menggunakan foto.png
            GestureDetector(
              onTap: _openCameraScanner,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4D3A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/foto.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Gallery button
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Ketik pesan...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppTheme.primaryDark,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) _handleTextSubmitted(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: () => _handleTextSubmitted(_textController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4D3A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
