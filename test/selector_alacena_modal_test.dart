import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:nutrilens_provider/features/alacena/data/repositories/alacena_repository_impl.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'package:nutrilens_provider/features/alacena/presentation/widgets/selector_alacena_modal.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'SelectorAlacenaModal filters locally without mutating AlacenaViewModel state',
    (tester) async {
      final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
      addTearDown(alacenaVM.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AlacenaViewModel>.value(
          value: alacenaVM,
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SelectorAlacenaModal.show(context),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Type a search query inside the modal.
      await tester.enterText(find.byType(TextField), 'palta');
      await tester.pumpAndSettle();
      expect(alacenaVM.busquedaQuery, isEmpty);

      // Select a category chip inside the modal.
      await tester.tap(find.text('Proteínas'));
      await tester.pumpAndSettle();
      expect(alacenaVM.categoriaSeleccionada, CategoriaAlacena.todos);
    },
  );
}
