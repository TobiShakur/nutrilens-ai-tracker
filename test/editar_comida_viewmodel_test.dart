import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/meal_health_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/editar_comida_viewmodel.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/health_score_eval_state.dart';

class _ControlledDraftHealthRepo implements MealHealthRepository {
  int callCount = 0;
  Future<MealHealthResult> Function(MealHealthEvaluationInput input)?
  onEvaluate;

  @override
  Future<MealHealthResult> evaluateMealHealth(
    MealHealthEvaluationInput input, {
    String languageCode = 'es',
  }) {
    callCount++;
    if (onEvaluate != null) {
      return onEvaluate!(input);
    }
    return Future.value(
      const MealHealthSuccess(
        MealHealthEvaluation(
          healthScore: 91,
          razonHealthScore: 'Aporte equilibrado de proteínas y carbohidratos.',
        ),
      ),
    );
  }
}

void main() {
  final sampleIngredient = ComidaIngrediente.manual(
    id: 'ing_1',
    nombre: 'Pechuga de pollo',
    gramos: 120,
    calorias: 198,
    proteinas: 37.2,
    carbohidratos: 0,
    grasas: 4.3,
  );

  final pantryEgg = IngredienteAlacena(
    id: 'p_egg',
    nombre: 'Huevo',
    categoria: CategoriaAlacena.proteinas,
    gramosPorcion: 100,
    calorias: 155,
    proteinas: 13,
    carbohidratos: 1.1,
    grasas: 11,
    creadoEn: DateTime(2026, 1, 1),
  );

  group('EditarComidaViewModel', () {
    test(
      'initializes cleanly without mutating original ComidaItem and tracks dirty edits',
      () {
        final original = ComidaItem(
          id: 'meal_1',
          titulo: 'Almuerzo proteico',
          tipoComida: 'ALMUERZO',
          hora: '13:00',
          healthScore: 84,
          explicacionHealthScore: 'Buena densidad proteica.',
          ingredientes: [sampleIngredient],
        );

        final vm = EditarComidaViewModel(
          comida: original,
          evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
            repository: _ControlledDraftHealthRepo(),
          ),
        );
        addTearDown(vm.dispose);

        expect(vm.healthScore, 84);
        expect(vm.healthScoreDesactualizado, isFalse);
        expect(vm.healthScoreSnapshot.isStale, isFalse);

        // Renaming title does not mark nutritional score stale.
        vm.setTitulo('Almuerzo post-entreno');
        expect(vm.healthScoreDesactualizado, isFalse);

        // Adjusting grams marks scored meal stale.
        vm.ajustarGramos(0, 30);
        expect(vm.ingredientes.first.gramos, 150);
        expect(vm.healthScoreDesactualizado, isTrue);
        // Original entity remains untouched until buildUpdatedComida().
        expect(original.healthScoreDesactualizado, isFalse);

        final updated = vm.buildUpdatedComida();
        expect(updated.titulo, 'Almuerzo post-entreno');
        expect(updated.healthScoreDesactualizado, isTrue);
        expect(updated.healthScore, 84);
      },
    );

    test(
      'evaluarHealthScore refreshes draft score, blocks double taps, and preserves on error',
      () async {
        final repo = _ControlledDraftHealthRepo();
        final completer = Completer<MealHealthResult>();
        repo.onEvaluate = (_) => completer.future;

        final original = ComidaItem(
          id: 'meal_2',
          titulo: 'Cena liviana',
          tipoComida: 'CENA',
          hora: '21:00',
          healthScore: 72,
          explicacionHealthScore: 'Puntaje inicial.',
          ingredientes: [sampleIngredient],
        );

        final vm = EditarComidaViewModel(
          comida: original,
          evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
            repository: repo,
          ),
        );
        addTearDown(vm.dispose);

        vm.agregarIngrediente(pantryEgg, 60);
        expect(vm.healthScoreDesactualizado, isTrue);

        final firstCall = vm.evaluarHealthScore();
        expect(vm.healthScoreEvalState, isA<HealthScoreEvaluating>());
        // Double-tap blocked while in flight.
        expect(await vm.evaluarHealthScore(), isFalse);
        expect(repo.callCount, 1);

        completer.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(
              healthScore: 88,
              razonHealthScore: 'Mayor aporte proteico y grasas saludables.',
            ),
          ),
        );
        expect(await firstCall, isTrue);
        expect(vm.healthScore, 88);
        expect(vm.healthScoreDesactualizado, isFalse);
        expect(vm.healthScoreEvalState, isA<HealthScoreEvalSuccess>());

        // Subsequent error keeps refreshed 88 score.
        repo.onEvaluate = (_) async =>
            const MealHealthError(ScannerNetworkFailure());
        vm.fijarGramos(0, 100);
        expect(vm.healthScoreDesactualizado, isTrue);
        expect(await vm.evaluarHealthScore(), isFalse);
        expect(vm.healthScore, 88);
        expect(vm.healthScoreEvalState, isA<HealthScoreEvalError>());

        // Removing all ingredients disables evaluation.
        vm.eliminarIngrediente(1);
        vm.eliminarIngrediente(0);
        expect(vm.ingredientes, isEmpty);
        expect(await vm.evaluarHealthScore(), isFalse);
      },
    );
  });
}
