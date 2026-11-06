import 'package:flutter/foundation.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import 'alimento_conflicto_marca.dart';

/// Resultado del procesamiento visual de un plato por parte de la IA
@immutable
class PlatoDetectado {
  final String id;
  final String nombreSugerido;
  final List<ComidaIngrediente> ingredientes;
  final int healthScore;
  final String explicacionHealthScore;
  final List<AlimentoConflictoMarca> conflictosMarcas;

  const PlatoDetectado({
    required this.id,
    required this.nombreSugerido,
    required this.ingredientes,
    this.healthScore = 88,
    this.explicacionHealthScore =
        'Buen balance de nutrientes y alimentos frescos.',
    this.conflictosMarcas = const [],
  });

  bool get tieneConflictosMarcas => conflictosMarcas.isNotEmpty;

  int get totalCalorias => ingredientes.fold(0, (acc, i) => acc + i.calorias);

  double get totalProteinas => double.parse(
    ingredientes.fold(0.0, (acc, i) => acc + i.proteinas).toStringAsFixed(1),
  );

  double get totalCarbos => double.parse(
    ingredientes
        .fold(0.0, (acc, i) => acc + i.carbohidratos)
        .toStringAsFixed(1),
  );

  double get totalGrasas => double.parse(
    ingredientes.fold(0.0, (acc, i) => acc + i.grasas).toStringAsFixed(1),
  );

  PlatoDetectado copyWith({
    String? id,
    String? nombreSugerido,
    List<ComidaIngrediente>? ingredientes,
    int? healthScore,
    String? explicacionHealthScore,
    List<AlimentoConflictoMarca>? conflictosMarcas,
  }) {
    return PlatoDetectado(
      id: id ?? this.id,
      nombreSugerido: nombreSugerido ?? this.nombreSugerido,
      ingredientes: ingredientes ?? this.ingredientes,
      healthScore: healthScore ?? this.healthScore,
      explicacionHealthScore:
          explicacionHealthScore ?? this.explicacionHealthScore,
      conflictosMarcas: conflictosMarcas ?? this.conflictosMarcas,
    );
  }
}
