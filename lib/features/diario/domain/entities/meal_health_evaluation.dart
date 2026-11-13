import 'package:flutter/foundation.dart';
import '../../../../core/failures/scanner_failure.dart';
import '../../../scanner/domain/entities/plato_detectado.dart';
import 'comida_item.dart';

/// Sanitized ingredient payload sent to the AI Health Score evaluator.
@immutable
class MealHealthIngredientInput {
  final String nombre;
  final double gramos;
  final int calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;

  const MealHealthIngredientInput({
    required this.nombre,
    required this.gramos,
    required this.calorias,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealHealthIngredientInput &&
          nombre == other.nombre &&
          gramos == other.gramos &&
          calorias == other.calorias &&
          proteinas == other.proteinas &&
          carbohidratos == other.carbohidratos &&
          grasas == other.grasas;

  @override
  int get hashCode =>
      Object.hash(nombre, gramos, calorias, proteinas, carbohidratos, grasas);
}

/// Sanitized meal input for text-only AI Health Score evaluation.
@immutable
class MealHealthEvaluationInput {
  final String titulo;
  final List<MealHealthIngredientInput> ingredientes;
  final int totalCalorias;
  final double totalProteinas;
  final double totalCarbohidratos;
  final double totalGrasas;

  const MealHealthEvaluationInput({
    required this.titulo,
    required this.ingredientes,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarbohidratos,
    required this.totalGrasas,
  });

  factory MealHealthEvaluationInput.fromComidaItem(
    ComidaItem item, {
    String? tituloOverride,
  }) {
    final effectiveTitle =
        (tituloOverride != null && tituloOverride.trim().isNotEmpty)
        ? tituloOverride
        : item.titulo;
    return MealHealthEvaluationInput(
      titulo: effectiveTitle,
      ingredientes: item.ingredientes
          .map(
            (i) => MealHealthIngredientInput(
              nombre: i.nombreConMarca,
              gramos: i.gramos,
              calorias: i.calorias,
              proteinas: i.proteinas,
              carbohidratos: i.carbohidratos,
              grasas: i.grasas,
            ),
          )
          .toList(growable: false),
      totalCalorias: item.calorias,
      totalProteinas: item.proteinas,
      totalCarbohidratos: item.carbohidratos,
      totalGrasas: item.grasas,
    );
  }

  factory MealHealthEvaluationInput.fromPlatoDetectado(
    PlatoDetectado plato, {
    String? tituloOverride,
  }) {
    final effectiveTitle =
        (tituloOverride != null && tituloOverride.trim().isNotEmpty)
        ? tituloOverride
        : plato.nombreSugerido;
    return MealHealthEvaluationInput(
      titulo: effectiveTitle,
      ingredientes: plato.ingredientes
          .map(
            (i) => MealHealthIngredientInput(
              nombre: i.nombreConMarca,
              gramos: i.gramos,
              calorias: i.calorias,
              proteinas: i.proteinas,
              carbohidratos: i.carbohidratos,
              grasas: i.grasas,
            ),
          )
          .toList(growable: false),
      totalCalorias: plato.totalCalorias,
      totalProteinas: plato.totalProteinas,
      totalCarbohidratos: plato.totalCarbos,
      totalGrasas: plato.totalGrasas,
    );
  }

  /// Deterministic fingerprint used to drop stale in-flight AI responses
  /// if ingredients, portions, or meal title changed mid-request.
  String computeFingerprint() {
    final buffer = StringBuffer(titulo.trim().toLowerCase());
    for (final ing in ingredientes) {
      buffer
        ..write('|')
        ..write(ing.nombre.trim().toLowerCase())
        ..write(':')
        ..write(ing.gramos.toStringAsFixed(2))
        ..write(':')
        ..write(ing.calorias)
        ..write(':')
        ..write(ing.proteinas.toStringAsFixed(1))
        ..write(':')
        ..write(ing.carbohidratos.toStringAsFixed(1))
        ..write(':')
        ..write(ing.grasas.toStringAsFixed(1));
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealHealthEvaluationInput &&
          titulo == other.titulo &&
          totalCalorias == other.totalCalorias &&
          totalProteinas == other.totalProteinas &&
          totalCarbohidratos == other.totalCarbohidratos &&
          totalGrasas == other.totalGrasas &&
          listEquals(ingredientes, other.ingredientes);

  @override
  int get hashCode => Object.hash(
    titulo,
    totalCalorias,
    totalProteinas,
    totalCarbohidratos,
    totalGrasas,
    Object.hashAll(ingredientes),
  );
}

/// Validated AI nutritional evaluation returned by [MealHealthRepository].
@immutable
class MealHealthEvaluation {
  final int healthScore;
  final String razonHealthScore;

  const MealHealthEvaluation({
    required this.healthScore,
    required this.razonHealthScore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealHealthEvaluation &&
          healthScore == other.healthScore &&
          razonHealthScore == other.razonHealthScore;

  @override
  int get hashCode => Object.hash(healthScore, razonHealthScore);
}

/// Typed outcome for [MealHealthRepository.evaluateMealHealth].
@immutable
sealed class MealHealthResult {
  const MealHealthResult();
}

final class MealHealthSuccess extends MealHealthResult {
  final MealHealthEvaluation evaluation;
  const MealHealthSuccess(this.evaluation);
}

final class MealHealthError extends MealHealthResult {
  final ScannerFailure failure;
  const MealHealthError(this.failure);
}
