import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía estandarizada de la app:
/// - Plus Jakarta Sans: Fuente estándar y limpia para todos los títulos, textos y etiquetas.
/// - Rubik: Solo para los números de calorías y métricas ("anchitos y gorditos").
class AppTextStyles {
  AppTextStyles._();

  /// Números y métricas nutricionales (anchitos / display)
  static TextStyle number({
    double size = 16,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.forestDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.rubik(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Títulos estándar limpios y profesionales
  static TextStyle title({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.forestDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Títulos de sección y encabezados (Plus Jakarta Sans)
  static TextStyle display({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.forestDark,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Textos de cuerpo, descripciones y etiquetas estándar
  static TextStyle body({
    double size = 13.5,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textDark,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
