import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hasGeminiKey = false;
  String _geminiKey = '';

  @override
  void initState() {
    super.initState();
    _loadGeminiKey();
  }

  Future<void> _loadGeminiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('gemini_api_key') ?? '';
      setState(() {
        _hasGeminiKey = key.isNotEmpty;
        _geminiKey = key;
      });
    } catch (e) {
      debugPrint("Failed to load Gemini API key: $e");
    }
  }

  void _showGeminiKeyDialog() {
    final controller = TextEditingController(text: _geminiKey);
    bool obscureText = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldDark.withValues(alpha: 0.1),
                      blurRadius: 24.0,
                      offset: const Offset(0.0, 12.0),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.key_rounded,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'API Key Gemini',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cara mendapatkan API Key Gratis:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTutorialStep('1', 'Kunjungi Google AI Studio di https://aistudio.google.com/'),
                      _buildTutorialStep('2', 'Masuk menggunakan akun Google Anda.'),
                      _buildTutorialStep('3', 'Klik tombol "Get API key" kemudian klik "Create API key".'),
                      _buildTutorialStep('4', 'Pilih proyek atau klik "Create API key in new project".'),
                      _buildTutorialStep('5', 'Salin kode API Key yang telah dibuat.'),
                      _buildTutorialStep('6', 'Tempelkan kunci tersebut di bawah ini lalu klik Simpan.'),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller,
                        obscureText: obscureText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          floatingLabelStyle: const TextStyle(color: AppColors.primaryGreen),
                          hintText: 'Masukkan API Key Anda',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (_hasGeminiKey) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('gemini_api_key');
                                  await _loadGeminiKey();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('API Key berhasil dihapus')),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final key = controller.text.trim();
                                if (key.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kunci API tidak boleh kosong')),
                                  );
                                  return;
                                }

                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('gemini_api_key', key);
                                await _loadGeminiKey();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('API Key berhasil disimpan')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTutorialStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.emeraldMid,
              shape: BoxShape.circle,
            ),
            child: Text(
              number, 
              style: const TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // ─── FIXED EMERALD GRADIENT HEADER ───
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.emeraldGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SizedBox(
                  height: 52,
                  child: const Center(
                    child: Text(
                      'Profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── SCROLLABLE CONTENT ───
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Avatar with shadow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldDark.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.isStudent ? 'Siswa' : 'Guru',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── INFO CARDS ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          icon: Icons.person_outline_rounded,
                          label: 'Nama Lengkap',
                          value: user.name,
                        ),
                        if (user.className != null)
                          _buildInfoCard(
                            icon: Icons.class_outlined,
                            label: 'Kelas',
                            value: user.className!,
                          ),
                        if (user.nis != null)
                          _buildInfoCard(
                            icon: Icons.badge_outlined,
                            label: 'NIS',
                            value: user.nis!,
                          ),
                        if (user.email != null)
                          _buildInfoCard(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email!,
                          ),
                        
                        // ─── GEMINI API KEY CARD ───
                        GestureDetector(
                          onTap: _showGeminiKeyDialog,
                          child: _buildInfoCard(
                            icon: Icons.key_rounded,
                            label: 'API Key Gemini',
                            value: _hasGeminiKey ? 'Sudah Diatur' : 'Belum Diatur (Ketuk untuk Mengatur)',
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: AppColors.error.withValues(alpha: 0.2),
                              highlightColor: AppColors.error.withValues(alpha: 0.1),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.emeraldDark.withValues(alpha: 0.1),
                                            blurRadius: 24.0,
                                            offset: const Offset(0.0, 12.0),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.logout_rounded,
                                              size: 36,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'Keluar Akun?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.emeraldDark,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Apakah Anda yakin ingin keluar dari aplikasi? Anda harus login kembali untuk masuk.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    side: BorderSide(color: Colors.grey.shade300),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Batal',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.error,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Ya, Keluar',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  await auth.clearSession();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Keluar Akun',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODERN INFO CARD (matching dashboard theme) ───
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emeraldMid, AppColors.primaryGreen],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}