import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:nutrilens_provider/features/alacena/domain/datasources/barcode_demo_datasource.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_demo_chip.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/barcode_product_data.dart';
import 'package:nutrilens_provider/features/alacena/domain/services/barcode_product_service.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/barcode_scanner_viewmodel.dart';
import 'package:nutrilens_provider/features/alacena/presentation/widgets/barcode_scanner_sheet.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/image_capture_service.dart';
import 'package:provider/provider.dart';

class _FakeDemoDatasource implements BarcodeDemoDatasource {
  @override
  List<BarcodeDemoChip> obtenerChipsDemostracion() => const [
    BarcodeDemoChip(label: 'Nutella', codigo: '3017620422003'),
  ];
}

class _FakeBarcodeService implements BarcodeProductService {
  Future<BarcodeProductData?> Function(String codigo)? onBuscar;

  @override
  Future<BarcodeProductData?> buscarPorCodigoBarras(
    String codigo, {
    String languageCode = 'es',
  }) {
    if (onBuscar != null) return onBuscar!(codigo);
    return Future.value(null);
  }

  @override
  Future<BarcodeProductData?> analizarFotoEtiqueta({
    required Uint8List bytes,
    required String mimeType,
    String languageCode = 'es',
  }) async => null;
}

class _FakeCaptureService implements ImageCaptureService {
  @override
  Future<ImagenPlato?> capturarConCamara() async => null;

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() async => null;
}

void main() {
  const productoDemo = BarcodeProductData(
    nombre: 'Nutella Ferrero',
    marca: 'Ferrero',
    porcionGramos: 15,
    calorias: 81,
    proteinas: 0.9,
    carbohidratos: 8.6,
    grasas: 4.6,
    codigoBarras: '3017620422003',
    fuente: 'Open Food Facts',
  );

  testWidgets(
    'BarcodeScannerSheet renderiza Loading, Error, Success, valida inputFormatters y retorna producto',
    (tester) async {
      final fakeService = _FakeBarcodeService();
      final completer = Completer<BarcodeProductData?>();
      fakeService.onBuscar = (_) => completer.future;

      final vm = BarcodeScannerViewModel(
        barcodeService: fakeService,
        imageCaptureService: _FakeCaptureService(),
        demoDatasource: _FakeDemoDatasource(),
      );

      BarcodeProductData? resultadoModal;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultadoModal = await BarcodeScannerSheet.show(
                    context,
                    viewModelOverride: vm,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('ESCANEAR PRODUCTO'), findsOneWidget);
      expect(find.text('Sacar foto'), findsOneWidget);

      // Cambiar al tab Código de barras
      await tester.tap(find.text('Código de barras'));
      await tester.pumpAndSettle();

      // InputFormatters: bloquean letras y limitan a 14 dígitos
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'abc123456789012345678');
      await tester.pump();
      expect(
        tester.widget<TextField>(textField).controller!.text,
        equals('12345678901234'),
      );

      // Código inválido muestra _ErrorBanner
      await tester.enterText(textField, '123');
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();
      expect(
        find.text('El código de barras ingresado no es válido.'),
        findsOneWidget,
      );

      // Tocar chip demo muestra _LoadingCard mientras Completer está pendiente
      await tester.tap(find.text('Nutella (3017620422003)'));
      await tester.pump();
      expect(find.text('Buscando producto...'), findsOneWidget);

      // Completar búsqueda muestra _ResultadoCard y retorna producto al tocar CTA
      completer.complete(productoDemo);
      await tester.pumpAndSettle();

      expect(find.text('Nutella Ferrero'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(resultadoModal, equals(productoDemo));
      vm.dispose();
    },
  );

  testWidgets(
    'BarcodeScannerSheet funciona dentro de MultiProvider sin overrides',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<BarcodeProductService>(
              create: (_) => _FakeBarcodeService(),
            ),
            Provider<ImageCaptureService>(create: (_) => _FakeCaptureService()),
            Provider<BarcodeDemoDatasource>(
              create: (_) => _FakeDemoDatasource(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => BarcodeScannerSheet.show(context),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('ESCANEAR PRODUCTO'), findsOneWidget);
    },
  );
}
