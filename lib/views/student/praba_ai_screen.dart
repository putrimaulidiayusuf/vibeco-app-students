import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'praba_chatbot_screen.dart';

class PrabaAiScreen extends StatelessWidget {
  final bool asRoute;
  const PrabaAiScreen({super.key, this.asRoute = false});

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mascot image - tanpa background/border, diperbesar
          Image.asset(
            'assets/images/maskothello.png',
            width: 210,
            height: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          // Subtitle
          Text(
            'Asisten Cerdas Kebersihan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // ─── MAIN CHAT CARD ───
          _buildMainChatCard(context),
          const SizedBox(height: 20),

          // ─── FEATURE CARDS GRID ───
          _buildFeatureGrid(),
          const SizedBox(height: 20),

          // ─── CAPABILITY HINTS ───
          _buildCapabilitySection(),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
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
                    if (asRoute) ...[
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
                    ],

                    // Title & subtitle (Centered)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'PRABA AI',
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
                          const SizedBox(height: 2),
                          const Text(
                            'Deteksi & analisis sampah dengan AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Balance padding for center alignment if there's a back button
                    if (asRoute) const SizedBox(width: 56),
                  ],
                ),
              ),
            ),
          ),
          // ─── BODY ───
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildMainChatCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4D3A), Color(0xFF1B6B4A), Color(0xFF06241B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4D3A).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar maskotprofil - lebih besar & lebih zoom
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.0,
                          child: Image.asset(
                            'assets/images/maskotprofil.png',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat dengan PRABA AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                              SizedBox(width: 5),
                              Text(
                                'Online & siap membantu',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Kirimkan foto sampah Anda melalui kamera pemindai atau galeri untuk mendeteksi kategori, dampak lingkungan, dan cara daur ulang secara instan.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F4D3A),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        _slideRoute(const PrabaChatBotScreen()),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_rounded, size: 18),
                        SizedBox(width: 9),
                        Text(
                          'Mulai Obrolan Sekarang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        icon: Icons.camera_alt_rounded,
        label: 'Kamera Pemindai',
        desc: 'Scan real-time',
        gradient: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
      ),
      _FeatureItem(
        icon: Icons.photo_library_rounded,
        label: 'Upload Galeri',
        desc: 'Dari foto tersimpan',
        gradient: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      ),
      _FeatureItem(
        icon: Icons.recycling_rounded,
        label: 'Ide Daur Ulang',
        desc: 'Tips kreatif',
        gradient: [const Color(0xFF00695C), const Color(0xFF00897B)],
      ),
      _FeatureItem(
        icon: Icons.analytics_rounded,
        label: 'Analisis Detail',
        desc: 'Info lengkap',
        gradient: [const Color(0xFFE65100), const Color(0xFFF4511E)],
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: features
          .map((f) => _buildFeatureGridItem(f))
          .toList(),
    );
  }

  Widget _buildFeatureGridItem(_FeatureItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.gradient.last.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            item.desc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitySection() {
    final hints = [
      _HintItem(Icons.chat_bubble_outline_rounded, 'Tanya jawab seputar kebersihan'),
      _HintItem(Icons.lightbulb_outline_rounded, 'Tips & saran peningkatan skor'),
      _HintItem(Icons.analytics_outlined, 'Analisis pola kebersihan kelas'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kemampuan AI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          ...hints.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(h.icon, size: 18, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h.text,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final String desc;
  final List<Color> gradient;
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.gradient,
  });
}

class _HintItem {
  final IconData icon;
  final String text;
  const _HintItem(this.icon, this.text);
}
