import 'package:flutter/material.dart';

/// Paleta de [ocupa2-app en Figma](https://www.figma.com/design/BSSAo9xjU0ARwhzm9lVesT/ocupa2-app?node-id=2-2001).
///
/// Tokens del login (`2:2001`): `#0F172A` texto, `#2563EB` marca,
/// `#E2E8F0` bordes, `#F8FAFC` fondo.
abstract final class AppColors {
  /// Fondo de pantalla e inputs. Figma `#F8FAFC`.
  static const Color cream = Color(0xFFF8FAFC);

  /// Texto, iconos e indicador. Figma `#0F172A`.
  static const Color navy = Color(0xFF0F172A);

  /// Marca, botones primarios y enlaces. Figma `#2563EB`.
  static const Color terracotta = Color(0xFF2563EB);

  static const Color white = Color(0xFFFFFFFF);

  /// Borde de campos y divisores. Figma `#E2E8F0`.
  static const Color border = Color(0xFFE2E8F0);

  /// Texto sobre botones primarios. Mismo valor que [cream].
  static const Color onPrimary = cream;

  /// Relleno de campos de texto. Mismo valor que [cream].
  static const Color inputFill = cream;

  /// Enlaces de acción (olvidé contraseña, crear cuenta).
  static const Color link = terracotta;

  /// Alias semánticos para pantallas nuevas (mismos valores Figma).
  static const Color surface = cream;
  static const Color text = navy;
  static const Color primary = terracotta;

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorSurface = Color(0xFFFFEDEA);

  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
}
