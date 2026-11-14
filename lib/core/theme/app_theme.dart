// TEMA GLOBAL MATERIAL 3 CON TIPOGRAFÍA PLUS JAKARTA SANS
// Configura los tokens visuales, esquemas de color y estilo tipográfico de la app.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Plus Jakarta Sans';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forestDark,
        primary: AppColors.forestDark,
        secondary: AppColors.pistachio,
        surface: AppColors.cardWhite,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: _fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _fontFamily),
    );
  }
}
