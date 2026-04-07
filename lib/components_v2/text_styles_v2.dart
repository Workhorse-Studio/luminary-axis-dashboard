import 'package:flutter/material.dart';
import 'colors_v2.dart';

/// Typography system for Stakent Dashboard v2
class StakentTextStyles {
  StakentTextStyles._();

  static const String primaryFont = 'Inter';
  static const String displayFont = 'Urbanist';

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: StakentColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: StakentColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Heading Styles
  static const TextStyle headingLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    height: 1.4,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: StakentColors.textSecondary,
    height: 1.5,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: StakentColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: StakentColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: StakentColors.textTertiary,
    height: 1.5,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: StakentColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: StakentColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: StakentColors.textSecondary,
    letterSpacing: 0.3,
    height: 1.4,
  );

  // Stat/Metric Styles
  static const TextStyle statLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: StakentColors.textPrimary,
    letterSpacing: -1,
    height: 1.1,
  );

  static const TextStyle statMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: StakentColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle statSmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: StakentColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  // Percentage/Change Styles
  static const TextStyle percentagePositive = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: StakentColors.success,
    height: 1.4,
  );

  static const TextStyle percentageNegative = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: StakentColors.error,
    height: 1.4,
  );

  // Brand/Logo Styles
  static const TextStyle brand = TextStyle(
    fontFamily: displayFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: StakentColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle brandTagline = TextStyle(
    fontFamily: primaryFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: StakentColors.textTertiary,
    letterSpacing: 1.5,
    height: 1.2,
  );

  // Navigation Styles
  static const TextStyle navActive = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: StakentColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle navInactive = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: StakentColors.textSecondary,
    height: 1.4,
  );

  // Caption/Meta Styles
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: StakentColors.textMuted,
    height: 1.4,
  );
}
