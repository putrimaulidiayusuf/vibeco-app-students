import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/onnx_predictor.dart';
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
  bool _isAiResponding = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('praba_chat_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        setState(() {
          _messages.addAll(decoded.cast<Map<String, dynamic>>());
        });
      } else {
        // Welcome message
        _addAiMessage(
          "Halo! Saya **PRABA AI**, Asisten Cerdas Kebersihan ZieClean.\n\n"
          "Kirimkan foto sampah dari **Kamera Pemindai** (real-time) atau **Galeri** Anda untuk mengetahui kategori sampah, cara membuang, dampak lingkungan, serta cara mendaur ulangnya!"
        );
      }
      _scrollToBottom();
    } catch (e) {
      print("Failed to load chat history: $e");
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('praba_chat_history', jsonEncode(_messages));
    } catch (e) {
      print("Failed to save chat history: $e");
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
              "Saya melihat kemiripan dengan sampah **$category** (${confPct.toStringAsFixed(1)}%), namun tingkat keyakinan saya masih di bawah batas minimal (40%).\n\n"
              "Mohon pastikan objek sampah berada di tengah frame, memiliki pencahayaan yang cukup, dan tidak terhalang bayangan agar saya dapat mendeteksinya dengan akurat.";
          
          _addAiMessage(
            responseText,
            imagePath: imagePath,
          );
        } else {
          final String responseText = 
              "Saya mendeteksi objek ini sebagai sampah **$category** dengan tingkat keyakinan **${confPct.toStringAsFixed(1)}%**.";
          
          _addAiMessage(
            responseText,
            prediction: result,
            imagePath: imagePath,
          );
        }
      } else {
        _addAiMessage("Maaf, saya tidak dapat menganalisis gambar ini. Error: ${result['error']}");
      }
    } catch (e) {
      _addAiMessage("Terjadi kesalahan sistem saat mendeteksi gambar: $e");
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
                "Hasil jepretan kamera menunjukkan kemiripan dengan sampah **$category** (${confPct.toStringAsFixed(1)}%), namun tingkat keyakinan saya masih terlalu rendah.\n\n"
                "Coba dekatkan kamera ke objek sampah dan pastikan posisinya berada tepat di tengah kotak pemindai.";
            
            _addAiMessage(
              responseText,
              imagePath: imagePath,
            );
          } else {
            final String responseText = 
                "Saya mendeteksi objek ini sebagai sampah **$category** dengan tingkat keyakinan **${confPct.toStringAsFixed(1)}%**.";

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error pemindai kamera: $e")),
      );
    }
  }

  void _handleTextSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addUserMessage(text);

    setState(() {
      _isAiResponding = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      final lower = text.toLowerCase();
      String reply = "";
      if (lower.contains("halo") || lower.contains("hai")) {
        reply = "Halo! Ada yang bisa saya bantu hari ini? Silakan kirimkan foto sampah Anda agar saya bisa mendeteksinya.";
      } else if (lower.contains("siapa") || lower.contains("praba")) {
        reply = "Saya adalah **PRABA AI**, asisten kebersihan ZieClean Anda. Saya dilatih untuk mendeteksi 7 jenis sampah menggunakan model AI secara lokal di perangkat Anda.";
      } else if (lower.contains("bersih") || lower.contains("piket")) {
        reply = "Untuk menjaga kebersihan kelas, pastikan Anda menyapu lantai, merapikan meja, dan membuang sampah sesuai dengan tempat pembuangan yang benar.";
      } else {
        reply = "Untuk menganalisis sampah dengan akurat, silakan gunakan tombol kamera pemindai (kiri) atau ikon galeri di bawah untuk mengirimkan foto objek sampah.";
      }

      _addAiMessage(reply);
      setState(() {
        _isAiResponding = false;
      });
    });
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
              await prefs.remove('praba_chat_history');
              _addAiMessage(
                "Halo! Saya **PRABA AI**, Asisten Cerdas Kebersihan ZieClean.\n\n"
                "Kirimkan foto sampah dari **Kamera Pemindai** atau **Galeri** Anda untuk mendeteksi kategori dan mendapatkan panduan pengolahannya!"
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
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "PRABA AI Chat Bot",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: "Hapus Chat",
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Chat message list
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "PRABA AI sedang menganalisis...",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Bottom input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'] ?? false;
    final String text = msg['text'] ?? "";
    final String? imagePath = msg['imagePath'];
    final Map<String, dynamic>? pred = msg['prediction'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Render image if present
                if (imagePath != null && imagePath.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Render chat bubble text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? AppTheme.primaryGreen 
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.primaryDark,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),

                // If prediction details are attached, render waste intelligence cards
                if (pred != null) ...[
                  const SizedBox(height: 8),
                  _buildIntelligenceCard(pred),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.black54),
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
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: AppTheme.surfaceGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Analisis Informasi Sampah: ${pred['class_name']}",
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                    const Divider(height: 24),
                    _buildIntelligenceRow(
                      Icons.nature_people_outlined,
                      "Dampak Lingkungan",
                      pred['impact'] ?? "N/A",
                      Colors.red.shade700,
                    ),
                    const Divider(height: 24),
                    _buildIntelligenceRow(
                      Icons.autorenew,
                      "Ide Daur Ulang",
                      pred['recycling'] ?? "N/A",
                      Colors.green.shade700,
                    ),
                    const Divider(height: 24),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
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
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: SafeArea(
        child: Row(
          children: [
            // Camera scanner button
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGreen, size: 28),
              tooltip: "Kamera Pemindai",
              onPressed: _openCameraScanner,
            ),
            // Gallery button
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen, size: 26),
              tooltip: "Pilih Galeri",
              onPressed: _pickFromGallery,
            ),
            const SizedBox(width: 4),
            // Text field input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Ketik pesan...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: _handleTextSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppTheme.primaryGreen),
              onPressed: () => _handleTextSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
