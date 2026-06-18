import 'package:flutter/material.dart';

/// Design System Color Tokens cho ứng dụng TopTop (TikTok Clone)
/// Cung cấp bảng màu đạt tiêu chuẩn tương phản cao WCAG AA cho cả Light & Dark Theme
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFE2C55);   // Hồng đỏ TikTok
  static const Color secondary = Color(0xFF25F4EE); // Xanh cyan TikTok
  static const Color primaryGradientStart = Color(0xFFFE2C55);
  static const Color primaryGradientEnd = Color(0xFFFF6A88);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF25F4EE), Color(0xFF00C9DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF25F4EE), Color(0xFFFE2C55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme Palette ────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F8F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightTextPrimary = Color(0xFF161722);
  static const Color lightTextSecondary = Color(0xFF8A8B90);
  static const Color lightTextHint = Color(0xFFC5C6C9);

  // ── Dark Theme Palette (TikTok AMOLED Black Style) ───────────────────────
  static const Color darkBg = Color(0xFF0F0F10);      // Nền tối thuần khiết AMOLED
  static const Color darkSurface = Color(0xFF161618); // Khung viền và các phân vùng phụ
  static const Color darkCard = Color(0xFF1E1E22);
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0AB);
  static const Color darkTextHint = Color(0xFF505056);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);
}
