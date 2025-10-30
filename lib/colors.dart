import 'package:flutter/material.dart';

/// NovaDraw AI Color Palette
/// 🌈 Primary Color Palette (Main UI)
class AppColors {
  // Primary Colors
  /// Sky Blue - Friendly, calming, gender-neutral (Primary buttons, highlights)
  static const Color primary = Color(0xFF4DA6FF);

  /// Bright Yellow - Joyful and energetic (Secondary)
  static const Color secondary = Color(0xFFFFD93D);

  /// Soft Pink - Adds warmth and fun (Accent)
  static const Color accent = Color(0xFFFF7EB9);

  /// Mint Green - Feels natural and creative (Success / Positive)
  static const Color success = Color(0xFF7CFFCB);

  /// Light Cream - Easy on eyes, gives warmth (Background)
  static const Color background = Color(0xFFFFF9E6);

  // Additional useful colors for UI
  /// White for contrast and clean areas
  static const Color white = Color(0xFFFFFFFF);

  /// Dark text color for good readability on light backgrounds
  static const Color textDark = Color(0xFF2D3748);

  /// Light text color for use on dark backgrounds
  static const Color textLight = Color(0xFFFFFFFF);

  /// Subtle gray for borders and dividers
  static const Color border = Color(0xFFE2E8F0);

  /// Error/warning color (complementary red)
  static const Color error = Color(0xFFFF6B6B);

  // Color variations for different states
  /// Darker version of primary for pressed states
  static const Color primaryDark = Color(0xFF3D8BFF);

  /// Lighter version of primary for hover/disabled states
  static const Color primaryLight = Color(0xFF80C1FF);
}
