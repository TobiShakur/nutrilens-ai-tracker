import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/theme/app_colors.dart';
import 'package:nutrilens_provider/features/alacena/data/repositories/alacena_repository_impl.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'package:nutrilens_provider/features/alacena/presentation/views/alacena_screen.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpAlacena(WidgetTester tester, Locale locale) async {
    final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
    addTearDown(alacenaVM.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AlacenaViewModel>.value(
        value: alacenaVM,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const AlacenaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'AlacenaScreen renders high-contrast forestDark CTA card in English',
    (tester) async {
      await pumpAlacena(tester, const Locale('en'));

      expect(find.text('Add new ingredient'), findsOneWidget);

      final ctaFinder = find.byKey(
        const ValueKey('alacena-add-ingredient-cta'),
      );
      expect(ctaFinder, findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: ctaFinder, matching: find.byType(Material)),
      );
      expect(material.color, AppColors.forestDark);
    },
  );

  testWidgets(
    'AlacenaScreen renders high-contrast forestDark CTA card in Spanish',
    (tester) async {
      await pumpAlacena(tester, const Locale('es'));

      expect(find.text('Agregar nuevo ingrediente'), findsOneWidget);

      final ctaFinder = find.byKey(
        const ValueKey('alacena-add-ingredient-cta'),
      );
      expect(ctaFinder, findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: ctaFinder, matching: find.byType(Material)),
      );
      expect(material.color, AppColors.forestDark);
    },
  );
}
