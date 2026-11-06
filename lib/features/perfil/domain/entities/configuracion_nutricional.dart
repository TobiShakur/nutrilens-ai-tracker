import 'package:flutter/foundation.dart';

/// Configuración de metas nutricionales y tolerancias del usuario.
@immutable
class ConfiguracionNutricional {
  final int metaCalorias;
  final double metaProteinas;
  final double metaCarbos;
  final double metaGrasas;

  /// Tolerancia porcentual inferior (ej: 0.10 representa -10%).
  final double toleranciaInferior;

  /// Tolerancia porcentual superior (ej: 0.10 representa +10%).
  final double toleranciaSuperior;

  const ConfiguracionNutricional({
    this.metaCalorias = 2000,
    this.metaProteinas = 140.0,
    this.metaCarbos = 220.0,
    this.metaGrasas = 65.0,
    this.toleranciaInferior = 0.10,
    this.toleranciaSuperior = 0.10,
  });

  /// Límite mínimo de calorías para considerar el día dentro del objetivo.
  int get limiteMinimoCalorias =>
      (metaCalorias * (1.0 - toleranciaInferior)).round();

  /// Límite máximo de calorías para considerar el día dentro del objetivo.
  int get limiteMaximoCalorias =>
      (metaCalorias * (1.0 + toleranciaSuperior)).round();

  /// Determina si un número de calorías consumidas está dentro de la ventana de tolerancia.
  bool esCaloriaEnRango(int calorias) {
    return calorias >= limiteMinimoCalorias && calorias <= limiteMaximoCalorias;
  }

  /// Texto descriptivo de la ventana calórica (ej: "1800 - 2200 kcal").
  String get ventanaCaloricaLabel =>
      '$limiteMinimoCalorias - $limiteMaximoCalorias kcal';

  /// Etiqueta del límite inferior (ej: "-10%").
  String get toleranciaInferiorLabel =>
      '-${(toleranciaInferior * 100).round()}%';

  /// Etiqueta del límite superior (ej: "+10%").
  String get toleranciaSuperiorLabel =>
      '+${(toleranciaSuperior * 100).round()}%';

  ConfiguracionNutricional copyWith({
    int? metaCalorias,
    double? metaProteinas,
    double? metaCarbos,
    double? metaGrasas,
    double? toleranciaInferior,
    double? toleranciaSuperior,
  }) {
    return ConfiguracionNutricional(
      metaCalorias: metaCalorias ?? this.metaCalorias,
      metaProteinas: metaProteinas ?? this.metaProteinas,
      metaCarbos: metaCarbos ?? this.metaCarbos,
      metaGrasas: metaGrasas ?? this.metaGrasas,
      toleranciaInferior: toleranciaInferior ?? this.toleranciaInferior,
      toleranciaSuperior: toleranciaSuperior ?? this.toleranciaSuperior,
    );
  }

  Map<String, dynamic> toJson() => {
    'metaCalorias': metaCalorias,
    'metaProteinas': metaProteinas,
    'metaCarbos': metaCarbos,
    'metaGrasas': metaGrasas,
    'toleranciaInferior': toleranciaInferior,
    'toleranciaSuperior': toleranciaSuperior,
  };

  factory ConfiguracionNutricional.fromJson(Map<String, dynamic> json) =>
      ConfiguracionNutricional(
        metaCalorias: (json['metaCalorias'] as num?)?.toInt() ?? 2000,
        metaProteinas: (json['metaProteinas'] as num?)?.toDouble() ?? 140.0,
        metaCarbos: (json['metaCarbos'] as num?)?.toDouble() ?? 220.0,
        metaGrasas: (json['metaGrasas'] as num?)?.toDouble() ?? 65.0,
        toleranciaInferior:
            (json['toleranciaInferior'] as num?)?.toDouble() ?? 0.10,
        toleranciaSuperior:
            (json['toleranciaSuperior'] as num?)?.toDouble() ?? 0.10,
      );
}
