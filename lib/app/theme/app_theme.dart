import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.terracotta,
          onPrimary: AppColors.white,
          secondary: AppColors.navy,
          onSecondary: AppColors.cream,
          surface: AppColors.cream,
          onSurface: AppColors.navy,
          error: AppColors.error,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 34,
          fontWeight: AppTypography.bold,
          height: 1.15,
        ),
        headlineSmall: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: AppTypography.bold,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: AppTypography.semiBold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 16,
          fontWeight: AppTypography.regular,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.navy,
          fontSize: 14,
          fontWeight: AppTypography.regular,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.cream,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.cream,
          fontSize: 20,
          fontWeight: AppTypography.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: AppTypography.semiBold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
