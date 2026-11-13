import '../../../../core/failures/scanner_failure.dart';
import '../../domain/entities/meal_health_evaluation.dart';

/// DTO parsing Gemini's `{ healthScore, razonHealthScore }` JSON payload
/// with strict finiteness, range, and length guards.
class MealHealthEvaluationModel {
  static const int maxReasonLength = 280;
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]+');
  static final RegExp _multiWhitespace = RegExp(r'\s+');

  final int healthScore;
  final String razonHealthScore;

  const MealHealthEvaluationModel({
    required this.healthScore,
    required this.razonHealthScore,
  });

  factory MealHealthEvaluationModel.fromJson(Map<String, dynamic> json) {
    final rawScore = json['healthScore'];
    if (rawScore is! num || !rawScore.isFinite) {
      throw const ScannerInvalidResponseFailure();
    }
    final normalizedScore = rawScore.round().clamp(0, 100);

    final rawReason = json['razonHealthScore'];
    if (rawReason is! String) {
      throw const ScannerInvalidResponseFailure();
    }
    final cleanedReason = rawReason
        .replaceAll(_controlChars, ' ')
        .replaceAll(_multiWhitespace, ' ')
        .trim();
    if (cleanedReason.isEmpty) {
      throw const ScannerInvalidResponseFailure();
    }
    final boundedReason = cleanedReason.length > maxReasonLength
        ? '${cleanedReason.substring(0, maxReasonLength - 3)}...'
        : cleanedReason;

    return MealHealthEvaluationModel(
      healthScore: normalizedScore,
      razonHealthScore: boundedReason,
    );
  }

  MealHealthEvaluation toEntity() => MealHealthEvaluation(
    healthScore: healthScore,
    razonHealthScore: razonHealthScore,
  );
}
