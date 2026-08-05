import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  /// PlusJakartaSans-Regular.ttf — textos de cuerpo.
  static const FontWeight regular = FontWeight.w400;

  /// PlusJakartaSans-Medium.ttf — textos secundarios, títulos de auth y énfasis intermedio.
  static const FontWeight medium = FontWeight.w500;

  /// PlusJakartaSans-Bold.ttf — títulos llamativos de ofertas de empleo.
  static const FontWeight bold = FontWeight.w700;

  /// Estilo dedicado para títulos de ofertas en job_posting / job_search.
  /// Preferir `Theme.of(context).textTheme.displaySmall` cuando exista BuildContext.
  static const TextStyle offerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: bold,
    height: 1.25,
    color: AppColors.navy,
  );
}
