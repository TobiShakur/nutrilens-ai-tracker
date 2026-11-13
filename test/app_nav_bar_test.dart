import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/shell/presentation/widgets/app_nav_bar.dart';

void main() {
  testWidgets(
    'AppNavBar renders 3 tabs and Scanner FAB with >= 48dp hit targets and fires callbacks',
    (tester) async {
      int? selectedTab;
      var centerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              selectedIndex: 0,
              onItemSelected: (index) => selectedTab = index,
              onCenterTap: () => centerTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Alacena'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      final fabFinder = find.bySemanticsLabel('Escanear plato o cargar comida');
      expect(fabFinder, findsOneWidget);
      final fabSize = tester.getSize(fabFinder);
      expect(fabSize.width, greaterThanOrEqualTo(48));
      expect(fabSize.height, greaterThanOrEqualTo(48));

      final alacenaSize = tester.getSize(find.bySemanticsLabel('Alacena'));
      expect(alacenaSize.width, greaterThanOrEqualTo(48));
      expect(alacenaSize.height, greaterThanOrEqualTo(48));

      await tester.tap(find.text('Alacena'));
      await tester.pump();
      expect(selectedTab, 1);

      await tester.tap(find.text('Perfil'));
      await tester.pump();
      expect(selectedTab, 2);

      await tester.tap(fabFinder);
      await tester.pump();
      expect(centerTapped, isTrue);
    },
  );
}
