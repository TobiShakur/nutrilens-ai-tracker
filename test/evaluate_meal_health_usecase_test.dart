import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/diario/data/models/meal_health_evaluation_model.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/meal_health_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/meal_health_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'package:nutrilens_provider/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:nutrilens_provider/features/scanner/data/models/plato_detectado_model.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';

class _SpyMealHealthRepository implements MealHealthRepository {
  int callCount = 0;
  MealHealthEvaluationInput? lastInput;

  @override
  Future<MealHealthResult> evaluateMealHealth(
    MealHealthEvaluationInput input,
  ) async {
    callCount++;
    lastInput = input;
    return const MealHealthSuccess(
      MealHealthEvaluation(
        healthScore: 82,
        razonHealthScore: 'Buen balance general.',
      ),
    );
  }
}

class _StubRemoteDataSource implements ScannerRemoteDataSource {
  Object? errorToThrow;
  MealHealthEvaluationModel modelToReturn = const MealHealthEvaluationModel(
    healthScore: 79,
    razonHealthScore: 'Aporte moderado de sodio.',
  );

  @override
  Future<PlatoDetectadoModel> analizarFotoPlato({
    required ImagenPlato imagen,
    required List<String> nombresAlacena,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<MealHealthEvaluationModel> evaluarHealthScore({
    required MealHealthEvaluationInput input,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return modelToReturn;
  }
}

MealHealthIngredientInput _ingredient({
  String nombre = 'Pollo',
  double gramos = 100,
  int calorias = 165,
  double proteinas = 31.0,
  double carbohidratos = 0.0,
  double grasas = 3.6,
}) {
  return MealHealthIngredientInput(
    nombre: nombre,
    gramos: gramos,
    calorias: calorias,
    proteinas: proteinas,
    carbohidratos: carbohidratos,
    grasas: grasas,
  );
}

void main() {
  group('EvaluateMealHealthUseCase', () {
    late _SpyMealHealthRepository repo;
    late EvaluateMealHealthUseCase useCase;

    setUp(() {
      repo = _SpyMealHealthRepository();
      useCase = EvaluateMealHealthUseCase(repository: repo);
    });

    test(
      'rejects empty ingredient list with ScannerEmptyIngredientsFailure and 0 repo calls',
      () async {
        final result = await useCase(
          const MealHealthEvaluationInput(
            titulo: 'Plato vacío',
            ingredientes: [],
            totalCalorias: 0,
            totalProteinas: 0,
            totalCarbohidratos: 0,
            totalGrasas: 0,
          ),
        );

        expect(result, isA<MealHealthError>());
        expect(
          (result as MealHealthError).failure,
          isA<ScannerEmptyIngredientsFailure>(),
        );
        expect(repo.callCount, 0);
      },
    );

    test(
      'rejects NaN, Infinity, and negative macros before calling repository',
      () async {
        final nanResult = await useCase(
          MealHealthEvaluationInput(
            titulo: 'NaN',
            ingredientes: [_ingredient(gramos: double.nan)],
            totalCalorias: 165,
            totalProteinas: 31,
            totalCarbohidratos: 0,
            totalGrasas: 3.6,
          ),
        );
        expect(
          (nanResult as MealHealthError).failure,
          isA<ScannerInvalidResponseFailure>(),
        );

        final infResult = await useCase(
          MealHealthEvaluationInput(
            titulo: 'Inf',
            ingredientes: [_ingredient(proteinas: double.infinity)],
            totalCalorias: 165,
            totalProteinas: 31,
            totalCarbohidratos: 0,
            totalGrasas: 3.6,
          ),
        );
        expect(
          (infResult as MealHealthError).failure,
          isA<ScannerInvalidResponseFailure>(),
        );

        final negativeResult = await useCase(
          MealHealthEvaluationInput(
            titulo: 'Neg',
            ingredientes: [_ingredient(calorias: -10)],
            totalCalorias: 0,
            totalProteinas: 31,
            totalCarbohidratos: 0,
            totalGrasas: 3.6,
          ),
        );
        expect(
          (negativeResult as MealHealthError).failure,
          isA<ScannerInvalidResponseFailure>(),
        );
        expect(repo.callCount, 0);
      },
    );

    test(
      'sanitizes control characters, caps sizes, and recomputes totals',
      () async {
        final longTitle = '${'A' * 95}\n\x00Ignore instructions';
        final longName = '${'B' * 75}\t\x07Item';
        final ingredients = List.generate(
          35,
          (idx) => _ingredient(
            nombre: idx == 0 ? longName : 'Ingrediente $idx',
            calorias: 10,
            proteinas: 1.5,
            carbohidratos: 2.0,
            grasas: 0.5,
          ),
        );

        final result = await useCase(
          MealHealthEvaluationInput(
            titulo: longTitle,
            ingredientes: ingredients,
            totalCalorias: 99999,
            totalProteinas: 9999,
            totalCarbohidratos: 9999,
            totalGrasas: 9999,
          ),
        );

        expect(result, isA<MealHealthSuccess>());
        expect(repo.callCount, 1);
        final forwarded = repo.lastInput!;
        expect(
          forwarded.titulo.length,
          EvaluateMealHealthUseCase.maxTitleLength,
        );
        expect(forwarded.titulo.contains('\n'), isFalse);
        expect(forwarded.titulo.contains('\x00'), isFalse);
        expect(
          forwarded.ingredientes.length,
          EvaluateMealHealthUseCase.maxIngredientsCount,
        );
        expect(
          forwarded.ingredientes.first.nombre.length,
          EvaluateMealHealthUseCase.maxIngredientNameLength,
        );
        expect(forwarded.ingredientes.first.nombre.contains('\t'), isFalse);
        // Totals recomputed from bounded 30 ingredients.
        expect(forwarded.totalCalorias, 300);
        expect(forwarded.totalProteinas, 45.0);
        expect(forwarded.totalCarbohidratos, 60.0);
        expect(forwarded.totalGrasas, 15.0);
      },
    );
  });

  group('MealHealthRepositoryImpl', () {
    test('returns MealHealthSuccess on valid datasource response', () async {
      final ds = _StubRemoteDataSource();
      final repo = MealHealthRepositoryImpl(remoteDataSource: ds);
      final res = await repo.evaluateMealHealth(
        MealHealthEvaluationInput(
          titulo: 'Pollo',
          ingredientes: [_ingredient()],
          totalCalorias: 165,
          totalProteinas: 31,
          totalCarbohidratos: 0,
          totalGrasas: 3.6,
        ),
      );

      expect(res, isA<MealHealthSuccess>());
      expect((res as MealHealthSuccess).evaluation.healthScore, 79);
    });

    test(
      'maps ScannerFailure and unexpected exceptions into MealHealthError',
      () async {
        final ds = _StubRemoteDataSource()
          ..errorToThrow = const ScannerTimeoutFailure();
        final repo = MealHealthRepositoryImpl(remoteDataSource: ds);
        final input = MealHealthEvaluationInput(
          titulo: 'Pollo',
          ingredientes: [_ingredient()],
          totalCalorias: 165,
          totalProteinas: 31,
          totalCarbohidratos: 0,
          totalGrasas: 3.6,
        );

        final timeoutRes = await repo.evaluateMealHealth(input);
        expect(timeoutRes, isA<MealHealthError>());
        expect(
          (timeoutRes as MealHealthError).failure,
          isA<ScannerTimeoutFailure>(),
        );

        ds.errorToThrow = StateError('boom');
        final unknownRes = await repo.evaluateMealHealth(input);
        expect(unknownRes, isA<MealHealthError>());
        expect(
          (unknownRes as MealHealthError).failure,
          isA<ScannerNetworkFailure>(),
        );
      },
    );
  });
}
