import 'package:flutter/foundation.dart';
import 'categoria_alacena.dart';

@immutable
class IngredienteAlacena {
  final String id;
  final String nombre;
  final String? marca;
  final CategoriaAlacena categoria;
  final double gramosPorcion;
  final int calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final DateTime creadoEn;

  const IngredienteAlacena({
    required this.id,
    required this.nombre,
    this.marca,
    required this.categoria,
    this.gramosPorcion = 100.0,
    required this.calorias,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    required this.creadoEn,
  });

  String get nombreConMarca {
    final m = marca?.trim();
    if (m != null && m.isNotEmpty) {
      return '$nombre ($m)';
    }
    return nombre;
  }

  String get porcionLabel => '${gramosPorcion.round()}g';

  int get caloriasPor100g {
    if (gramosPorcion <= 0) return calorias;
    return ((calorias * 100) / gramosPorcion).round();
  }

  double get proteinasPor100g {
    if (gramosPorcion <= 0) return proteinas;
    return (proteinas * 100) / gramosPorcion;
  }

  double get carbohidratosPor100g {
    if (gramosPorcion <= 0) return carbohidratos;
    return (carbohidratos * 100) / gramosPorcion;
  }

  double get grasasPor100g {
    if (gramosPorcion <= 0) return grasas;
    return (grasas * 100) / gramosPorcion;
  }

  int calcularCalorias(double gramos) {
    if (gramos <= 0 || gramosPorcion <= 0) return 0;
    return ((calorias * gramos) / gramosPorcion).round();
  }

  double calcularProteinas(double gramos) {
    if (gramos <= 0 || gramosPorcion <= 0) return 0.0;
    return (proteinas * gramos) / gramosPorcion;
  }

  double calcularCarbos(double gramos) {
    if (gramos <= 0 || gramosPorcion <= 0) return 0.0;
    return (carbohidratos * gramos) / gramosPorcion;
  }

  double calcularGrasas(double gramos) {
    if (gramos <= 0 || gramosPorcion <= 0) return 0.0;
    return (grasas * gramos) / gramosPorcion;
  }

  IngredienteAlacena copyWith({
    String? id,
    String? nombre,
    String? marca,
    CategoriaAlacena? categoria,
    double? gramosPorcion,
    int? calorias,
    double? proteinas,
    double? carbohidratos,
    double? grasas,
    DateTime? creadoEn,
  }) {
    return IngredienteAlacena(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      categoria: categoria ?? this.categoria,
      gramosPorcion: gramosPorcion ?? this.gramosPorcion,
      calorias: calorias ?? this.calorias,
      proteinas: proteinas ?? this.proteinas,
      carbohidratos: carbohidratos ?? this.carbohidratos,
      grasas: grasas ?? this.grasas,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredienteAlacena &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'marca': marca,
    'categoriaId': categoria.id,
    'categoriaLabel': categoria.label,
    'categoriaEmoji': categoria.emoji,
    'gramosPorcion': gramosPorcion,
    'calorias': calorias,
    'proteinas': proteinas,
    'carbohidratos': carbohidratos,
    'grasas': grasas,
    'creadoEn': creadoEn.toIso8601String(),
  };

  factory IngredienteAlacena.fromJson(Map<String, dynamic> json) =>
      IngredienteAlacena(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        marca: json['marca'] as String?,
        categoria: CategoriaAlacena(
          id: json['categoriaId'] as String? ?? 'otros',
          label: json['categoriaLabel'] as String? ?? 'Otros',
          emoji: json['categoriaEmoji'] as String? ?? '🧂',
        ),
        gramosPorcion: (json['gramosPorcion'] as num?)?.toDouble() ?? 100.0,
        calorias: (json['calorias'] as num).toInt(),
        proteinas: (json['proteinas'] as num).toDouble(),
        carbohidratos: (json['carbohidratos'] as num).toDouble(),
        grasas: (json['grasas'] as num).toDouble(),
        creadoEn: json['creadoEn'] != null
            ? DateTime.tryParse(json['creadoEn'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
