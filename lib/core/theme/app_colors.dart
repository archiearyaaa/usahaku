import 'package:flutter/material.dart';

/// Palet warna USAHAKU sesuai ARCHITECTURE.md
class AppColors {
  AppColors._();

  // Warna Utama
  static const Color primary = Color(0xFFFF2800);
  static const Color primaryContainer = Color(0xFFFFECE8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF8F1300);

  // Background & Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color surfaceContainerHighest = Color(0xFFECECEC);
  static const Color onBackground = Color(0xFF292D35);
  static const Color onSurface = Color(0xFF292D35);

  // Teks
  static const Color textPrimary = Color(0xFF292D35);
  static const Color textSecondary = Color(0xFF858585);
  static const Color textDisabled = Color(0xFFB0B0B0);

  // Border & Divider
  static const Color border = Color(0xFFE5E5E5);
  static const Color divider = Color(0xFFEEEEEE);

  // Status (Success, Danger, Warning, Info)
  static const Color success = Color(0xFF16A36A);
  static const Color successContainer = Color(0xFFE8F8F0);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFE53935);
  static const Color dangerContainer = Color(0xFFFDECEC);
  static const Color onDanger = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFEFF6FF);
}
