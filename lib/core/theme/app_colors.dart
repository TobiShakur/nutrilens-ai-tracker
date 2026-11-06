// PALETA DE COLORES CENTRALIZADA DEL DESIGN SYSTEM
// Define la paleta de identidad visual FoodTech (Forest Dark, Pistachio y semánticos)
// garantizando consistencia y contraste visual accesible en toda la interfaz.

import 'package:flutter/material.dart';

/// Paleta de diseño oficial inspirada en la referencia visual FoodTech (Forest Dark & Pistachio)
class AppColors {
  // Verdes del Hero Card
  static const Color forestDark = Color(0xFF0C4E36);
  static const Color forestDeep = Color(
    0xFF155442,
  ); // Verde más clarito para contenedores internos
  static const Color forestSlot = Color(
    0xFF185B47,
  ); // Verde suave visible para el track vacío del anillo y macros
  static const Color webBg = Color(0xFF07140E);

  // Acentos Pistacho / Lima Pastel (Botones, píldoras y anillo)
  static const Color pistachio = Color(0xFFD2F07A);
  static const Color pistachioLight = Color(0xFFEAF9C2);
  static const Color pistachioDark = Color(0xFF8BAA34);

  // Fondos y Superficies
  static const Color scaffoldBg = Color(0xFFF6F8F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFEFF4F1);

  // Tipografía
  static const Color textDark = Color(0xFF0D291E);
  static const Color textMuted = Color(0xFF6B8075);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMutedLight = Color(
    0xFFA5C4B4,
  ); // Más claro para mejor contraste

  // Bordes y Divisores
  static const Color borderLight = Color(0xFFE2EBE5);

  // Estados
  static const Color alertRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  // Anillo de calorías: primer exceso (naranja) y segundo exceso (rojo)
  static const Color exceedOrange = Color(0xFFFFA726);
  static const Color exceedOrangeSoft = Color(0xFFFFCC80);
  static const Color exceedOrangeStroke = Color(0xFFFF9500);
  static const Color exceedRed = Color(0xFFFF5252);
  static const Color exceedRedSoft = Color(0xFFFF8A80);
  static const Color exceedRedStroke = Color(0xFFFF3B30);

  // Health score: niveles
  static const Color scoreGood = Color(0xFF6E9A1F);
  static const Color scoreMid = Color(0xFFD98E04);
  static const Color scoreLow = Color(0xFFD9534F);
}
