import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/plato_detectado.dart';
import 'package:nutrilens_provider/features/scanner/domain/usecases/build_comida_from_plato_usecase.dart';

void main() {
  group('BuildComidaFromPlatoUseCase', () {
    final fixedClock = DateTime(2026, 11, 12, 9, 7);
    final useCase = BuildComidaFromPlatoUseCase(clock: () => fixedClock);

    final sampleIngredient = ComidaIngrediente.manual(
      id: 'ing_1',
      nombre: 'Avena',
      gramos: 60,
      calorias: 220,
      proteinas: 8,
      carbohidratos: 38,
      grasas: 4,
    );

    test('throws ArgumentError when dish has zero ingredients', () {
      final emptyManual = PlatoDetectado.manualEmpty();
      expect(
        () => useCase(
          plato: emptyManual,
          titulo: 'Desayuno',
          tipoComida: 'Desayuno',
        ),
        throwsArgumentError,
      );
    });

    test('normalizes title, type, hour, and omits AI copy on manual meals', () {
      final manualDish = PlatoDetectado.manualEmpty().copyWith(
        ingredientes: [sampleIngredient],
      );

      final item = useCase(
        plato: manualDish,
        titulo: '   ',
        tipoComida: ' desayuno ',
      );

      expect(item.id, 'comida_${fixedClock.microsecondsSinceEpoch}');
      expect(item.titulo, 'Comida');
      expect(item.tipoComida, 'DESAYUNO');
      expect(item.hora, '09:07');
      expect(item.descripcion, isNull);
      expect(item.healthScore, isNull);
      expect(item.explicacionHealthScore, isNull);
      expect(item.healthScoreDesactualizado, isFalse);
      expect(item.calorias, 220);
    });

    test(
      'preserves healthScore, explanation, and stale flag on evaluated manual meals',
      () {
        final evaluatedManual = PlatoDetectado.manualEmpty().copyWith(
          ingredientes: [sampleIngredient],
          healthScore: 86,
          explicacionHealthScore:
              '  Buena fuente de fibra y energía sostenida.  ',
        );

        final item = useCase(
          plato: evaluatedManual,
          titulo: 'Avena matinal',
          tipoComida: 'Desayuno',
          healthScoreDesactualizado: true,
        );

        expect(item.descripcion, isNull);
        expect(item.healthScore, 86);
        expect(
          item.explicacionHealthScore,
          'Buena fuente de fibra y energía sostenida.',
        );
        expect(item.healthScoreDesactualizado, isTrue);
      },
    );

    test(
      'preserves AI dish description and score explanation when not manual',
      () {
        final aiDish = PlatoDetectado(
          id: 'plato_ai',
          nombreSugerido: 'Bowl de avena',
          healthScore: 92,
          explicacionHealthScore: 'Rico en fibra soluble.',
          ingredientes: [sampleIngredient],
        );

        final item = useCase(
          plato: aiDish,
          titulo: 'Desayuno Fit',
          tipoComida: 'Desayuno',
          now: DateTime(2026, 11, 12, 14, 30),
        );

        expect(item.titulo, 'Desayuno Fit');
        expect(item.hora, '14:30');
        expect(item.descripcion, 'Bowl de avena');
        expect(item.healthScore, 92);
        expect(item.explicacionHealthScore, 'Rico en fibra soluble.');
      },
    );
  });
}
