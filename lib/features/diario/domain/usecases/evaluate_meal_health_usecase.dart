import '../../../../core/failures/scanner_failure.dart';
import '../entities/meal_health_evaluation.dart';
import '../repositories/meal_health_repository.dart';

/// Validates and sanitizes meal data before delegating Health Score evaluation
/// to [MealHealthRepository].
class EvaluateMealHealthUseCase {
  static const int maxTitleLength = 80;
  static const int maxIngredientNameLength = 60;
  static const int maxIngredientsCount = 30;
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]+');
  static final RegExp _multiWhitespace = RegExp(r'\s+');

  final MealHealthRepository repository;

  const EvaluateMealHealthUseCase({required this.repository});

  Future<MealHealthResult> call(
    MealHealthEvaluationInput input, {
    String languageCode = 'es',
  }) async {
    if (input.ingredientes.isEmpty) {
      return const MealHealthError(ScannerEmptyIngredientsFailure());
    }

    if (!_areTotalsValid(input) ||
        input.ingredientes.any((i) => !_isIngredientValid(i))) {
      return const MealHealthError(ScannerInvalidResponseFailure());
    }

    final isEnglish = languageCode.toLowerCase() == 'en';
    final sanitizedTitle = _sanitizeText(
      input.titulo,
      maxLength: maxTitleLength,
      fallback: isEnglish ? 'Meal' : 'Comida',
    );

    final boundedIngredients = input.ingredientes
        .take(maxIngredientsCount)
        .map(
          (i) => MealHealthIngredientInput(
            nombre: _sanitizeText(
              i.nombre,
              maxLength: maxIngredientNameLength,
              fallback: isEnglish ? 'Ingredient' : 'Alimento',
            ),
            gramos: _round1(i.gramos),
            calorias: i.calorias,
            proteinas: _round1(i.proteinas),
            carbohidratos: _round1(i.carbohidratos),
            grasas: _round1(i.grasas),
          ),
        )
        .toList(growable: false);

    final recomputedCalories = boundedIngredients.fold<int>(
      0,
      (sum, i) => sum + i.calorias,
    );
    final recomputedProtein = _round1(
      boundedIngredients.fold<double>(0.0, (sum, i) => sum + i.proteinas),
    );
    final recomputedCarbs = _round1(
      boundedIngredients.fold<double>(0.0, (sum, i) => sum + i.carbohidratos),
    );
    final recomputedFat = _round1(
      boundedIngredients.fold<double>(0.0, (sum, i) => sum + i.grasas),
    );

    final sanitizedInput = MealHealthEvaluationInput(
      titulo: sanitizedTitle,
      ingredientes: boundedIngredients,
      totalCalorias: recomputedCalories,
      totalProteinas: recomputedProtein,
      totalCarbohidratos: recomputedCarbs,
      totalGrasas: recomputedFat,
    );

    return repository.evaluateMealHealth(
      sanitizedInput,
      languageCode: languageCode,
    );
  }

  static bool _areTotalsValid(MealHealthEvaluationInput input) {
    return input.totalCalorias >= 0 &&
        input.totalProteinas.isFinite &&
        input.totalProteinas >= 0 &&
        input.totalCarbohidratos.isFinite &&
        input.totalCarbohidratos >= 0 &&
        input.totalGrasas.isFinite &&
        input.totalGrasas >= 0;
  }

  static bool _isIngredientValid(MealHealthIngredientInput ingredient) {
    return ingredient.gramos.isFinite &&
        ingredient.gramos >= 0 &&
        ingredient.calorias >= 0 &&
        ingredient.proteinas.isFinite &&
        ingredient.proteinas >= 0 &&
        ingredient.carbohidratos.isFinite &&
        ingredient.carbohidratos >= 0 &&
        ingredient.grasas.isFinite &&
        ingredient.grasas >= 0;
  }

  static double _round1(double value) => double.parse(value.toStringAsFixed(1));

  static String _sanitizeText(
    String raw, {
    required int maxLength,
    required String fallback,
  }) {
    final cleaned = raw
        .replaceAll(_controlChars, ' ')
        .replaceAll(_multiWhitespace, ' ')
        .trim();
    if (cleaned.isEmpty) return fallback;
    if (cleaned.length <= maxLength) return cleaned;
    return cleaned.substring(0, maxLength).trimRight();
  }
}
