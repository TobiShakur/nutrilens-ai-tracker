// TEMA GLOBAL MATERIAL 3 CON TIPOGRAFÍA PLUS JAKARTA SANS
// Configura los tokens visuales, esquemas de color y estilo tipográfico de la app.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forestDark,
        primary: AppColors.forestDark,
        secondary: AppColors.pistachio,
        surface: AppColors.cardWhite,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    );
  }
}
