import 'package:flutter/foundation.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';

/// Representa un ingrediente individual consumido dentro de una comida con su gramaje específico.
@immutable
class ComidaIngrediente {
  final String id;
  final String? ingredienteAlacenaId;
  final String nombre;
  final String? marca;
  final String emoji;
  final double gramos; // Cantidad consumida (ej: 120.0g)

  // Macros calculados específicamente para este gramaje consumido
  final int calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;

  // Valores de referencia base por 100g para recálculo proporcional
  final double caloriasPor100g;
  final double proteinasPor100g;
  final double carbosPor100g;
  final double grasasPor100g;

  const ComidaIngrediente({
    required this.id,
    this.ingredienteAlacenaId,
    required this.nombre,
    this.marca,
    required this.emoji,
    required this.gramos,
    required this.calorias,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    required this.caloriasPor100g,
    required this.proteinasPor100g,
    required this.carbosPor100g,
    required this.grasasPor100g,
  });

  static int _seq = 0;

  /// Crea un ComidaIngrediente a partir de un alimento de la Alacena y la porción en gramos consumida
  factory ComidaIngrediente.desdeAlacena({
    String? id,
    required IngredienteAlacena alacena,
    required double gramos,
  }) {
    final c100 = alacena.caloriasPor100g.toDouble();
    final p100 = alacena.proteinasPor100g;
    final carb100 = alacena.carbohidratosPor100g;
    final g100 = alacena.grasasPor100g;
    final ratio = (gramos > 0 ? gramos : 0.0) / 100.0;

    return ComidaIngrediente(
      id: id ?? 'ci_${DateTime.now().microsecondsSinceEpoch}_${_seq++}',
      ingredienteAlacenaId: alacena.id,
      nombre: alacena.nombre,
      marca: alacena.marca,
      emoji: alacena.categoria.emoji,
      gramos: gramos,
      calorias: (c100 * ratio).round(),
      proteinas: double.parse((p100 * ratio).toStringAsFixed(1)),
      carbohidratos: double.parse((carb100 * ratio).toStringAsFixed(1)),
      grasas: double.parse((g100 * ratio).toStringAsFixed(1)),
      caloriasPor100g: c100,
      proteinasPor100g: p100,
      carbosPor100g: carb100,
      grasasPor100g: g100,
    );
  }

  /// Crea un ComidaIngrediente manual cuando no viene de la alacena
  factory ComidaIngrediente.manual({
    required String id,
    required String nombre,
    String? marca,
    String emoji = '🥗',
    required double gramos,
    required int calorias,
    required double proteinas,
    required double carbohidratos,
    required double grasas,
  }) {
    final factor = gramos > 0 ? (100.0 / gramos) : 1.0;
    return ComidaIngrediente(
      id: id,
      ingredienteAlacenaId: null,
      nombre: nombre,
      marca: marca,
      emoji: emoji,
      gramos: gramos,
      calorias: calorias,
      proteinas: proteinas,
      carbohidratos: carbohidratos,
      grasas: grasas,
      caloriasPor100g: calorias * factor,
      proteinasPor100g: proteinas * factor,
      carbosPor100g: carbohidratos * factor,
      grasasPor100g: grasas * factor,
    );
  }

  /// Devuelve una copia con la nueva cantidad en gramos, recalculando todos los macros
  ComidaIngrediente conGramos(double nuevosGramos) {
    final g = nuevosGramos < 0 ? 0.0 : nuevosGramos;
    final ratio = g / 100.0;

    return copyWith(
      gramos: g,
      calorias: (caloriasPor100g * ratio).round(),
      proteinas: double.parse((proteinasPor100g * ratio).toStringAsFixed(1)),
      carbohidratos: double.parse((carbosPor100g * ratio).toStringAsFixed(1)),
      grasas: double.parse((grasasPor100g * ratio).toStringAsFixed(1)),
    );
  }

  String get nombreConMarca =>
      (marca != null && marca!.trim().isNotEmpty) ? '$nombre ($marca)' : nombre;

  String get porcionLabel => '${gramos.round()}g';

  ComidaIngrediente copyWith({
    String? id,
    String? ingredienteAlacenaId,
    String? nombre,
    String? marca,
    String? emoji,
    double? gramos,
    int? calorias,
    double? proteinas,
    double? carbohidratos,
    double? grasas,
    double? caloriasPor100g,
    double? proteinasPor100g,
    double? carbosPor100g,
    double? grasasPor100g,
  }) {
    return ComidaIngrediente(
      id: id ?? this.id,
      ingredienteAlacenaId: ingredienteAlacenaId ?? this.ingredienteAlacenaId,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      emoji: emoji ?? this.emoji,
      gramos: gramos ?? this.gramos,
      calorias: calorias ?? this.calorias,
      proteinas: proteinas ?? this.proteinas,
      carbohidratos: carbohidratos ?? this.carbohidratos,
      grasas: grasas ?? this.grasas,
      caloriasPor100g: caloriasPor100g ?? this.caloriasPor100g,
      proteinasPor100g: proteinasPor100g ?? this.proteinasPor100g,
      carbosPor100g: carbosPor100g ?? this.carbosPor100g,
      grasasPor100g: grasasPor100g ?? this.grasasPor100g,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ingredienteAlacenaId': ingredienteAlacenaId,
    'nombre': nombre,
    'marca': marca,
    'emoji': emoji,
    'gramos': gramos,
    'calorias': calorias,
    'proteinas': proteinas,
    'carbohidratos': carbohidratos,
    'grasas': grasas,
    'caloriasPor100g': caloriasPor100g,
    'proteinasPor100g': proteinasPor100g,
    'carbosPor100g': carbosPor100g,
    'grasasPor100g': grasasPor100g,
  };

  factory ComidaIngrediente.fromJson(Map<String, dynamic> json) =>
      ComidaIngrediente(
        id: json['id'] as String,
        ingredienteAlacenaId: json['ingredienteAlacenaId'] as String?,
        nombre: json['nombre'] as String,
        marca: json['marca'] as String?,
        emoji: json['emoji'] as String? ?? '🥗',
        gramos: (json['gramos'] as num).toDouble(),
        calorias: (json['calorias'] as num).toInt(),
        proteinas: (json['proteinas'] as num).toDouble(),
        carbohidratos: (json['carbohidratos'] as num).toDouble(),
        grasas: (json['grasas'] as num).toDouble(),
        caloriasPor100g: (json['caloriasPor100g'] as num?)?.toDouble() ?? 0.0,
        proteinasPor100g: (json['proteinasPor100g'] as num?)?.toDouble() ?? 0.0,
        carbosPor100g: (json['carbosPor100g'] as num?)?.toDouble() ?? 0.0,
        grasasPor100g: (json['grasasPor100g'] as num?)?.toDouble() ?? 0.0,
      );
}
