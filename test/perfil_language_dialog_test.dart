import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/localization/locale_provider.dart';
import 'package:nutrilens_provider/core/storage/local_storage_service.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/diario_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'package:nutrilens_provider/features/perfil/data/repositories/perfil_repository_impl.dart';
import 'package:nutrilens_provider/features/perfil/presentation/viewmodels/perfil_viewmodel.dart';
import 'package:nutrilens_provider/features/perfil/presentation/views/perfil_screen.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'PerfilScreen renders language selector card at bottom and switches es <-> en via centered Dialog',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.inicializar();
      final localeProvider = LocaleProvider(storageService: storage);
      final diarioVM = DiarioViewModel(repository: DiarioRepositoryImpl());
      final perfilVM = PerfilViewModel(repository: PerfilRepositoryImpl());
      await perfilVM.inicializar(diarioVM.todosLosDias);

      addTearDown(localeProvider.dispose);
      addTearDown(diarioVM.dispose);
      addTearDown(perfilVM.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<DiarioViewModel>.value(value: diarioVM),
            ChangeNotifierProvider<PerfilViewModel>.value(value: perfilVM),
          ],
          child: Consumer<LocaleProvider>(
            builder: (context, localeState, _) => MaterialApp(
              locale: localeState.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const PerfilScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts in Spanish.
      expect(find.text('MI PERFIL & METAS'), findsOneWidget);

      final selectorFinder = find.byKey(const Key('perfil-language-selector'));
      await tester.ensureVisible(selectorFinder);
      await tester.pumpAndSettle();

      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);

      // Tap card -> centered Dialog opens with Español & English.
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Elegir idioma'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Select English -> Dialog closes, locale updates, UI switches to English.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(localeProvider.locale, const Locale('en'));
      expect(storage.obtenerLocale(), 'en');
      expect(find.text('MY PROFILE & GOALS'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      // Re-open Dialog and switch back to Español.
      await tester.ensureVisible(selectorFinder);
      await tester.pumpAndSettle();
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      expect(find.text('Select language'), findsOneWidget);
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(localeProvider.locale, const Locale('es'));
      expect(storage.obtenerLocale(), 'es');
      expect(find.text('MI PERFIL & METAS'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
    },
  );
}
