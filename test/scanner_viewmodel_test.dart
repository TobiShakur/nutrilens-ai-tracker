import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/failures/barcode_scan_failure.dart';
import 'package:nutrilens_provider/features/diario/data/models/meal_health_evaluation_model.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/meal_health_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/meal_health_evaluation.dart';
import 'package:nutrilens_provider/features/diario/domain/repositories/meal_health_repository.dart';
import 'package:nutrilens_provider/features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/health_score_eval_state.dart';
import 'package:nutrilens_provider/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:nutrilens_provider/features/scanner/data/models/comida_ingrediente_model.dart';
import 'package:nutrilens_provider/features/scanner/data/models/plato_detectado_model.dart';
import 'package:nutrilens_provider/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/imagen_plato.dart';
import 'package:nutrilens_provider/features/scanner/domain/entities/plato_detectado.dart';
import 'package:nutrilens_provider/features/scanner/domain/failures/scanner_failure.dart';
import 'package:nutrilens_provider/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:nutrilens_provider/features/scanner/domain/services/image_capture_service.dart';
import 'package:nutrilens_provider/features/scanner/presentation/viewmodels/scanner_state.dart';
import 'package:nutrilens_provider/features/scanner/presentation/viewmodels/scanner_viewmodel.dart';

class _FakeImageCaptureService implements ImageCaptureService {
  ImagenPlato? cameraResult;
  ImagenPlato? galleryResult;
  Object? cameraError;
  Object? galleryError;
  int cameraCalls = 0;
  int galleryCalls = 0;

  _FakeImageCaptureService({this.cameraResult, this.galleryResult});

  @override
  Future<ImagenPlato?> capturarConCamara() async {
    cameraCalls++;
    if (cameraError != null) throw cameraError!;
    return cameraResult;
  }

  @override
  Future<ImagenPlato?> seleccionarDeGaleria() async {
    galleryCalls++;
    if (galleryError != null) throw galleryError!;
    return galleryResult;
  }
}

class _FakeScannerRemoteDataSource implements ScannerRemoteDataSource {
  bool shouldFail = false;

  @override
  Future<PlatoDetectadoModel> analizarFotoPlato({
    required ImagenPlato imagen,
    required List<String> nombresAlacena,
    String languageCode = 'es',
  }) async {
    if (shouldFail) {
      throw const ScannerNetworkFailure();
    }
    return const PlatoDetectadoModel(
      nombrePlato: 'Huevos revueltos con tostadas',
      healthScore: 88,
      explicacionHealthScore: 'Buen balance proteico.',
      ingredientes: [
        ComidaIngredienteModel(
          nombre: 'Huevos de campo',
          gramos: 120,
          calorias: 170,
          proteinas: 15.0,
          carbos: 1.0,
          grasas: 12.0,
          emoji: '🍳',
        ),
        ComidaIngredienteModel(
          nombre: 'Pan integral',
          gramos: 50,
          calorias: 120,
          proteinas: 4.5,
          carbos: 22.0,
          grasas: 1.5,
          emoji: '🍞',
        ),
      ],
    );
  }

  @override
  Future<MealHealthEvaluationModel> evaluarHealthScore({
    required MealHealthEvaluationInput input,
    String languageCode = 'es',
  }) async {
    if (shouldFail) {
      throw const ScannerNetworkFailure();
    }
    return const MealHealthEvaluationModel(
      healthScore: 84,
      razonHealthScore:
          'Buen balance entre proteínas y carbohidratos complejos.',
    );
  }
}

class _ControlledMealHealthRepository implements MealHealthRepository {
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
          healthScore: 84,
          razonHealthScore: 'Buen equilibrio nutricional.',
        ),
      ),
    );
  }
}

class _ControlledScannerRepository implements ScannerRepository {
  int scanCalls = 0;
  Future<PlatoDetectado> Function(
    ImagenPlato imagen,
    bool preferirAlacena,
    List<IngredienteAlacena> alacenaUsuario,
  )?
  onScan;

  @override
  Future<PlatoDetectado> escanearPlato({
    required ImagenPlato imagen,
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
    String languageCode = 'es',
  }) {
    scanCalls++;
    if (onScan != null) {
      return onScan!(imagen, preferirAlacena, alacenaUsuario);
    }
    return Future.value(
      PlatoDetectado(
        id: 'plato_1',
        nombreSugerido: 'Plato test',
        ingredientes: [
          ComidaIngrediente.manual(
            id: 'ing_1',
            nombre: 'Pollo',
            gramos: 150,
            calorias: 240,
            proteinas: 45,
            carbohidratos: 0,
            grasas: 5,
          ),
        ],
      ),
    );
  }
}

void main() {
  group('ImagenPlato, PlatoDetectado & DTOs', () {
    test('ImagenPlato validates bytes and MIME allowlist', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final image = ImagenPlato.crear(bytes: bytes, mimeType: 'image/jpeg');

      expect(image.tamanoBytes, 5);
      expect(image.tamanoLegible, '5 B');
      expect(image.mimeType, 'image/jpeg');

      expect(() => ImagenPlato.crear(bytes: Uint8List(0)), throwsArgumentError);
      expect(
        () => ImagenPlato.crear(bytes: bytes, mimeType: 'application/pdf'),
        throwsArgumentError,
      );

      final upper = ImagenPlato.crear(bytes: bytes, mimeType: 'IMAGE/PNG');
      expect(upper.mimeType, 'image/png');
    });

    test(
      'PlatoDetectado.manualEmpty creates empty manual draft with null score',
      () {
        final manual = PlatoDetectado.manualEmpty(id: 'manual_42');

        expect(manual.id, 'manual_42');
        expect(manual.esManual, isTrue);
        expect(manual.healthScore, isNull);
        expect(manual.explicacionHealthScore, isNull);
        expect(manual.ingredientes, isEmpty);
        expect(manual.totalCalorias, 0);
        expect(manual.totalProteinas, 0.0);
        expect(manual.tieneConflictosMarcas, isFalse);
      },
    );

    test(
      'PlatoDetectadoModel rejects missing or non-finite healthScore and clamps bounds',
      () {
        expect(
          () => PlatoDetectadoModel.fromJson({
            'nombrePlato': 'Bowl',
            'ingredientes': [],
          }),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );
        expect(
          () => PlatoDetectadoModel.fromJson({
            'nombrePlato': 'Bowl',
            'healthScore': double.nan,
            'ingredientes': [],
          }),
          throwsA(isA<ScannerInvalidResponseFailure>()),
        );
        final clamped = PlatoDetectadoModel.fromJson({
          'nombrePlato': 'Bowl',
          'healthScore': 142,
          'ingredientes': [],
        });
        expect(clamped.healthScore, 100);
      },
    );

    test('PlatoDetectadoModel parses JSON defensively', () {
      final model = PlatoDetectadoModel.fromJson({
        'nombrePlato': 'Bowl de Salmón',
        'healthScore': 95,
        'explicacionHealthScore': 'Excelente aporte de omega-3.',
        'ingredientes': [
          {
            'nombre': 'Salmón fresco',
            'gramos': 120,
            'calorias': 240,
            'proteinas': 25.0,
            'carbos': 0.0,
            'grasas': 15.0,
            'emoji': '🐟',
          },
        ],
      });

      final entity = model.toEntity(id: 'plato_test_1');
      expect(entity.id, 'plato_test_1');
      expect(entity.esManual, isFalse);
      expect(entity.ingredientes.first.calorias, 240);
    });
  });

  group('ScannerViewModel State Machine & Guards', () {
    late ScannerRepositoryImpl repository;
    late _FakeImageCaptureService captureService;
    late ScannerViewModel vm;
    late List<IngredienteAlacena> mockPantry;
    late ImagenPlato fakeImage;

    setUp(() {
      repository = ScannerRepositoryImpl(
        remoteDataSource: _FakeScannerRemoteDataSource(),
      );
      fakeImage = ImagenPlato.crear(
        bytes: Uint8List.fromList([10, 20, 30, 40]),
        mimeType: 'image/jpeg',
      );
      captureService = _FakeImageCaptureService(
        cameraResult: fakeImage,
        galleryResult: fakeImage,
      );
      vm = ScannerViewModel(
        repository: repository,
        imageCaptureService: captureService,
      );

      final now = DateTime(2026, 11, 12);
      mockPantry = [
        IngredienteAlacena(
          id: 'ing_huevo',
          nombre: 'Huevos de campo',
          categoria: CategoriaAlacena.proteinas,
          gramosPorcion: 100.0,
          calorias: 143,
          proteinas: 13.0,
          carbohidratos: 1.0,
          grasas: 10.0,
          creadoEn: now,
        ),
        IngredienteAlacena(
          id: 'ing_pan_1',
          nombre: 'Pan integral',
          marca: 'Fargo',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50.0,
          calorias: 120,
          proteinas: 4.5,
          carbohidratos: 22.0,
          grasas: 1.5,
          creadoEn: now,
        ),
        IngredienteAlacena(
          id: 'ing_pan_2',
          nombre: 'Pan integral doble salvado',
          marca: 'Lactal',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 50.0,
          calorias: 110,
          proteinas: 5.0,
          carbohidratos: 20.0,
          grasas: 1.2,
          creadoEn: now,
        ),
      ];
    });

    tearDown(() {
      vm.dispose();
    });

    test(
      'starts in ScannerIdle with preferirAlacena=true and isBusy=false',
      () {
        expect(vm.state, const ScannerIdle());
        expect(vm.preferirAlacena, isTrue);
        expect(vm.isBusy, isFalse);
        expect(vm.imagenActual, isNull);
        expect(vm.platoActual, isNull);
      },
    );

    test(
      'capturarYAnalizar transitions Idle -> Capturing -> Analyzing -> Success and detects brand conflict',
      () async {
        final history = <ScannerState>[];
        vm.addListener(() => history.add(vm.state));

        final ok = await vm.capturarYAnalizar(alacenaUsuario: mockPantry);

        expect(ok, isTrue);
        expect(history.length, 3);
        expect(history[0], const ScannerCapturing());
        expect(history[1], ScannerAnalyzing(imagen: fakeImage));
        expect(history[2], isA<ScannerSuccess>());
        final success = vm.state as ScannerSuccess;
        expect(success.esManual, isFalse);
        expect(success.imagen, fakeImage);
        expect(success.plato.tieneConflictosMarcas, isTrue);
        expect(success.plato.conflictosMarcas.first.opcionesAlacena.length, 2);
      },
    );

    test(
      'capturarYAnalizar prefers liveCapture and skips ImageCaptureService when non-null',
      () async {
        final ok = await vm.capturarYAnalizar(
          alacenaUsuario: mockPantry,
          liveCapture: () async => fakeImage,
        );

        expect(ok, isTrue);
        expect(captureService.cameraCalls, 0);
      },
    );

    test(
      'user cancel (null image) returns to ScannerIdle with 0 repository calls',
      () async {
        final controlledRepo = _ControlledScannerRepository();
        final cancelVm = ScannerViewModel(
          repository: controlledRepo,
          imageCaptureService: _FakeImageCaptureService(
            cameraResult: null,
            galleryResult: null,
          ),
        );
        addTearDown(cancelVm.dispose);

        final camOk = await cancelVm.capturarYAnalizar(
          alacenaUsuario: mockPantry,
        );
        expect(camOk, isFalse);
        expect(cancelVm.state, const ScannerIdle());

        final galOk = await cancelVm.seleccionarGaleriaYAnalizar(
          alacenaUsuario: mockPantry,
        );
        expect(galOk, isFalse);
        expect(cancelVm.state, const ScannerIdle());
        expect(controlledRepo.scanCalls, 0);
      },
    );

    test(
      'blocks concurrent capture, gallery, manual, and toggle calls while busy',
      () async {
        final controlledRepo = _ControlledScannerRepository();
        final completer = Completer<PlatoDetectado>();
        controlledRepo.onScan = (_, _, _) => completer.future;

        final busyVm = ScannerViewModel(
          repository: controlledRepo,
          imageCaptureService: captureService,
        );
        addTearDown(busyVm.dispose);

        final firstFuture = busyVm.capturarYAnalizar(
          alacenaUsuario: mockPantry,
        );
        await Future<void>.delayed(Duration.zero);
        expect(busyVm.isBusy, isTrue);

        expect(
          await busyVm.capturarYAnalizar(alacenaUsuario: mockPantry),
          isFalse,
        );
        expect(
          await busyVm.seleccionarGaleriaYAnalizar(alacenaUsuario: mockPantry),
          isFalse,
        );
        expect(busyVm.iniciarComidaManual(), isFalse);
        busyVm.setPreferirAlacena(false);
        expect(busyVm.preferirAlacena, isTrue);
        expect(controlledRepo.scanCalls, 1);

        completer.complete(
          const PlatoDetectado(
            id: 'p1',
            nombreSugerido: 'Pollo',
            ingredientes: [],
          ),
        );
        expect(await firstFuture, isTrue);
      },
    );

    test(
      'dispose while repository request is in flight does not throw on completion',
      () async {
        final controlledRepo = _ControlledScannerRepository();
        final completer = Completer<PlatoDetectado>();
        controlledRepo.onScan = (_, _, _) => completer.future;

        final localVm = ScannerViewModel(
          repository: controlledRepo,
          imageCaptureService: captureService,
        );

        final future = localVm.capturarYAnalizar(alacenaUsuario: mockPantry);
        await Future<void>.delayed(Duration.zero);
        localVm.dispose();

        completer.complete(
          const PlatoDetectado(
            id: 'p1',
            nombreSugerido: 'Pollo',
            ingredientes: [],
          ),
        );
        expect(await future, isFalse);
      },
    );

    test(
      'maps every ScannerFailure and BarcodePermisoDenegadoFailure accurately',
      () async {
        final cases = <(Object, ScannerErrorType)>[
          (const ScannerApiKeyMissingFailure(), ScannerErrorType.missingApiKey),
          (const ScannerMissingImageFailure(), ScannerErrorType.invalidImage),
          (
            const ScannerInvalidImageFailure('size_exceeded'),
            ScannerErrorType.invalidImage,
          ),
          (
            const ScannerPermissionDeniedFailure(isCamera: true),
            ScannerErrorType.permissionDenied,
          ),
          (const ScannerNetworkFailure(), ScannerErrorType.network),
          (const ScannerTimeoutFailure(), ScannerErrorType.timeout),
          (const ScannerRateLimitFailure(), ScannerErrorType.rateLimit),
          (
            const ScannerServiceUnavailableFailure(statusCode: 503),
            ScannerErrorType.serviceUnavailable,
          ),
          (
            const ScannerInvalidResponseFailure(),
            ScannerErrorType.invalidResponse,
          ),
          (
            const ScannerNoFoodDetectedFailure(),
            ScannerErrorType.noFoodDetected,
          ),
          (
            const BarcodePermisoDenegadoFailure(esCamara: false),
            ScannerErrorType.permissionDenied,
          ),
          (StateError('secret-internal-token'), ScannerErrorType.unknown),
        ];

        for (final (failure, expectedType) in cases) {
          final repo = _ControlledScannerRepository()
            ..onScan = (_, _, _) async => throw failure;
          final testVm = ScannerViewModel(
            repository: repo,
            imageCaptureService: captureService,
          );

          final ok = await testVm.capturarYAnalizar(alacenaUsuario: mockPantry);
          expect(ok, isFalse);
          expect(testVm.state, isA<ScannerError>());
          final err = testVm.state as ScannerError;
          expect(err.type, expectedType);
          expect(err.imagen, fakeImage);
          expect(err.message.contains('secret-internal-token'), isFalse);
          testVm.dispose();
        }
      },
    );

    test(
      'reintentarAnalisis retries retained image and recovers to ScannerSuccess',
      () async {
        var shouldThrow = true;
        final repo = _ControlledScannerRepository()
          ..onScan = (_, _, _) async {
            if (shouldThrow) throw const ScannerTimeoutFailure();
            return PlatoDetectado(
              id: 'recovered',
              nombreSugerido: 'Ensalada',
              ingredientes: [
                ComidaIngrediente.manual(
                  id: 'i1',
                  nombre: 'Lechuga',
                  gramos: 80,
                  calorias: 15,
                  proteinas: 1,
                  carbohidratos: 2,
                  grasas: 0,
                ),
              ],
            );
          };
        final retryVm = ScannerViewModel(
          repository: repo,
          imageCaptureService: captureService,
        );
        addTearDown(retryVm.dispose);

        expect(
          await retryVm.capturarYAnalizar(alacenaUsuario: mockPantry),
          isFalse,
        );
        expect(retryVm.state, isA<ScannerError>());
        expect((retryVm.state as ScannerError).imagen, fakeImage);

        shouldThrow = false;
        expect(
          await retryVm.reintentarAnalisis(alacenaUsuario: mockPantry),
          isTrue,
        );
        expect(retryVm.state, isA<ScannerSuccess>());
        expect(repo.scanCalls, 2);
      },
    );

    test(
      'iniciarComidaManual builds empty manual draft and saves ComidaItem once ingredients added',
      () {
        expect(vm.iniciarComidaManual(), isTrue);
        expect(vm.state, isA<ScannerSuccess>());
        final success = vm.state as ScannerSuccess;
        expect(success.esManual, isTrue);
        expect(success.imagen, isNull);
        expect(success.plato.ingredientes, isEmpty);

        expect(
          vm.construirComidaParaDiario(
            titulo: 'Almuerzo',
            tipoComida: 'Almuerzo',
          ),
          isNull,
        );

        vm.agregarIngredienteDesdeAlacena(mockPantry.first, 150);
        final comida = vm.construirComidaParaDiario(
          titulo: 'Almuerzo proteico',
          tipoComida: 'Almuerzo',
          now: DateTime(2026, 11, 12, 13, 5),
        );

        expect(comida, isNotNull);
        expect(comida!.titulo, 'Almuerzo proteico');
        expect(comida.tipoComida, 'ALMUERZO');
        expect(comida.hora, '13:05');
        expect(comida.descripcion, isNull);
        expect(comida.explicacionHealthScore, isNull);
        expect(comida.ingredientes.length, 1);
      },
    );

    test(
      'resolverConflictoMarca, portion updates, and delete update dish totals',
      () async {
        await vm.capturarYAnalizar(alacenaUsuario: mockPantry);
        final conflict = vm.platoActual!.conflictosMarcas.first;
        vm.resolverConflictoMarca(
          nombreGenerico: conflict.nombreGenerico,
          alacenaElegida: conflict.opcionesAlacena.last,
        );
        expect(vm.platoActual!.tieneConflictosMarcas, isFalse);

        final first = vm.platoActual!.ingredientes.first;
        final initialCalories = vm.platoActual!.totalCalorias;
        vm.ajustarGramosIngrediente(first.id, 30);
        expect(vm.platoActual!.totalCalorias, greaterThan(initialCalories));

        vm.fijarGramosIngrediente(first.id, 50);
        expect(
          vm.platoActual!.ingredientes
              .firstWhere((i) => i.id == first.id)
              .gramos,
          50.0,
        );

        vm.eliminarIngrediente(first.id);
        expect(
          vm.platoActual!.ingredientes.any((i) => i.id == first.id),
          isFalse,
        );

        vm.reiniciar();
        expect(vm.state, const ScannerIdle());
      },
    );

    test(
      'evaluarHealthScore scores manual meal, tracks dirty edits, blocks double taps, and preserves prior score on error',
      () async {
        final healthRepo = _ControlledMealHealthRepository();
        final evalUseCase = EvaluateMealHealthUseCase(repository: healthRepo);
        final scoredVm = ScannerViewModel(
          repository: repository,
          imageCaptureService: captureService,
          evaluateMealHealthUseCase: evalUseCase,
        );
        addTearDown(scoredVm.dispose);

        scoredVm.iniciarComidaManual();
        expect(scoredVm.platoActual!.healthScore, isNull);
        expect(scoredVm.healthScoreSnapshot.healthScore, isNull);

        // Editing ingredients while unscored must not mark stale.
        scoredVm.agregarIngredienteDesdeAlacena(mockPantry.first, 150);
        expect(
          (scoredVm.state as ScannerSuccess).healthScoreDesactualizado,
          isFalse,
        );

        final firstCompleter = Completer<MealHealthResult>();
        healthRepo.onEvaluate = (_) => firstCompleter.future;

        final future1 = scoredVm.evaluarHealthScore(titulo: 'Almuerzo test');
        expect(
          (scoredVm.state as ScannerSuccess).healthScoreEvalState,
          isA<HealthScoreEvaluating>(),
        );
        // Double-tap while in flight is ignored.
        final future2 = scoredVm.evaluarHealthScore(titulo: 'Almuerzo test');
        expect(await future2, isFalse);
        expect(healthRepo.calls, 1);

        firstCompleter.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(
              healthScore: 91,
              razonHealthScore: 'Excelente densidad nutricional.',
            ),
          ),
        );
        expect(await future1, isTrue);
        final scoredState = scoredVm.state as ScannerSuccess;
        expect(scoredState.plato.healthScore, 91);
        expect(
          scoredState.plato.explicacionHealthScore,
          'Excelente densidad nutricional.',
        );
        expect(scoredState.healthScoreDesactualizado, isFalse);
        expect(scoredState.healthScoreEvalState, isA<HealthScoreEvalSuccess>());

        // Editing grams marks the score as stale.
        final ingId = scoredVm.platoActual!.ingredientes.first.id;
        scoredVm.ajustarGramosIngrediente(ingId, 40);
        expect(
          (scoredVm.state as ScannerSuccess).healthScoreDesactualizado,
          isTrue,
        );

        // Error preserves prior score & explanation.
        healthRepo.onEvaluate = (_) async =>
            const MealHealthError(ScannerTimeoutFailure());
        expect(await scoredVm.evaluarHealthScore(), isFalse);
        final errState = scoredVm.state as ScannerSuccess;
        expect(errState.plato.healthScore, 91);
        expect(
          errState.plato.explicacionHealthScore,
          'Excelente densidad nutricional.',
        );
        expect(errState.healthScoreDesactualizado, isTrue);
        expect(errState.healthScoreEvalState, isA<HealthScoreEvalError>());
      },
    );

    test(
      'evaluarHealthScore drops stale in-flight result if ingredients change mid-flight',
      () async {
        final healthRepo = _ControlledMealHealthRepository();
        final completer = Completer<MealHealthResult>();
        healthRepo.onEvaluate = (_) => completer.future;
        final evalVm = ScannerViewModel(
          repository: repository,
          imageCaptureService: captureService,
          evaluateMealHealthUseCase: EvaluateMealHealthUseCase(
            repository: healthRepo,
          ),
        );
        addTearDown(evalVm.dispose);

        evalVm.iniciarComidaManual();
        evalVm.agregarIngredienteDesdeAlacena(mockPantry.first, 100);
        final pending = evalVm.evaluarHealthScore(titulo: 'Almuerzo');

        // Mutate grams while evaluation is running.
        final ingId = evalVm.platoActual!.ingredientes.first.id;
        evalVm.ajustarGramosIngrediente(ingId, 50);

        completer.complete(
          const MealHealthSuccess(
            MealHealthEvaluation(
              healthScore: 80,
              razonHealthScore: 'Razon obsoleta.',
            ),
          ),
        );
        expect(await pending, isFalse);
        expect(evalVm.platoActual!.healthScore, isNull);
        expect(
          (evalVm.state as ScannerSuccess).healthScoreEvalState,
          const HealthScoreEvalIdle(),
        );
      },
    );

    test(
      'MealHealthRepositoryImpl maps failures cleanly without inventing fake scores',
      () async {
        final ds = _FakeScannerRemoteDataSource()..shouldFail = true;
        final repo = MealHealthRepositoryImpl(remoteDataSource: ds);
        final res = await repo.evaluateMealHealth(
          const MealHealthEvaluationInput(
            titulo: 'Test',
            ingredientes: [
              MealHealthIngredientInput(
                nombre: 'Pollo',
                gramos: 100,
                calorias: 165,
                proteinas: 31,
                carbohidratos: 0,
                grasas: 3.6,
              ),
            ],
            totalCalorias: 165,
            totalProteinas: 31,
            totalCarbohidratos: 0,
            totalGrasas: 3.6,
          ),
        );
        expect(res, isA<MealHealthError>());
      },
    );
  });
}
