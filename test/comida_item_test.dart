import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/diario_dia.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/nivel_score.dart';

void main() {
  group('ComidaItem nullable healthScore & JSON compatibility', () {
    test(
      'defaults to null healthScore and false healthScoreDesactualizado',
      () {
        const meal = ComidaItem(
          id: 'm1',
          titulo: 'Tostadas con palta',
          hora: '08:30',
        );

        expect(meal.healthScore, isNull);
        expect(meal.tieneHealthScore, isFalse);
        expect(meal.tieneExplicacionHealthScore, isFalse);
        expect(meal.healthScoreDesactualizado, isFalse);
      },
    );

    test(
      'fromJson preserves legacy int score and defaults missing/null/non-finite to null',
      () {
        final legacy = ComidaItem.fromJson(const {
          'id': 'c1',
          'titulo': 'Legacy',
          'hora': '12:00',
          'healthScore': 85,
        });
        expect(legacy.healthScore, 85);
        expect(legacy.healthScoreDesactualizado, isFalse);

        final missing = ComidaItem.fromJson(const {
          'id': 'c2',
          'titulo': 'Missing',
          'hora': '12:00',
        });
        expect(missing.healthScore, isNull);

        final nullScore = ComidaItem.fromJson(const {
          'id': 'c3',
          'titulo': 'NullScore',
          'hora': '12:00',
          'healthScore': null,
        });
        expect(nullScore.healthScore, isNull);

        final nanScore = ComidaItem.fromJson(const {
          'id': 'c4',
          'titulo': 'NaNScore',
          'hora': '12:00',
          'healthScore': double.nan,
        });
        expect(nanScore.healthScore, isNull);

        final infScore = ComidaItem.fromJson(const {
          'id': 'c5',
          'titulo': 'InfScore',
          'hora': '12:00',
          'healthScore': double.infinity,
        });
        expect(infScore.healthScore, isNull);

        final clamped = ComidaItem.fromJson(const {
          'id': 'c6',
          'titulo': 'Clamped',
          'hora': '12:00',
          'healthScore': 140.4,
          'healthScoreDesactualizado': true,
        });
        expect(clamped.healthScore, 100);
        expect(clamped.healthScoreDesactualizado, isTrue);

        final clampedLow = ComidaItem.fromJson(const {
          'id': 'c7',
          'titulo': 'ClampedLow',
          'hora': '12:00',
          'healthScore': -12,
        });
        expect(clampedLow.healthScore, 0);
      },
    );

    test('copyWith clear flags clear nullable healthScore and explanation', () {
      const meal = ComidaItem(
        id: 'm1',
        titulo: 'Bowl',
        hora: '13:00',
        healthScore: 90,
        explicacionHealthScore: 'Rico en fibra.',
        healthScoreDesactualizado: true,
      );

      final cleared = meal.copyWith(
        clearHealthScore: true,
        clearExplicacionHealthScore: true,
        healthScoreDesactualizado: false,
      );

      expect(cleared.healthScore, isNull);
      expect(cleared.explicacionHealthScore, isNull);
      expect(cleared.healthScoreDesactualizado, isFalse);
    });
  });

  group('DiarioDia promedioHealthScore with nullable meals', () {
    test('averages only scored meals and ignores null scores', () {
      const dia = DiarioDia(
        diaIndex: 0,
        diaNombre: 'Hoy',
        comidas: [
          ComidaItem(
            id: '1',
            titulo: 'Scored',
            hora: '08:00',
            calorias: 300,
            healthScore: 80,
          ),
          ComidaItem(
            id: '2',
            titulo: 'Unscored',
            hora: '13:00',
            calorias: 450,
            healthScore: null,
          ),
          ComidaItem(
            id: '3',
            titulo: 'Scored 2',
            hora: '20:00',
            calorias: 500,
            healthScore: 90,
          ),
        ],
      );

      expect(dia.tieneComidasConScore, isTrue);
      expect(dia.promedioHealthScore, 85);
      expect(dia.nivelScore, NivelScore.excelente);
    });

    test(
      'returns 0 and NivelScore.sinRegistros when all meals are unscored',
      () {
        const dia = DiarioDia(
          diaIndex: 0,
          diaNombre: 'Hoy',
          comidas: [
            ComidaItem(
              id: '1',
              titulo: 'Unscored',
              hora: '12:00',
              calorias: 400,
            ),
          ],
        );

        expect(dia.tieneComidasConScore, isFalse);
        expect(dia.promedioHealthScore, 0);
        expect(dia.nivelScore, NivelScore.sinRegistros);
      },
    );
  });
}
