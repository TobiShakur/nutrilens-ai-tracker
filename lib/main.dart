// PUNTO DE ENTRADA PRINCIPAL Y CONFIGURACIÓN DEL ÁRBOL DE DEPENDENCIAS
// Inicializa la persistencia local (SharedPreferences), instancia los repositorios
// desacoplados y provee los ViewModels globales a través de MultiProvider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/alacena/data/repositories/alacena_repository_impl.dart';
import 'features/alacena/presentation/viewmodels/alacena_viewmodel.dart';
import 'features/diario/data/repositories/diario_repository_impl.dart';
import 'features/diario/presentation/viewmodels/diario_viewmodel.dart';
import 'features/perfil/data/repositories/perfil_repository_impl.dart';
import 'features/perfil/presentation/viewmodels/perfil_viewmodel.dart';
import 'features/scanner/data/repositories/scanner_repository_impl.dart';
import 'features/scanner/data/services/image_picker_capture_service_impl.dart';
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
  final scannerRepository = ScannerRepositoryImpl();
  final perfilRepository = PerfilRepositoryImpl(storageService: storageService);
  final imageCaptureService = ImagePickerCaptureServiceImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DiarioViewModel>(
          create: (_) => DiarioViewModel(repository: diarioRepository),
        ),
        ChangeNotifierProvider<AlacenaViewModel>(
          create: (_) => AlacenaViewModel(repository: alacenaRepository),
        ),
        ChangeNotifierProvider<ScannerViewModel>(
          create: (_) => ScannerViewModel(
            repository: scannerRepository,
            imageCaptureService: imageCaptureService,
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
    return MaterialApp(
      title: 'NutriLens AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShellScreen(),
      builder: (context, child) =>
          DesktopWrapper(child: child ?? const SizedBox()),
    );
  }
}
