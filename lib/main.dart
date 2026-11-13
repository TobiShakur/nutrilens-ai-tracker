// PUNTO DE ENTRADA PRINCIPAL Y CONFIGURACIÓN DEL ÁRBOL DE DEPENDENCIAS
// Inicializa la persistencia local (SharedPreferences), instancia los repositorios
// desacoplados y provee los ViewModels y servicios a través de MultiProvider.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'core/localization/locale_provider.dart';
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

class NutriLensApp extends StatelessWidget {
  const NutriLensApp({super.key});

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
      builder: (context, child) =>
          DesktopWrapper(child: child ?? const SizedBox()),
    );
  }
}
