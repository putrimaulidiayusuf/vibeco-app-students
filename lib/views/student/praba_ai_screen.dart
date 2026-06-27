import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrabaAiScreen extends StatelessWidget {
  const PrabaAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Icon with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                    Color(0xFF66BB6A),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'PRABA AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
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
            // Coming soon card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGreen,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.construction_rounded,
                    size: 32,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Segera Hadir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fitur PRABA AI sedang dalam tahap pengembangan. '
                    'Nantikan kemampuan AI yang akan membantu '
                    'menganalisis dan meningkatkan kebersihan kelas Anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Feature hints
            _buildFeatureHint(
              Icons.chat_bubble_outline_rounded,
              'Tanya jawab seputar kebersihan',
            ),
            const SizedBox(height: 12),
            _buildFeatureHint(
              Icons.lightbulb_outline_rounded,
              'Tips & saran peningkatan skor',
            ),
            const SizedBox(height: 12),
            _buildFeatureHint(
              Icons.analytics_outlined,
              'Analisis pola kebersihan kelas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHint(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
