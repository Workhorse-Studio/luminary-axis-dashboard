import 'package:flutter/material.dart';

/// Color palette matching the Stakent crypto dashboard design
/// Dark theme with purple accents and clean visual hierarchy
class StakentColors {
  StakentColors._();

  // Primary Background Colors
  /// Deepest background - main app background
  static const Color bgPrimary = Color(0xFF0B0E14);

  /// Secondary background - sidebar, elevated surfaces
  static const Color bgSecondary = Color(0xFF11141C);

  /// Tertiary background - cards, containers
  static const Color bgTertiary = Color(0xFF151821);

  /// Elevated card background
  static const Color bgElevated = Color(0xFF1A1D26);

  // Surface Colors
  /// Input field backgrounds
  static const Color surfaceInput = Color(0xFF1E212B);

  /// Hover state surfaces
  static const Color surfaceHover = Color(0xFF252836);

  /// Pressed/active surfaces
  static const Color surfacePressed = Color(0xFF2D303D);

  // Purple Accent Colors (Primary Brand)
  /// Primary purple - buttons, active states
  static const Color purplePrimary = Color(0xFF9B87F5);

  /// Light purple - hover states, highlights
  static const Color purpleLight = Color(0xFFB4A7F7);

  /// Dark purple - borders, subtle accents
  static const Color purpleDark = Color(0xFF7C6AE0);

  /// Muted purple for backgrounds
  static const Color purpleMuted = Color(0xFF2D2844);

  /// Purple gradient start
  static const Color purpleGradientStart = Color(0xFF9B87F5);

  /// Purple gradient end
  static const Color purpleGradientEnd = Color(0xFF6B5CE7);

  /// Purple glow/shadow
  static const Color purpleGlow = Color(0x409B87F5);

  // Semantic Colors
  /// Success green - positive values, growth
  static const Color success = Color(0xFF22C55E);
  static const Color successMuted = Color(0xFF1A3D2A);

  /// Error red - negative values, alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0xFF3D1A1A);

  /// Warning yellow
  static const Color warning = Color(0xFFEAB308);

  /// Info blue
  static const Color info = Color(0xFF3B82F6);

  // Text Colors
  /// Primary text - headings, important content
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - body content
  static const Color textSecondary = Color(0xFF9CA3AF);

  /// Tertiary text - hints, disabled
  static const Color textTertiary = Color(0xFF6B7280);

  /// Muted text - placeholders, labels
  static const Color textMuted = Color(0xFF4B5563);

  // Border Colors
  /// Subtle borders
  static const Color borderSubtle = Color(0xFF2A2E3A);

  /// Default borders
  static const Color borderDefault = Color(0xFF374151);

  /// Active/focused borders
  static const Color borderActive = Color(0xFF9B87F5);

  // Chart/Graph Colors
  static const Color chartLinePrimary = Color(0xFF9B87F5);
  static const Color chartLineSecondary = Color(0xFF22C55E);
  static const Color chartLineTertiary = Color(0xFFEF4444);
  static const Color chartFill = Color(0x209B87F5);
  static const Color chartFillGreen = Color(0x2022C55E);
  static const Color chartFillRed = Color(0x20EF4444);

  // Gradient Definitions
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleGradientStart, purpleGradientEnd],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1D26), Color(0xFF151821)],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x309B87F5), Colors.transparent],
  );

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
