import '../entities/meal_health_evaluation.dart';

/// Domain contract for on-demand AI nutritional Health Score evaluation.
abstract class MealHealthRepository {
  /// Evaluates nutritional quality of [input] via Gemini 2.5 Flash.
  /// Never throws raw exceptions or returns fake fallback scores.
  Future<MealHealthResult> evaluateMealHealth(
    MealHealthEvaluationInput input, {
    String languageCode = 'es',
  });
}
