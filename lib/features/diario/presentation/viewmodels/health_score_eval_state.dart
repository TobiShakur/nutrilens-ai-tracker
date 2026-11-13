import 'package:flutter/foundation.dart';
import '../../../../core/failures/scanner_failure.dart';

/// Immutable state machine for on-demand AI Health Score evaluation.
@immutable
sealed class HealthScoreEvalState {
  const HealthScoreEvalState();
}

final class HealthScoreEvalIdle extends HealthScoreEvalState {
  const HealthScoreEvalIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthScoreEvalIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class HealthScoreEvaluating extends HealthScoreEvalState {
  const HealthScoreEvaluating();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthScoreEvaluating;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class HealthScoreEvalSuccess extends HealthScoreEvalState {
  final int healthScore;
  final String razonHealthScore;

  const HealthScoreEvalSuccess({
    required this.healthScore,
    required this.razonHealthScore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthScoreEvalSuccess &&
          healthScore == other.healthScore &&
          razonHealthScore == other.razonHealthScore;

  @override
  int get hashCode => Object.hash(runtimeType, healthScore, razonHealthScore);
}

final class HealthScoreEvalError extends HealthScoreEvalState {
  final String message;
  final ScannerErrorType type;

  const HealthScoreEvalError({required this.message, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthScoreEvalError &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode => Object.hash(runtimeType, message, type);
}

/// Immutable projection consumed by [HealthScoreBadge] and [HealthScoreDetailSheet].
@immutable
class HealthScoreSheetSnapshot {
  final int? healthScore;
  final String? razonHealthScore;
  final bool isStale;
  final bool hasIngredients;
  final HealthScoreEvalState evalState;

  const HealthScoreSheetSnapshot({
    required this.healthScore,
    required this.razonHealthScore,
    required this.isStale,
    required this.hasIngredients,
    required this.evalState,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthScoreSheetSnapshot &&
          healthScore == other.healthScore &&
          razonHealthScore == other.razonHealthScore &&
          isStale == other.isStale &&
          hasIngredients == other.hasIngredients &&
          evalState == other.evalState;

  @override
  int get hashCode => Object.hash(
    healthScore,
    razonHealthScore,
    isStale,
    hasIngredients,
    evalState,
  );
}
