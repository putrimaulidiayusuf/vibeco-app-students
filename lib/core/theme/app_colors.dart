import 'package:flutter/material.dart';

/// Centralized color palette for VibeCo app.
class AppColors {
  AppColors._();

  // ─── Emerald Brand Colors ───
  /// Deep emerald – background dark tone  #06241B
  static const Color emeraldDark = Color(0xFF06241B);

  /// Normal emerald – background lighter tone  #0F4D3A
  static const Color emeraldMid = Color(0xFF0F4D3A);

  /// Primary green used across the app
  static const Color primaryGreen = Color(0xFF2E7D32);

  /// Lighter primary green
  static const Color primaryLight = Color(0xFF4CAF50);

  /// Dark primary green
  static const Color primaryDark = Color(0xFF1B5E20);

  // ─── Gradient ───
  /// Main background gradient: emerald dark → emerald mid (top → bottom)
  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [emeraldDark, emeraldMid],
  );

  // ─── Surface ───
  static const Color cardWhite = Colors.white;
  static const Color cardSurface = Color(0xFFF0F0F0);

  // ─── Status ───
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF42A5F5);
}
