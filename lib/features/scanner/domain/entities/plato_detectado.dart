import 'package:flutter/foundation.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import 'alimento_conflicto_marca.dart';

/// Result of AI visual dish analysis or manual meal composition.
@immutable
class PlatoDetectado {
  final String id;
  final String nombreSugerido;
  final List<ComidaIngrediente> ingredientes;
  final int? healthScore;
  final String? explicacionHealthScore;
  final List<AlimentoConflictoMarca> conflictosMarcas;
  final bool esManual;

  const PlatoDetectado({
    required this.id,
    required this.nombreSugerido,
    required this.ingredientes,
    this.healthScore,
    this.explicacionHealthScore,
    this.conflictosMarcas = const [],
    this.esManual = false,
  });

  /// Creates an empty dish for manual pantry-based meal assembly without a photo.
  factory PlatoDetectado.manualEmpty({String? id}) {
    return PlatoDetectado(
      id: id ?? 'manual_${DateTime.now().microsecondsSinceEpoch}',
      nombreSugerido: 'Armado manual',
      ingredientes: const [],
      healthScore: null,
      explicacionHealthScore: null,
      conflictosMarcas: const [],
      esManual: true,
    );
  }

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
    bool clearHealthScore = false,
    String? explicacionHealthScore,
    bool clearExplicacionHealthScore = false,
    List<AlimentoConflictoMarca>? conflictosMarcas,
    bool? esManual,
  }) {
    return PlatoDetectado(
      id: id ?? this.id,
      nombreSugerido: nombreSugerido ?? this.nombreSugerido,
      ingredientes: ingredientes ?? this.ingredientes,
      healthScore: clearHealthScore ? null : (healthScore ?? this.healthScore),
      explicacionHealthScore: clearExplicacionHealthScore
          ? null
          : (explicacionHealthScore ?? this.explicacionHealthScore),
      conflictosMarcas: conflictosMarcas ?? this.conflictosMarcas,
      esManual: esManual ?? this.esManual,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatoDetectado &&
          id == other.id &&
          nombreSugerido == other.nombreSugerido &&
          healthScore == other.healthScore &&
          explicacionHealthScore == other.explicacionHealthScore &&
          esManual == other.esManual &&
          listEquals(ingredientes, other.ingredientes) &&
          listEquals(conflictosMarcas, other.conflictosMarcas);

  @override
  int get hashCode => Object.hash(
    id,
    nombreSugerido,
    healthScore,
    explicacionHealthScore,
    esManual,
    Object.hashAll(ingredientes),
    Object.hashAll(conflictosMarcas),
  );
}
