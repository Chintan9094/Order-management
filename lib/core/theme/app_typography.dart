import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme() {
    final display = GoogleFonts.syne();
    final body = GoogleFonts.dmSans();

    return TextTheme(
      displayLarge: display.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.15,
      ),
      displayMedium: display.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.2,
      ),
      headlineLarge: display.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      headlineMedium: display.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      headlineSmall: display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      titleLarge: body.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      titleMedium: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      titleSmall: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSoft,
        height: 1.45,
      ),
      bodyMedium: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSoft,
        height: 1.45,
      ),
      bodySmall: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        height: 1.4,
      ),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      labelMedium: body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      labelSmall: body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      ),
    );
  }
}
