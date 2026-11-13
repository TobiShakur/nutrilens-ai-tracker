import 'package:flutter/foundation.dart';
import 'barcode_validator.dart';
import 'categoria_alacena.dart';

/// Datos estructurados de un producto obtenidos mediante escáner de código de barras
/// (Open Food Facts API) o reconocimiento multimodal de etiqueta/envase con IA (Gemini Vision).
@immutable
class BarcodeProductData {
  static const int maxNombreChars = 120;
  static const int maxMarcaChars = 80;

  final String nombre;
  final String marca;
  final double porcionGramos;
  final int calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final String? categoriaIdSugerida;
  final String? codigoBarras;
  final String fuente;

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

  /// Normalizador único que garantiza cotas finitas, truncado de textos y código GS1 válido.
  factory BarcodeProductData.normalizar({
    required String nombre,
    String marca = '',
    required double porcionGramos,
    required int calorias,
    required double proteinas,
    required double carbohidratos,
    required double grasas,
    String? categoriaIdSugerida,
    String? codigoBarras,
    required String fuente,
  }) {
    final nombreNormalizado = _truncar(nombre.trim(), maxNombreChars);
    final marcaNormalizada = _truncar(marca.trim(), maxMarcaChars);
    final porcionNormalizada = (!porcionGramos.isFinite || porcionGramos <= 0)
        ? 100.0
        : porcionGramos.clamp(1.0, 10000.0).toDouble();
    final caloriasNormalizadas = calorias.clamp(0, 10000);

    String? codigoValidado;
    if (codigoBarras != null) {
      final limpio = BarcodeValidator.limpiar(codigoBarras);
      if (BarcodeValidator.esCodigoValido(limpio)) {
        codigoValidado = limpio;
      }
    }

    final catTrim = categoriaIdSugerida?.trim();
    final categoriaNormalizada = (catTrim == null || catTrim.isEmpty)
        ? null
        : catTrim;

    return BarcodeProductData(
      nombre: nombreNormalizado,
      marca: marcaNormalizada,
      porcionGramos: porcionNormalizada,
      calorias: caloriasNormalizadas,
      proteinas: _normalizarMacro(proteinas),
      carbohidratos: _normalizarMacro(carbohidratos),
      grasas: _normalizarMacro(grasas),
      categoriaIdSugerida: categoriaNormalizada,
      codigoBarras: codigoValidado,
      fuente: fuente.trim(),
    );
  }

  static double _normalizarMacro(double valor) {
    if (!valor.isFinite || valor <= 0) return 0.0;
    final clamped = valor.clamp(0.0, 1000.0);
    return (clamped * 10).round() / 10.0;
  }

  static String _truncar(String texto, int maxChars) {
    if (texto.length <= maxChars) return texto;
    return texto.substring(0, maxChars);
  }

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

    final p = porcionGramos.isFinite && porcionGramos > 0
        ? porcionGramos
        : 100.0;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeProductData &&
          runtimeType == other.runtimeType &&
          nombre == other.nombre &&
          marca == other.marca &&
          porcionGramos == other.porcionGramos &&
          calorias == other.calorias &&
          proteinas == other.proteinas &&
          carbohidratos == other.carbohidratos &&
          grasas == other.grasas &&
          categoriaIdSugerida == other.categoriaIdSugerida &&
          codigoBarras == other.codigoBarras &&
          fuente == other.fuente;

  @override
  int get hashCode => Object.hash(
    nombre,
    marca,
    porcionGramos,
    calorias,
    proteinas,
    carbohidratos,
    grasas,
    categoriaIdSugerida,
    codigoBarras,
    fuente,
  );
}
