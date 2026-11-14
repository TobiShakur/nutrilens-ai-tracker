// PUNTO DE ENTRADA PRINCIPAL Y CONFIGURACIÓN DEL ÁRBOL DE DEPENDENCIAS
// Inicializa la persistencia local (SharedPreferences), instancia los repositorios
// desacoplados y provee los ViewModels y servicios a través de MultiProvider.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/app_ready_notifier.dart';
import 'core/services/perf_telemetry_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/alacena/data/datasources/barcode_demo_local_datasource.dart';
import 'features/alacena/data/datasources/barcode_product_service_impl.dart';
import 'features/alacena/data/repositories/alacena_repository_impl.dart';
import 'features/alacena/domain/datasources/barcode_demo_datasource.dart';
import 'features/alacena/domain/services/barcode_product_service.dart';
import 'features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'features/diario/data/repositories/diario_repository_impl.dart';
import 'features/diario/data/repositories/meal_health_repository_impl.dart';
import 'features/diario/domain/repositories/meal_health_repository.dart';
import 'features/diario/domain/usecases/evaluate_meal_health_usecase.dart';
import 'features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'features/perfil/data/repositories/perfil_repository_impl.dart';
import 'features/perfil/presentation/viewmodels/perfil_viewmodel.dart';
import 'features/scanner/data/datasources/scanner_firebase_ai_datasource.dart';
import 'features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'features/scanner/data/repositories/scanner_repository_impl.dart';
import 'features/scanner/data/services/image_picker_capture_service_impl.dart';
import 'features/scanner/domain/services/image_capture_service.dart';
import 'features/scanner/presentation/viewmodels/scanner_viewmodel.dart';
import 'features/shell/presentation/views/main_shell_screen.dart';
import 'widgets/desktop_wrapper.dart';
import 'widgets/perf_debug_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await LocalStorageService.inicializar();
  final diarioRepository = DiarioRepositoryImpl(storageService: storageService);
  final alacenaRepository = AlacenaRepositoryImpl(
    storageService: storageService,
  );
  final perfilRepository = PerfilRepositoryImpl(storageService: storageService);
  final imageCaptureService = ImagePickerCaptureServiceImpl();

  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider<ScannerRemoteDataSource>(
          create: (ctx) => ScannerFirebaseAiDataSourceImpl(
            httpClient: ctx.read<http.Client>(),
          ),
        ),
        Provider<MealHealthRepository>(
          create: (ctx) => MealHealthRepositoryImpl(
            remoteDataSource: ctx.read<ScannerRemoteDataSource>(),
          ),
        ),
        Provider<EvaluateMealHealthUseCase>(
          create: (ctx) => EvaluateMealHealthUseCase(
            repository: ctx.read<MealHealthRepository>(),
          ),
        ),
        Provider<BarcodeProductService>(
          create: (ctx) =>
              BarcodeProductServiceImpl(httpClient: ctx.read<http.Client>()),
        ),
        Provider<BarcodeDemoDatasource>(
          create: (_) => const BarcodeDemoLocalDatasource(),
        ),
        Provider<ImageCaptureService>.value(value: imageCaptureService),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(storageService: storageService),
        ),
        ChangeNotifierProvider<DiarioViewModel>(
          create: (ctx) => DiarioViewModel(
            repository: diarioRepository,
            evaluateMealHealthUseCase: ctx.read<EvaluateMealHealthUseCase>(),
          ),
        ),
        ChangeNotifierProvider<AlacenaViewModel>(
          create: (_) => AlacenaViewModel(repository: alacenaRepository),
        ),
        ChangeNotifierProvider<ScannerViewModel>(
          create: (ctx) => ScannerViewModel(
            repository: ScannerRepositoryImpl(
              remoteDataSource: ctx.read<ScannerRemoteDataSource>(),
            ),
            imageCaptureService: ctx.read<ImageCaptureService>(),
            evaluateMealHealthUseCase: ctx.read<EvaluateMealHealthUseCase>(),
          ),
        ),
        ChangeNotifierProvider<PerfilViewModel>(
          create: (_) => PerfilViewModel(repository: perfilRepository),
        ),
      ],
      child: const NutriLensApp(),
    ),
  );
}

class NutriLensApp extends StatefulWidget {
  const NutriLensApp({super.key, this.perfTelemetryService});

  final PerfTelemetryService? perfTelemetryService;

  @override
  State<NutriLensApp> createState() => _NutriLensAppState();
}

class _NutriLensAppState extends State<NutriLensApp> {
  static const List<String> _criticalImageAssets = [
    'assets/images/sample_meal.webp',
  ];

  static const Map<String, List<String>> _localFonts = {
    'Plus Jakarta Sans': [
      'assets/fonts/PlusJakartaSans-Regular.ttf',
      'assets/fonts/PlusJakartaSans-Medium.ttf',
      'assets/fonts/PlusJakartaSans-SemiBold.ttf',
      'assets/fonts/PlusJakartaSans-Bold.ttf',
      'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
    ],
    'Rubik': [
      'assets/fonts/Rubik-Regular.ttf',
      'assets/fonts/Rubik-Medium.ttf',
      'assets/fonts/Rubik-SemiBold.ttf',
      'assets/fonts/Rubik-Bold.ttf',
      'assets/fonts/Rubik-ExtraBold.ttf',
      'assets/fonts/Rubik-Black.ttf',
    ],
  };

  bool _warmupStarted = false;
  Timer? _warmupTimeoutTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmupStarted) {
      return;
    }
    _warmupStarted = true;
    _awaitInitialAssetsAndNotify();
  }

  Future<void> _preloadLocalFonts() async {
    for (final entry in _localFonts.entries) {
      final loader = FontLoader(entry.key);
      for (final assetPath in entry.value) {
        loader.addFont(rootBundle.load(assetPath));
      }
      await loader.load();
    }
  }

  Future<void> _awaitInitialAssetsAndNotify() async {
    final readyCompleter = Completer<void>();

    void finishWarmup() {
      _warmupTimeoutTimer?.cancel();
      _warmupTimeoutTimer = null;
      if (!readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    }

    _warmupTimeoutTimer = Timer(
      const Duration(milliseconds: 1500),
      finishWarmup,
    );

    final firstFrameCompleter = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!firstFrameCompleter.isCompleted) {
        firstFrameCompleter.complete();
      }
    });

    final imageFutures = <Future<void>>[
      for (final asset in _criticalImageAssets)
        precacheImage(AssetImage(asset), context).catchError((_) {}),
    ];

    unawaited(
      Future.wait<void>([
        firstFrameCompleter.future,
        _preloadLocalFonts().catchError((_) {}),
        ...imageFutures,
      ]).then((_) => finishWarmup(), onError: (_) => finishWarmup()),
    );

    await readyCompleter.future;

    if (mounted) {
      notifyAppReady();
    }
  }

  @override
  void dispose() {
    _warmupTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      title: 'NutriLens AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const MainShellScreen(),
      builder: (context, child) => Stack(
        alignment: Alignment.topLeft,
        children: [
          DesktopWrapper(child: child ?? const SizedBox()),
          PerfDebugOverlay(telemetryService: widget.perfTelemetryService),
        ],
      ),
    );
  }
}
