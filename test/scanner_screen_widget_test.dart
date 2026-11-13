import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/l10n/app_localizations.dart';
import 'package:nutrilens_provider/features/alacena/data/repositories/alacena_repository_impl.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/diario_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/plato_detectado.dart';
import 'package:nutrilens_provider/features/scanner/domain/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/camera_preview_controller.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/image_capture_service.dart';
import 'package:nutrilens_provider/features/scanner/presentation/viewmodels/scanner_state.dart';
import 'package:nutrilens_provider/features/scanner/presentation/viewmodels/scanner_viewmodel.dart';
import 'package:nutrilens_provider/features/scanner/presentation/views/scanner_screen.dart';
import 'package:provider/provider.dart';

final Uint8List _valid1x1Png = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _FakeCameraPreviewController extends ChangeNotifier
    implements CameraPreviewController {
  CameraPreviewStatus _status;
  bool _flashOn = false;
  int initializeCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  ImagenPlato? livePhoto;

  _FakeCameraPreviewController({
    CameraPreviewStatus initialStatus = CameraPreviewStatus.unavailable,
  }) : _status = initialStatus;

  @override
  CameraPreviewStatus get status => _status;

  @override
  bool get isReady => _status == CameraPreviewStatus.ready;

  @override
  bool get isFlashOn => _flashOn;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    notifyListeners();
  }

  @override
  Future<void> pauseAndDispose() async {
    pauseCalls++;
    _status = CameraPreviewStatus.uninitialized;
    _flashOn = false;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
    notifyListeners();
  }

  @override
  Future<void> toggleFlash() async {
    _flashOn = !_flashOn;
    notifyListeners();
  }

  @override
  Future<ImagenPlato?> takePicture() async => livePhoto;
}

class _FakeCaptureService implements ImageCaptureService {
  ImagenPlato? photo;
  _FakeCaptureService({this.photo});

  @override
  Future<ImagenPlato?> capturarConCamara() async => photo;

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() async => photo;
}

class _FakeScannerRepository implements ScannerRepository {
  bool failOnce = false;
  ImagenPlato? lastImage;
  String? lastLanguageCode;
  Completer<PlatoDetectado>? pendingScan;

  @override
  Future<PlatoDetectado> escanearPlato({
    required ImagenPlato imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
    String languageCode = 'es',
  }) async {
    lastImage = imagen;
    lastLanguageCode = languageCode;
    if (pendingScan != null) {
      return pendingScan!.future;
    }
    if (failOnce) {
      failOnce = false;
      throw const ScannerTimeoutFailure();
    }
    return PlatoDetectado(
      id: 'plato_widget',
      nombreSugerido: 'Ensalada proteica',
      ingredientes: [
        ComidaIngrediente.manual(
          id: 'i1',
          nombre: 'Pollo grillado',
          gramos: 150,
          calorias: 240,
          proteinas: 45,
          carbohidratos: 0,
          grasas: 5,
        ),
      ],
    );
  }
}

void main() {
  Widget buildTestApp({
    required ScannerViewModel scanVM,
    required AlacenaViewModel alacenaVM,
    required DiarioViewModel diarioVM,
    required CameraPreviewController cameraCtrl,
    Locale locale = const Locale('es'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScannerViewModel>.value(value: scanVM),
        ChangeNotifierProvider<AlacenaViewModel>.value(value: alacenaVM),
        ChangeNotifierProvider<DiarioViewModel>.value(value: diarioVM),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ScannerScreen(cameraControllerOverride: cameraCtrl),
                    ),
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'ScannerScreen renders symmetric dock, handles error banner + retry, and forwards lifecycle events',
    (tester) async {
      final image = ImagenPlato.crear(
        bytes: _valid1x1Png,
        mimeType: 'image/png',
      );
      final repo = _FakeScannerRepository()..failOnce = true;
      final scanVM = ScannerViewModel(
        repository: repo,
        imageCaptureService: _FakeCaptureService(photo: image),
      );
      final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
      final diarioVM = DiarioViewModel(repository: DiarioRepositoryImpl());
      final cameraCtrl = _FakeCameraPreviewController();
      addTearDown(() {
        scanVM.dispose();
        alacenaVM.dispose();
        diarioVM.dispose();
        cameraCtrl.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          scanVM: scanVM,
          alacenaVM: alacenaVM,
          diarioVM: diarioVM,
          cameraCtrl: cameraCtrl,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      // Symmetric 3-slot dock and fallback card are visible simultaneously.
      expect(find.text('Fototeca'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Cámara en vivo no disponible'), findsOneWidget);
      expect(cameraCtrl.initializeCalls, 1);

      // App lifecycle pause & resume safely delegate to CameraPreviewController.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(cameraCtrl.pauseCalls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(cameraCtrl.resumeCalls, 1);

      // Tapping gallery triggers error banner (due to failOnce=true) with Reintentar & Retomar.
      await tester.tap(find.text('Fototeca'));
      await tester.pumpAndSettle();

      expect(scanVM.state, isA<ScannerError>());
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Retomar'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);

      // Retrying succeeds and opens ReviewComidaSheet in AI mode.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL DETECTADO'), findsOneWidget);
      expect(find.text('Pollo grillado'), findsOneWidget);
    },
  );

  testWidgets(
    'Manual meal flow disables save when empty, allows dialogs without controller leaks, and saves to DiarioViewModel',
    (tester) async {
      final scanVM = ScannerViewModel(
        repository: _FakeScannerRepository(),
        imageCaptureService: _FakeCaptureService(),
      );
      final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
      final diarioVM = DiarioViewModel(repository: DiarioRepositoryImpl());
      final cameraCtrl = _FakeCameraPreviewController();
      addTearDown(() {
        scanVM.dispose();
        alacenaVM.dispose();
        diarioVM.dispose();
        cameraCtrl.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          scanVM: scanVM,
          alacenaVM: alacenaVM,
          diarioVM: diarioVM,
          cameraCtrl: cameraCtrl,
        ),
      );
      await tester.pumpAndSettle();

      final initialMeals = diarioVM.diaActual.cantidadComidas;

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(find.text('Armado manual'), findsOneWidget);
      expect(find.text('TOTAL DE LA COMIDA'), findsOneWidget);
      expect(find.text('Todavía no agregaste ingredientes'), findsOneWidget);

      // Save CTA must be disabled when ingredients list is empty.
      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Agregar comida'),
      );
      expect(saveButton.onPressed, isNull);

      // Add an ingredient from Alacena via SelectorAlacenaModal.
      await tester.tap(find.text('Agregar ingrediente desde Mi Alacena'));
      await tester.pumpAndSettle();
      expect(find.text('SELECCIONAR DE ALACENA'), findsOneWidget);

      final firstPantry = alacenaVM.todosLosIngredientes.first;
      await tester.tap(find.text(firstPantry.nombreConMarca).first);
      await tester.pumpAndSettle();

      // Edit meal title via StatefulWidget dialog (no TextEditingController leak).
      await tester.tap(find.byTooltip('Cambiar nombre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bowl Manual');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Bowl Manual'), findsOneWidget);

      // Edit grams via StatefulWidget dialog (no TextEditingController leak).
      await tester.tap(find.text(firstPantry.porcionLabel).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '200');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(find.text('200g'), findsOneWidget);

      // Confirm saving meal: registers in DiarioViewModel and pops cleanly.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar comida'));
      await tester.pumpAndSettle();

      expect(diarioVM.diaActual.cantidadComidas, initialMeals + 1);
      expect(diarioVM.diaActual.comidas.last.titulo, 'Bowl Manual');
      expect(scanVM.state, const ScannerIdle());
      expect(find.text('Open Scanner'), findsOneWidget);
    },
  );

  testWidgets(
    'Sample meal pill fits 390px top bar with flash, toggles card, dismisses on outside tap, disables while busy, and analyzes bundled asset bytes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pending = Completer<PlatoDetectado>();
      final repo = _FakeScannerRepository()..pendingScan = pending;
      final scanVM = ScannerViewModel(
        repository: repo,
        imageCaptureService: _FakeCaptureService(),
      );
      final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
      final diarioVM = DiarioViewModel(repository: DiarioRepositoryImpl());
      final cameraCtrl = _FakeCameraPreviewController(
        initialStatus: CameraPreviewStatus.ready,
      );
      addTearDown(() {
        scanVM.dispose();
        alacenaVM.dispose();
        diarioVM.dispose();
        cameraCtrl.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          scanVM: scanVM,
          alacenaVM: alacenaVM,
          diarioVM: diarioVM,
          cameraCtrl: cameraCtrl,
          locale: const Locale('es'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Prueba'), findsOneWidget);
      expect(find.byTooltip('Encender flash'), findsOneWidget);

      // Open sample meal card.
      await tester.tap(find.text('Prueba'));
      await tester.pumpAndSettle();

      expect(find.text('¿Sin foto a mano?'), findsOneWidget);
      expect(find.text('Probar con plato real'), findsOneWidget);

      // Tapping outside the card (top-left inside viewfinder scrim) dismisses it.
      final scaffoldRect = tester.getRect(find.byType(ClipRRect).first);
      await tester.tapAt(Offset(scaffoldRect.left + 12, scaffoldRect.top + 12));
      await tester.pumpAndSettle();
      expect(find.text('¿Sin foto a mano?'), findsNothing);

      // Re-open and trigger sample meal analysis.
      await tester.tap(find.text('Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Probar con plato real'));
      await tester.pump();
      await tester.pump();

      // Card dismissed, sample image shown in preview while analyzing, pill disabled.
      expect(find.text('¿Sin foto a mano?'), findsNothing);
      expect(scanVM.state, isA<ScannerAnalyzing>());
      expect(find.text('Analizando nutrientes...'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Tapping "Prueba" while busy does nothing.
      await tester.tap(find.text('Prueba'));
      await tester.pump();
      expect(find.text('¿Sin foto a mano?'), findsNothing);

      // Verify exact asset bytes were loaded and passed to repository.
      final expectedData = await rootBundle.load(
        'assets/images/sample_meal.jpg',
      );
      final expectedBytes = expectedData.buffer.asUint8List(
        expectedData.offsetInBytes,
        expectedData.lengthInBytes,
      );
      expect(repo.lastImage, isNotNull);
      expect(repo.lastImage!.bytes, expectedBytes);
      expect(repo.lastImage!.mimeType, 'image/jpeg');
      expect(repo.lastLanguageCode, 'es');

      // Complete AI response at standard viewport -> opens ReviewComidaSheet.
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      pending.complete(
        PlatoDetectado(
          id: 'plato_sample',
          nombreSugerido: 'Pollo grillado con palta',
          ingredientes: [
            ComidaIngrediente.manual(
              id: 'i1',
              nombre: 'Pollo grillado',
              gramos: 180,
              calorias: 290,
              proteinas: 52,
              carbohidratos: 0,
              grasas: 7,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOTAL DETECTADO'), findsOneWidget);
      expect(find.text('Pollo grillado'), findsOneWidget);
    },
  );

  testWidgets(
    'Sample meal card works in English locale and sends languageCode en',
    (tester) async {
      final repo = _FakeScannerRepository();
      final scanVM = ScannerViewModel(
        repository: repo,
        imageCaptureService: _FakeCaptureService(),
      );
      final alacenaVM = AlacenaViewModel(repository: AlacenaRepositoryImpl());
      final diarioVM = DiarioViewModel(repository: DiarioRepositoryImpl());
      final cameraCtrl = _FakeCameraPreviewController();
      addTearDown(() {
        scanVM.dispose();
        alacenaVM.dispose();
        diarioVM.dispose();
        cameraCtrl.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          scanVM: scanVM,
          alacenaVM: alacenaVM,
          diarioVM: diarioVM,
          cameraCtrl: cameraCtrl,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      expect(find.text('Sample'), findsOneWidget);
      await tester.tap(find.text('Sample'));
      await tester.pumpAndSettle();

      expect(find.text('No photo handy?'), findsOneWidget);
      expect(find.text('Try sample meal'), findsOneWidget);

      // Dismiss via close button, then reopen and run.
      await tester.tap(find.byTooltip('Close sample meal card'));
      await tester.pumpAndSettle();
      expect(find.text('No photo handy?'), findsNothing);

      await tester.tap(find.text('Sample'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try sample meal'));
      await tester.pumpAndSettle();

      expect(repo.lastLanguageCode, 'en');
      expect(find.text('DETECTED TOTAL'), findsOneWidget);
      expect(find.text('Pollo grillado'), findsOneWidget);
    },
  );
}
