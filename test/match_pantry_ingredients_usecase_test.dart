import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/scanner/domain/usecases/match_pantry_ingredients_usecase.dart';

void main() {
  group('MatchPantryIngredientsUseCase', () {
    final fixedNow = DateTime(2026, 11, 12, 12, 0);
    late MatchPantryIngredientsUseCase useCase;
    late List<IngredienteAlacena> pantry;

    setUp(() {
      useCase = MatchPantryIngredientsUseCase(clock: () => fixedNow);
      pantry = [
        IngredienteAlacena(
          id: 'p_egg',
          nombre: 'Huevos de campo',
          categoria: CategoriaAlacena.proteinas,
          gramosPorcion: 100,
          calorias: 143,
          proteinas: 13.0,
          carbohidratos: 1.0,
          grasas: 10.0,
          creadoEn: fixedNow,
        ),
        IngredienteAlacena(
          id: 'p_bread_1',
          nombre: 'Pan integral',
          marca: 'Fargo',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50,
          calorias: 120,
          proteinas: 4.5,
          carbohidratos: 22.0,
          grasas: 1.5,
          creadoEn: fixedNow,
        ),
        IngredienteAlacena(
          id: 'p_bread_2',
          nombre: 'Pan integral con semillas',
          marca: 'Lactal',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50,
          calorias: 115,
          proteinas: 5.0,
          carbohidratos: 20.0,
          grasas: 1.8,
          creadoEn: fixedNow,
        ),
      ];
    });

    test(
      'links single match, emits conflict on multi-brand match, and keeps AI macros for unmatched',
      () {
        final detected = [
          ComidaIngrediente.manual(
            id: 'raw_0',
            nombre: 'Huevos de campo',
            gramos: 120,
            calorias: 180,
            proteinas: 14,
            carbohidratos: 1,
            grasas: 12,
          ),
          ComidaIngrediente.manual(
            id: 'raw_1',
            nombre: 'Pan integral',
            gramos: 50,
            calorias: 130,
            proteinas: 4,
            carbohidratos: 24,
            grasas: 2,
          ),
          ComidaIngrediente.manual(
            id: 'raw_2',
            nombre: 'Tomate cherry',
            gramos: 80,
            calorias: 16,
            proteinas: 0.8,
            carbohidratos: 3.5,
            grasas: 0.2,
          ),
        ];

        final result = useCase(
          dishName: 'Tostadas con huevo',
          healthScore: 90,
          healthScoreExplanation: 'Equilibrado.',
          detectedIngredients: detected,
          preferirAlacena: true,
          alacenaUsuario: pantry,
        );

        expect(result.esManual, isFalse);
        expect(result.id, 'plato_${fixedNow.microsecondsSinceEpoch}');
        expect(result.ingredientes.length, 3);
        expect(result.ingredientes[0].ingredienteAlacenaId, 'p_egg');
        expect(result.ingredientes[1].ingredienteAlacenaId, 'p_bread_1');
        expect(result.ingredientes[2].ingredienteAlacenaId, isNull);
        expect(
          result.ingredientes[2].id,
          'ci_ai_${fixedNow.microsecondsSinceEpoch}_2',
        );
        expect(result.conflictosMarcas.length, 1);
        expect(result.conflictosMarcas.first.nombreGenerico, 'Pan integral');
        expect(result.conflictosMarcas.first.opcionesAlacena.length, 2);
      },
    );

    test('skips pantry matching when preferirAlacena is false', () {
      final detected = [
        ComidaIngrediente.manual(
          id: 'raw_0',
          nombre: 'Huevos de campo',
          gramos: 100,
          calorias: 150,
          proteinas: 12,
          carbohidratos: 1,
          grasas: 11,
        ),
      ];

      final result = useCase(
        dishName: 'Huevos',
        healthScore: 85,
        healthScoreExplanation: 'Simple.',
        detectedIngredients: detected,
        preferirAlacena: false,
        alacenaUsuario: pantry,
      );

      expect(result.ingredientes.single.ingredienteAlacenaId, isNull);
      expect(result.conflictosMarcas, isEmpty);
    });
  });
}
