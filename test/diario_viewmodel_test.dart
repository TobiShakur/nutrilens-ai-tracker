import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/diario_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/diario_dia.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/nivel_score.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/diario_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/meal_health_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/health_score_eval_state.dart';

class _SpyDiarioRepository implements DiarioRepository {
  final DiarioRepository _inner = DiarioRepositoryImpl();
  int saveCalls = 0;
  Map<int, DiarioDia>? lastSavedDias;

  @override
  Map<int, DiarioDia> getDiasIniciales() => _inner.getDiasIniciales();

  @override
  Future<void> guardarDias(Map<int, DiarioDia> dias) async {
    saveCalls++;
    lastSavedDias = dias;
  }

  @override
  ComidaItem generarComidaAleatoria(int numeroComida) =>
      _inner.generarComidaAleatoria(numeroComida);
}

class _ControlledHealthRepo implements MealHealthRepository {
  int callCount = 0;
  Future<MealHealthResult> Function(MealHealthEvaluationInput input)?
  onEvaluate;

  @override
  Future<MealHealthResult> evaluateMealHealth(MealHealthEvaluationInput input) {
    callCount++;
    if (onEvaluate != null) {
      return onEvaluate!(input);
    }
    return Future.value(
      const MealHealthSuccess(
        MealHealthEvaluation(
          healthScore: 87,
          razonHealthScore: 'Buen balance entre proteínas y fibra.',
        ),
      ),
    );
  }
}

ComidaItem _comida(String id, int kcal, {int score = 90}) {
  return ComidaItem(
    id: id,
    titulo: 'Comida $id',
    calorias: kcal,
    proteinas: 10,
    grasas: 5,
    carbohidratos: 20,
    healthScore: score,
    hora: '12:00',
  );
}

void main() {
  late DiarioViewModel vm;
  late int notificaciones;

  setUp(() {
    vm = DiarioViewModel(repository: DiarioRepositoryImpl());
    notificaciones = 0;
    vm.addListener(() => notificaciones++);
  });

  group('Estado inicial', () {
    test('Hoy arranca con 3 comidas realistas y los números de la semilla', () {
      final hoy = vm.diaActual;

      expect(vm.diaSeleccionadoIndex, 30);
      expect(hoy.diaNombre, 'Hoy');
      expect(hoy.cantidadComidas, 3);
      expect(hoy.caloriasActuales, 1255);
      expect(hoy.caloriasRestantes, 880);
      expect(hoy.caloriasExtras, 0);
      expect(hoy.ratioVerde, closeTo(1255 / 2135, 0.001));
      expect(hoy.ratioNaranja, 0.0);
      expect(hoy.ratioRojo, 0.0);
      expect(hoy.promedioHealthScore, 96);
      expect(hoy.nivelScore, NivelScore.excelente);
    });
  });

  group('Navegación entre días', () {
    test(
      'diaTieneRacha y rachaDias identifican días cumplidos y racha acumulada en ventana de 35 días (30 atrás + Hoy + 4 adelante)',
      () {
        expect(vm.nombresDias.length, 35);
        expect(vm.rachaDias, 11);
        expect(vm.diaTieneRacha(29), isTrue); // Ayer (~2020 kcal cumplido)
        expect(vm.diaTieneRacha(28), isTrue); // Anteayer (~1980 kcal cumplido)
        expect(
          vm.diaTieneRacha(30),
          isFalse,
        ); // Hoy (1255 kcal, en curso aún no alcanzó meta)
        expect(vm.diaTieneRacha(31), isFalse); // Hoy + 1 (0 kcal)
        expect(vm.diaTieneRacha(32), isFalse); // Hoy + 2 (0 kcal)
        expect(vm.diaTieneRacha(33), isFalse); // Hoy + 3 (0 kcal)
        expect(vm.diaTieneRacha(34), isFalse); // Hoy + 4 (0 kcal)
      },
    );

    test(
      'respeta el día actual real (DateTime.now) y genera 30 días atrás y 4 adelante',
      () {
        final now = DateTime.now();
        final hoyEsperado =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        expect(vm.diaActual.diaNombre, 'Hoy');
        expect(vm.diaActual.fechaIso, hoyEsperado);
        expect(vm.todosLosDias.length, 35);
        expect(vm.todosLosDias.first.diaIndex, 0);
        expect(vm.todosLosDias.last.diaIndex, 34);
      },
    );

    test('seleccionarDia cambia de día y notifica una vez', () {
      vm.seleccionarDia(29);

      expect(vm.diaActual.diaNombre, isNot('Hoy'));
      expect(vm.diaActual.caloriasActuales, greaterThan(1900));
      expect(notificaciones, 1);
    });

    test('seleccionar el mismo día o un índice inválido no notifica', () {
      vm.seleccionarDia(30);
      vm.seleccionarDia(-1);
      vm.seleccionarDia(100);

      expect(notificaciones, 0);
      expect(vm.diaSeleccionadoIndex, 30);
    });
  });

  group('Comandos', () {
    test(
      'agregarComidaAleatoria suma al día seleccionado y devuelve la comida',
      () {
        vm.seleccionarDia(31); // Jueves futuro arranca limpio en 0
        expect(vm.diaActual.cantidadComidas, 0);
        notificaciones = 0;

        final comida = vm.agregarComidaAleatoria();

        expect(vm.diaActual.comidas.last.id, comida.id);
        expect(vm.diaActual.caloriasActuales, comida.calorias);
        expect(notificaciones, 1);
      },
    );

    test('lo que se suma a un día no afecta a los demás', () {
      vm.seleccionarDia(31);
      vm.agregarComidaAleatoria();

      vm.seleccionarDia(30);
      expect(vm.diaActual.caloriasActuales, 1255);

      vm.seleccionarDia(31);
      expect(vm.diaActual.cantidadComidas, 1);
    });

    test('agregar comidas seguidas genera ids únicos', () {
      for (var i = 0; i < 20; i++) {
        vm.agregarComidaAleatoria();
      }
      final ids = vm.diaActual.comidas.map((c) => c.id).toSet();

      expect(ids.length, vm.diaActual.cantidadComidas);
    });

    test(
      'eliminarComida descuenta y devuelve true; id inexistente devuelve false',
      () {
        final id = vm.diaActual.comidas.first.id;

        expect(vm.eliminarComida(id), isTrue);
        expect(vm.diaActual.caloriasActuales, 924);
        expect(vm.diaActual.caloriasRestantes, 1211);

        notificaciones = 0;
        expect(vm.eliminarComida('no_existe'), isFalse);
        expect(notificaciones, 0);
      },
    );

    test(
      'actualizarComida modifica la comida y recalcula los totales del día',
      () {
        final comidaOriginal = vm.diaActual.comidas.first;
        notificaciones = 0;

        final ingredienteExtra = ComidaIngrediente.manual(
          id: 'ci_nuevo',
          nombre: 'Queso rallado',
          gramos: 20.0,
          calorias: 80,
          proteinas: 6.0,
          carbohidratos: 0.5,
          grasas: 6.0,
        );

        final comidaActualizada = comidaOriginal.conIngredienteAgregado(
          ingredienteExtra,
        );
        final resultado = vm.actualizarComida(comidaActualizada);

        expect(resultado, isTrue);
        expect(notificaciones, 1);
        // El total del día subió por 80 kcal
        expect(vm.diaActual.caloriasActuales, 1255 + 80);
        expect(
          vm.diaActual.comidas.first.ingredientes.contains(ingredienteExtra),
          isTrue,
        );

        // Error con id inexistente
        expect(vm.actualizarComida(_comida('inexistente', 100)), isFalse);
      },
    );

    test('ComidaIngrediente conGramos recalcula proporcionalmente', () {
      final ing = ComidaIngrediente.manual(
        id: 'ci_test',
        nombre: 'Avena',
        gramos: 100.0,
        calorias: 370,
        proteinas: 14.0,
        carbohidratos: 60.0,
        grasas: 7.0,
      );

      // Duplicar porción a 200g
      final ing200 = ing.conGramos(200.0);
      expect(ing200.calorias, 740);
      expect(ing200.proteinas, 28.0);
      expect(ing200.carbohidratos, 120.0);
      expect(ing200.grasas, 14.0);

      // Reducir porción a 50g
      final ing50 = ing.conGramos(50.0);
      expect(ing50.calorias, 185);
      expect(ing50.proteinas, 7.0);
      expect(ing50.carbohidratos, 30.0);
      expect(ing50.grasas, 3.5);
    });
  });

  group('Anillo multicapa', () {
    final base = DiarioViewModel(repository: DiarioRepositoryImpl()).diaActual;

    test('exceso simple activa naranja y deja el rojo en cero', () {
      final dia = base.copyWith(comidas: [_comida('a', 2500)]);

      expect(dia.estaExcedido, isTrue);
      expect(dia.caloriasExtras, 365);
      expect(dia.caloriasRestantes, 0);
      expect(dia.ratioVerde, 1.0);
      expect(dia.ratioNaranja, closeTo(365 / 2135, 0.001));
      expect(dia.ratioRojo, 0.0);
    });

    test('exceso doble activa rojo y completa naranja', () {
      final dia = base.copyWith(comidas: [_comida('a', 4800)]);

      expect(dia.estaExcedidoCritico, isTrue);
      expect(dia.ratioNaranja, 1.0);
      expect(dia.ratioRojo, closeTo((4800 - 4270) / 2135, 0.001));
    });

    test('meta exacta llena el verde sin activar naranja', () {
      final dia = base.copyWith(comidas: [_comida('a', 2135)]);

      expect(dia.ratioVerde, 1.0);
      expect(dia.ratioNaranja, 0.0);
      expect(dia.estaExcedido, isFalse);
    });
  });

  group('Health score', () {
    final base = DiarioViewModel(repository: DiarioRepositoryImpl()).diaActual;

    test('día vacío no inventa un score', () {
      final dia = base.copyWith(comidas: []);

      expect(dia.promedioHealthScore, 0);
      expect(dia.nivelScore, NivelScore.sinRegistros);
    });

    test('los niveles respetan los umbrales', () {
      NivelScore nivel(int score) =>
          base.copyWith(comidas: [_comida('a', 100, score: score)]).nivelScore;

      expect(nivel(85), NivelScore.excelente);
      expect(nivel(84), NivelScore.bueno);
      expect(nivel(70), NivelScore.bueno);
      expect(nivel(69), NivelScore.moderado);
      expect(nivel(50), NivelScore.moderado);
      expect(nivel(49), NivelScore.bajo);
    });
  });

  group('On-demand Health Score persistence & concurrency', () {
    test(
      'evaluarHealthScoreComida persists score across day switches and updates diario average',
      () async {
        final spyRepo = _SpyDiarioRepository();
        final healthRepo = _ControlledHealthRepo();
        final completer = Completer<MealHealthResult>();
        healthRepo.onEvaluate = (_) => completer.future;

        final diarioVm = DiarioViewModel(
          repository: spyRepo,
          evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
            repository: healthRepo,
          ),
        );
        addTearDown(diarioVm.dispose);

        final meal = ComidaItem(
          id: 'unscored_1',
          titulo: 'Bowl casero',
          hora: '13:15',
          ingredientes: [
            ComidaIngrediente.manual(
              id: 'i1',
              nombre: 'Pollo',
              gramos: 150,
              calorias: 165,
              proteinas: 31,
              carbohidratos: 0,
              grasas: 3.6,
            ),
          ],
        );
        diarioVm.registrarComida(meal);
        expect(diarioVm.buscarComidaPorId('unscored_1')?.healthScore, isNull);

        final evalFuture = diarioVm.evaluarHealthScoreComida('unscored_1');
        expect(diarioVm.isEvaluatingHealthScore('unscored_1'), isTrue);

        // Double-tap on the same meal is blocked.
        expect(await diarioVm.evaluarHealthScoreComida('unscored_1'), isFalse);
        expect(healthRepo.callCount, 1);

        // Switch to another day while evaluation is in flight.
        diarioVm.seleccionarDia(29);
        expect(diarioVm.diaSeleccionadoIndex, 29);

        completer.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(
              healthScore: 89,
              razonHealthScore: 'Rico en proteínas magras.',
            ),
          ),
        );
        expect(await evalFuture, isTrue);

        final persisted = diarioVm.buscarComidaPorId('unscored_1');
        expect(persisted?.healthScore, 89);
        expect(persisted?.explicacionHealthScore, 'Rico en proteínas magras.');
        expect(persisted?.healthScoreDesactualizado, isFalse);
        expect(
          spyRepo.lastSavedDias?[30]?.comidas.any(
            (c) => c.id == 'unscored_1' && c.healthScore == 89,
          ),
          isTrue,
        );
      },
    );

    test(
      'evaluarHealthScoreComida drops stale result on mid-flight edit or delete and preserves score on error',
      () async {
        final spyRepo = _SpyDiarioRepository();
        final healthRepo = _ControlledHealthRepo();
        final diarioVm = DiarioViewModel(
          repository: spyRepo,
          evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
            repository: healthRepo,
          ),
        );
        addTearDown(diarioVm.dispose);

        final meal = ComidaItem(
          id: 'race_meal',
          titulo: 'Pasta',
          hora: '20:00',
          healthScore: 70,
          explicacionHealthScore: 'Score previo.',
          ingredientes: [
            ComidaIngrediente.manual(
              id: 'i1',
              nombre: 'Fideos',
              gramos: 100,
              calorias: 350,
              proteinas: 12,
              carbohidratos: 70,
              grasas: 2,
            ),
          ],
        );
        diarioVm.registrarComida(meal);

        // Mid-flight edit drops stale response.
        final editCompleter = Completer<MealHealthResult>();
        healthRepo.onEvaluate = (_) => editCompleter.future;
        final pendingEdit = diarioVm.evaluarHealthScoreComida('race_meal');
        diarioVm.actualizarComida(
          meal.copyWith(
            ingredientes: [meal.ingredientes.first.conGramos(200)],
            healthScoreDesactualizado: true,
          ),
        );
        editCompleter.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(
              healthScore: 95,
              razonHealthScore: 'Obsoleta.',
            ),
          ),
        );
        expect(await pendingEdit, isFalse);
        expect(diarioVm.buscarComidaPorId('race_meal')?.healthScore, 70);

        // Error keeps prior score and emits HealthScoreEvalError.
        healthRepo.onEvaluate = (_) async =>
            const MealHealthError(ScannerTimeoutFailure());
        expect(await diarioVm.evaluarHealthScoreComida('race_meal'), isFalse);
        expect(diarioVm.buscarComidaPorId('race_meal')?.healthScore, 70);
        expect(
          diarioVm.healthScoreStateFor('race_meal'),
          isA<HealthScoreEvalError>(),
        );

        // Mid-flight delete ignores result cleanly.
        final delCompleter = Completer<MealHealthResult>();
        healthRepo.onEvaluate = (_) => delCompleter.future;
        final pendingDel = diarioVm.evaluarHealthScoreComida('race_meal');
        diarioVm.eliminarComida('race_meal');
        delCompleter.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(healthScore: 80, razonHealthScore: 'Late'),
          ),
        );
        expect(await pendingDel, isFalse);
        expect(diarioVm.buscarComidaPorId('race_meal'), isNull);
      },
    );
  });
}
