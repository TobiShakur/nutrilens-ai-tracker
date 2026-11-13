import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/widgets/desktop_wrapper.dart';

void main() {
  const stackPills = [
    'Clean Architecture',
    'MVVM + Provider',
    'Dart 3 Sealed States',
    '133 Unit & Widget Tests',
    'Gemini 2.5 Flash Vision',
    'Open Food Facts API v2',
    'Pantry-First Macro Matching',
  ];

  Future<void> pumpWithViewport(
    WidgetTester tester, {
    required Size viewport,
    required Widget child,
    void Function(String url)? onLinkTap,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DesktopWrapper(onLinkTap: onLinkTap, child: child),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Mobile viewport (390x844 < 860px) renders full-screen child without showcase chrome',
    (tester) async {
      const childKey = Key('live-app-child');

      await pumpWithViewport(
        tester,
        viewport: const Size(390, 844),
        child: const SizedBox.expand(key: childKey),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(childKey), findsOneWidget);
      expect(tester.getSize(find.byKey(childKey)), const Size(390, 844));
      expect(find.text('Mobile Engineering Showcase'), findsNothing);
      expect(find.text('Interactive Live Demo'), findsNothing);
      expect(find.text('Tobías Gutiérrez'), findsNothing);
    },
  );

  testWidgets(
    'Tablet boundary (859x800 < 860px) still renders pure full-screen child',
    (tester) async {
      const childKey = Key('tablet-child');

      await pumpWithViewport(
        tester,
        viewport: const Size(859, 800),
        child: const SizedBox.expand(key: childKey),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(childKey)), const Size(859, 800));
      expect(find.text('Mobile Engineering Showcase'), findsNothing);
      expect(find.text('Interactive Live Demo'), findsNothing);
      expect(find.text('Tobías Gutiérrez'), findsNothing);
    },
  );

  for (final size in const [Size(860, 640), Size(1280, 720)]) {
    testWidgets(
      'Compact laptop desktop (${size.width.toInt()}x${size.height.toInt()}) renders full showcase and child with zero overflow',
      (tester) async {
        const childKey = Key('desktop-live-child');

        await pumpWithViewport(
          tester,
          viewport: size,
          child: const ColoredBox(
            key: childKey,
            color: Colors.white,
            child: Center(child: Text('Live App Content')),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(childKey), findsOneWidget);
        expect(find.text('Live App Content'), findsOneWidget);
        expect(find.text('Mobile Engineering Showcase'), findsOneWidget);
        expect(find.text('NutriLens AI'), findsOneWidget);
        expect(find.text('Tobías Gutiérrez'), findsOneWidget);
        expect(find.text('Mobile Software Engineer · FIUBA'), findsOneWidget);

        for (final pill in stackPills) {
          expect(find.text(pill), findsOneWidget);
        }

        expect(find.text('Interactive Live Demo'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(
          find.textContaining('Fototeca', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('?/100', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Agregar nuevo ingrediente', findRichText: true),
          findsOneWidget,
        );

        expect(find.text('github.com/TobiShakur'), findsOneWidget);
        expect(find.text('LinkedIn'), findsOneWidget);
        expect(find.text('tobigutierrez26@gmail.com'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Wide desktop (1440x900) isolates child MediaQuery width to 390px and uses Clip.antiAlias',
    (tester) async {
      Size? reportedChildSize;

      await pumpWithViewport(
        tester,
        viewport: const Size(1440, 900),
        child: Builder(
          builder: (childContext) {
            reportedChildSize = MediaQuery.sizeOf(childContext);
            return const SizedBox.expand();
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(reportedChildSize, isNotNull);
      expect(reportedChildSize!.width, 390.0);
      expect(reportedChildSize!.height, inInclusiveRange(680.0, 800.0));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.clipBehavior, Clip.antiAlias);
    },
  );

  testWidgets(
    'Clickable links invoke callback with exact verified GitHub, LinkedIn, and mailto URLs',
    (tester) async {
      final tappedUrls = <String>[];

      await pumpWithViewport(
        tester,
        viewport: const Size(1440, 900),
        onLinkTap: tappedUrls.add,
        child: const SizedBox.expand(),
      );

      for (final label in const [
        'github.com/TobiShakur',
        'LinkedIn',
        'tobigutierrez26@gmail.com',
      ]) {
        final finder = find.text(label);
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        await tester.pump();
      }

      expect(tappedUrls, [
        'https://github.com/TobiShakur',
        'https://www.linkedin.com/in/tobias-gutierrez-reboredo-991084279/',
        'mailto:tobigutierrez26@gmail.com',
      ]);
    },
  );
}
