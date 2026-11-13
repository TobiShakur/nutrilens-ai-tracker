import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:nutrilens_provider/core/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'package:nutrilens_provider/features/alacena/data/repositories/alacena_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/diario_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/meal_health_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/editar_comida_viewmodel.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/health_score_eval_state.dart';
import 'package:nutrilens_provider/features/diario/presentation/widgets/detalle_comida_sheet.dart';
import 'package:nutrilens_provider/features/diario/presentation/widgets/editar_comida_sheet.dart';
import 'package:nutrilens_provider/features/diario/presentation/widgets/health_score_badge.dart';
import 'package:nutrilens_provider/features/diario/presentation/widgets/health_score_detail_sheet.dart';
import 'package:nutrilens_provider/features/diario/presentation/widgets/meal_card_widget.dart';
import 'package:provider/provider.dart';

class _WidgetMealHealthRepo implements MealHealthRepository {
  int calls = 0;
  Future<MealHealthResult> Function(MealHealthEvaluationInput input)?
  onEvaluate;

  @override
  Future<MealHealthResult> evaluateMealHealth(
    MealHealthEvaluationInput input, {
    String languageCode = 'es',
  }) {
    calls++;
    if (onEvaluate != null) {
      return onEvaluate!(input);
    }
    return Future.value(
      const MealHealthSuccess(
        MealHealthEvaluation(
          healthScore: 91,
          razonHealthScore:
              'Muy buen balance proteico y aporte moderado de grasas.',
        ),
      ),
    );
  }
}

void main() {
  group('HealthScoreBadge', () {
    testWidgets(
      'renders all 5 visual states and guarantees >= 44x44 touch target',
      (tester) async {
        int taps = 0;

        // 1. Unscored (?/100)
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: HealthScoreBadge(healthScore: null, onTap: () => taps++),
              ),
            ),
          ),
        );
        expect(find.text('?/100'), findsOneWidget);
        final size = tester.getSize(find.byType(HealthScoreBadge));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
        await tester.tap(find.byType(HealthScoreBadge));
        expect(taps, 1);

        // 2. Loading (Calculando, taps disabled)
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: HealthScoreBadge(
                  healthScore: null,
                  isLoading: true,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Calculando'), findsOneWidget);
        await tester.tap(find.byType(HealthScoreBadge));
        expect(taps, 1);

        // 3. Fresh scored
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: HealthScoreBadge(healthScore: 88, onTap: () => taps++),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('88/100'), findsOneWidget);

        // 4. Stale scored
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: HealthScoreBadge(
                  healthScore: 76,
                  isStale: true,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('76/100'), findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

        // 5. Error state
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: HealthScoreBadge(
                  healthScore: 76,
                  hasError: true,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      },
    );
  });

  group('HealthScoreDetailSheet', () {
    testWidgets(
      'auto-triggers evaluation on open when unscored with ingredients and lays out cleanly at 360px',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final notifier = ValueNotifier<HealthScoreSheetSnapshot>(
          const HealthScoreSheetSnapshot(
            healthScore: null,
            razonHealthScore: null,
            isStale: false,
            hasIngredients: true,
            evalState: HealthScoreEvalIdle(),
          ),
        );
        addTearDown(notifier.dispose);

        int evaluateCalls = 0;
        final completer = Completer<bool>();

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: HealthScoreDetailSheet(
                listenable: notifier,
                readSnapshot: () => notifier.value,
                onEvaluate: () {
                  evaluateCalls++;
                  notifier.value = const HealthScoreSheetSnapshot(
                    healthScore: null,
                    razonHealthScore: null,
                    isStale: false,
                    hasIngredients: true,
                    evalState: HealthScoreEvaluating(),
                  );
                  return completer.future;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(evaluateCalls, 1);

        notifier.value = const HealthScoreSheetSnapshot(
          healthScore: 90,
          razonHealthScore: 'Rico en proteínas y fibra vegetal.',
          isStale: false,
          hasIngredients: true,
          evalState: HealthScoreEvalSuccess(
            healthScore: 90,
            razonHealthScore: 'Rico en proteínas y fibra vegetal.',
          ),
        );
        completer.complete(true);
        await tester.pumpAndSettle();

        expect(find.text('90'), findsOneWidget);
        expect(find.text('Rico en proteínas y fibra vegetal.'), findsOneWidget);
        expect(find.text('Entendido'), findsOneWidget);
        expect(find.text('Recalcular'), findsOneWidget);
      },
    );

    testWidgets(
      'disables CTA when no ingredients, highlights Recalcular puntaje when stale, and offers Reintentar on error',
      (tester) async {
        final emptyNotifier = ValueNotifier<HealthScoreSheetSnapshot>(
          const HealthScoreSheetSnapshot(
            healthScore: null,
            razonHealthScore: null,
            isStale: false,
            hasIngredients: false,
            evalState: HealthScoreEvalIdle(),
          ),
        );
        addTearDown(emptyNotifier.dispose);

        int emptyCalls = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: HealthScoreDetailSheet(
                listenable: emptyNotifier,
                readSnapshot: () => emptyNotifier.value,
                onEvaluate: () async {
                  emptyCalls++;
                  return false;
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(emptyCalls, 0);
        expect(find.text('Calcular puntaje'), findsOneWidget);

        // Stale state highlights Recalcular puntaje
        final staleNotifier = ValueNotifier<HealthScoreSheetSnapshot>(
          const HealthScoreSheetSnapshot(
            healthScore: 74,
            razonHealthScore: 'Puntaje previo.',
            isStale: true,
            hasIngredients: true,
            evalState: HealthScoreEvalIdle(),
          ),
        );
        addTearDown(staleNotifier.dispose);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: HealthScoreDetailSheet(
                listenable: staleNotifier,
                readSnapshot: () => staleNotifier.value,
                onEvaluate: () async => true,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Recalcular puntaje'), findsOneWidget);

        // Error state keeps prior score & renders Reintentar
        staleNotifier.value = const HealthScoreSheetSnapshot(
          healthScore: 74,
          razonHealthScore: 'Puntaje previo.',
          isStale: true,
          hasIngredients: true,
          evalState: HealthScoreEvalError(
            message: 'Sin conexión para evaluar.',
            type: ScannerErrorType.network,
          ),
        );
        await tester.pump();
        expect(find.text('Reintentar'), findsOneWidget);
        expect(
          find.text(
            'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.',
          ),
          findsOneWidget,
        );
        expect(find.text('Puntaje actual conservado: 74/100'), findsOneWidget);
      },
    );
  });

  group(
    'Integration inside MealCardWidget, DetalleComidaSheet & EditarComidaSheet',
    () {
      testWidgets('MealCardWidget renders ?/100 and invokes onScoreTap', (
        tester,
      ) async {
        int scoreTaps = 0;
        const unscored = ComidaItem(
          id: 'card_1',
          titulo: 'Bowl sin score',
          hora: '12:30',
          calorias: 350,
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: MealCardWidget(
                comida: unscored,
                onDelete: () {},
                onScoreTap: () => scoreTaps++,
              ),
            ),
          ),
        );

        expect(find.text('?/100'), findsOneWidget);
        await tester.tap(find.byType(HealthScoreBadge));
        expect(scoreTaps, 1);
      });

      testWidgets(
        'DetalleComidaSheet evaluates unscored meal via HealthScoreDetailSheet and persists into DiarioViewModel',
        (tester) async {
          final repo = _WidgetMealHealthRepo();
          final diarioVm = DiarioViewModel(
            repository: DiarioRepositoryImpl(),
            evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
              repository: repo,
            ),
          );
          addTearDown(diarioVm.dispose);

          final meal = ComidaItem(
            id: 'detalle_unscored',
            titulo: 'Pollo con arroz',
            hora: '13:15',
            ingredientes: [
              ComidaIngrediente.manual(
                id: 'i1',
                nombre: 'Pollo',
                gramos: 150,
                calorias: 248,
                proteinas: 46,
                carbohidratos: 0,
                grasas: 5,
              ),
            ],
          );
          diarioVm.registrarComida(meal);

          await tester.pumpWidget(
            ChangeNotifierProvider<DiarioViewModel>.value(
              value: diarioVm,
              child: MaterialApp(
                locale: const Locale('es'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: Scaffold(
                  body: DetalleComidaSheet(comida: meal, onDelete: () {}),
                ),
              ),
            ),
          );

          expect(find.text('?/100'), findsOneWidget);
          await tester.tap(find.byType(HealthScoreBadge));
          await tester.pumpAndSettle();

          expect(repo.calls, 1);
          expect(find.text('91'), findsOneWidget);
          expect(
            diarioVm.buscarComidaPorId('detalle_unscored')?.healthScore,
            91,
          );
        },
      );

      testWidgets(
        'EditarComidaSheet edits grams via dialog without leaks, marks stale, and saves to DiarioViewModel',
        (tester) async {
          final repo = _WidgetMealHealthRepo();
          final diarioVm = DiarioViewModel(
            repository: DiarioRepositoryImpl(),
            evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
              repository: repo,
            ),
          );
          addTearDown(diarioVm.dispose);

          final alacenaVm = AlacenaViewModel(
            repository: AlacenaRepositoryImpl(),
          );
          addTearDown(alacenaVm.dispose);

          final meal = ComidaItem(
            id: 'edit_1',
            titulo: 'Bowl test',
            tipoComida: 'ALMUERZO',
            hora: '14:00',
            healthScore: 80,
            explicacionHealthScore: 'Score inicial.',
            ingredientes: [
              ComidaIngrediente.manual(
                id: 'i1',
                nombre: 'Pollo grillado',
                gramos: 100,
                calorias: 165,
                proteinas: 31,
                carbohidratos: 0,
                grasas: 3.6,
              ),
            ],
          );
          diarioVm.registrarComida(meal);

          final draftVm = EditarComidaViewModel(
            comida: meal,
            evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
              repository: repo,
            ),
          );
          addTearDown(draftVm.dispose);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<DiarioViewModel>.value(value: diarioVm),
                ChangeNotifierProvider<AlacenaViewModel>.value(
                  value: alacenaVm,
                ),
              ],
              child: MaterialApp(
                locale: const Locale('es'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => EditarComidaSheet.show(
                        ctx,
                        comida: meal,
                        viewModelOverride: draftVm,
                      ),
                      child: const Text('Abrir editor'),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Abrir editor'));
          await tester.pumpAndSettle();

          // Tap manual grams chip to open _EditGramsDialog and change to 180g.
          await tester.tap(find.text('100g'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).last, '180');
          await tester.tap(find.text('Aplicar'));
          await tester.pumpAndSettle();

          expect(draftVm.healthScoreDesactualizado, isTrue);
          expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
          // Original DiarioViewModel meal is NOT mutated yet.
          expect(
            diarioVm.buscarComidaPorId('edit_1')?.healthScoreDesactualizado,
            isFalse,
          );

          // Save changes to DiarioViewModel.
          await tester.tap(find.text('Guardar cambios'));
          await tester.pumpAndSettle();

          final saved = diarioVm.buscarComidaPorId('edit_1')!;
          expect(saved.ingredientes.first.gramos, 180);
          expect(saved.healthScoreDesactualizado, isTrue);
        },
      );
    },
  );
}
