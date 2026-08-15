import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';

abstract final class AppTheme {
  static OutlineInputBorder _inputBorder({
    Color color = AppColors.border,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData get light {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.terracotta,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.navy,
          onSecondary: AppColors.cream,
          surface: AppColors.cream,
          onSurface: AppColors.navy,
          error: AppColors.error,
          outline: AppColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.navy,
          fontSize: 22,
          fontWeight: AppTypography.bold,
          height: 1.25,
        ),
        headlineLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 34,
          fontWeight: AppTypography.medium,
          height: 1.15,
        ),
        headlineSmall: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: AppTypography.medium,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: AppTypography.medium,
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
        labelLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: AppTypography.medium,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: AppTypography.medium,
          fontFamily: AppTypography.fontFamily,
        ),
        iconTheme: IconThemeData(color: AppColors.navy),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: AppTypography.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.link,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: AppTypography.medium,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: TextStyle(
          color: AppColors.navy.withValues(alpha: 0.45),
          fontSize: 15,
          fontWeight: AppTypography.regular,
        ),
        prefixIconColor: AppColors.navy,
        suffixIconColor: AppColors.navy,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: AppColors.terracotta, width: 2),
        errorBorder: _inputBorder(color: AppColors.error),
        focusedErrorBorder: _inputBorder(color: AppColors.error, width: 2),
      ),
    );
  }
}
