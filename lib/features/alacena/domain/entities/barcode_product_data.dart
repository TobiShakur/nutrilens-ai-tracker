import 'package:flutter/foundation.dart';
import 'categoria_alacena.dart';

/// Datos estructurados de un producto obtenidos mediante escáner de código de barras
/// (Open Food Facts API) o reconocimiento multimodal de etiqueta/envase con IA (Gemini Vision).
@immutable
class BarcodeProductData {
  final String nombre;
  final String marca;
  final double porcionGramos;
  final int calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final String? categoriaIdSugerida;
  final String? codigoBarras;
  final String fuente; // 'Open Food Facts' | 'Gemini Vision AI'

  const BarcodeProductData({
    required this.nombre,
    required this.marca,
    required this.porcionGramos,
    required this.calorias,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    this.categoriaIdSugerida,
    this.codigoBarras,
    required this.fuente,
  });

  /// Deducción inteligente de la categoría de alacena basada en macros y perfil nutricional.
  CategoriaAlacena resolverCategoriaSugerida(
    List<CategoriaAlacena> disponibles,
  ) {
    if (categoriaIdSugerida != null) {
      final match = disponibles
          .where((c) => c.id == categoriaIdSugerida)
          .firstOrNull;
      if (match != null) return match;
    }

    final p = porcionGramos > 0 ? porcionGramos : 100.0;
    final ratioProt = proteinas / p;
    final ratioGrasa = grasas / p;
    final ratioCarbo = carbohidratos / p;

    if (ratioProt >= 0.15 && ratioProt >= ratioCarbo) {
      return disponibles.firstWhere(
        (c) => c.id == 'proteinas',
        orElse: () => CategoriaAlacena.proteinas,
      );
    }
    if (ratioGrasa >= 0.20 &&
        ratioGrasa > ratioProt &&
        ratioGrasa > ratioCarbo) {
      return disponibles.firstWhere(
        (c) => c.id == 'grasas',
        orElse: () => CategoriaAlacena.grasas,
      );
    }
    if (ratioCarbo >= 0.20) {
      return disponibles.firstWhere(
        (c) => c.id == 'carbohidratos',
        orElse: () => CategoriaAlacena.carbohidratos,
      );
    }
    return disponibles.firstWhere(
      (c) => c.id == 'otros',
      orElse: () => CategoriaAlacena.otros,
    );
  }
}
