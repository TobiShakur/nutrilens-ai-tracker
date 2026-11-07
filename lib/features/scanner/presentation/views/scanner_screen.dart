// PANTALLA DEL ESCÁNER: VISOR DE CÁMARA E INTERFAZ DE ANÁLISIS MULTIMODAL
// Controla el ciclo de vida del visor nativo, selector de cámara/flash, carga de imágenes de galería
// e invocación al pipeline de visión de Gemini con previsualización interactiva de resultados.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../alacena/presentation/viewmodels/alacena_viewmodel.dart';
import '../../../diario/presentation/viewmodels/diario_viewmodel.dart';
import '../../domain/entities/imagen_plato.dart';
import '../viewmodels/scanner_viewmodel.dart';
import '../widgets/conflicto_marca_dialog.dart';
import '../widgets/review_comida_sheet.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _flashActivo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      _configurarControlador(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _inicializarCamara() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;

      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex != -1 ? backIndex : 0;
      await _configurarControlador(_cameras[_selectedCameraIndex]);
    } catch (_) {
      // Si el navegador no permite streaming WebRTC automático, fallback transparente a captura nativa
    }
  }

  Future<void> _configurarControlador(CameraDescription description) async {
    final oldController = _cameraController;
    final newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await oldController?.dispose();
    if (!mounted) return;

    try {
      await newController.initialize();
      if (!mounted) return;
      setState(() => _cameraController = newController);
    } catch (_) {
      await newController.dispose();
    }
  }

  Future<void> _alternarFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final nuevo = !_flashActivo;
      await _cameraController!.setFlashMode(
        nuevo ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _flashActivo = nuevo);
    } catch (_) {
      if (mounted) setState(() => _flashActivo = !_flashActivo);
    }
  }

  Future<void> _dispararObturador() async {
    final scanVM = context.read<ScannerViewModel>();

    // 1. Si hay stream en vivo activo, sacamos foto del controlador
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xfile = await _cameraController!.takePicture();
        final bytes = await xfile.readAsBytes();
        final imagen = ImagenPlato.crear(
          bytes: bytes,
          nombreArchivo: xfile.name,
          mimeType: 'image/jpeg',
        );
        scanVM.establecerFotoCapturada(imagen);
        if (!mounted) return;
        await _ejecutarAnalisis(imagen: imagen);
        return;
      } catch (e) {
        debugPrint('Fallo al tomar foto con CameraController: $e');
      }
    }

    // 2. Fallback fluido a cámara nativa del teléfono (iOS / Android)
    final img = await scanVM.capturarFotoConCamara();
    if (!mounted || img == null) return;
    await _ejecutarAnalisis(imagen: img);
  }

  Future<void> _seleccionarDeGaleria() async {
    final scanVM = context.read<ScannerViewModel>();
    final img = await scanVM.seleccionarFotoDeGaleria();
    if (!mounted || img == null) return;
    await _ejecutarAnalisis(imagen: img);
  }

  Future<void> _ejecutarAnalisis({ImagenPlato? imagen}) async {
    final alacenaVM = context.read<AlacenaViewModel>();
    final scanVM = context.read<ScannerViewModel>();
    final diarioVM = context.read<DiarioViewModel>();

    final plato = await scanVM.escanear(
      alacenaVM.todosLosIngredientes,
      imagen: imagen,
    );

    if (!mounted) return;

    // En cualquier caso que no sea éxito: mostrar error amigable al usuario y no abrir creación de comida
    if (plato == null || plato.ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No pudimos reconocer la comida. Probá con otra foto más de cerca o con mejor luz.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (plato.tieneConflictosMarcas) {
      for (final conflicto in plato.conflictosMarcas) {
        if (!mounted) break;
        final elegida = await ConflictoMarcaDialog.show(
          context,
          conflicto: conflicto,
        );
        if (elegida != null && mounted) {
          scanVM.resolverConflictoMarca(
            nombreGenerico: conflicto.nombreGenerico,
            alacenaElegida: elegida,
          );
        }
      }
    }

    if (!mounted) return;

    final agregada = await ReviewComidaSheet.show(
      context,
      numeroComidaDefault: diarioVM.diaActual.cantidadComidas + 1,
    );

    if (agregada == true && mounted) {
      scanVM.descartarFotoCapturada();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanVM = context.watch<ScannerViewModel>();
    final foto = scanVM.fotoCapturada;
    final bool camaraLista =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF07140E),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior compacta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      scanVM.descartarFotoCapturada();
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Escanear Plato',
                    style: AppTextStyles.title(
                      size: 16,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (camaraLista)
                    IconButton(
                      icon: Icon(
                        _flashActivo
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _flashActivo
                            ? AppColors.pistachio
                            : Colors.white70,
                        size: 22,
                      ),
                      onPressed: _alternarFlash,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Visor central
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.pistachio.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    color: const Color(0xFF0F1B16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Contenido del visor: foto capturada, stream en vivo, o placeholder limpio
                        if (foto != null)
                          Image.memory(foto.bytes, fit: BoxFit.cover)
                        else if (camaraLista)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  _cameraController!.value.previewSize?.width ??
                                  1280,
                              height:
                                  _cameraController!
                                      .value
                                      .previewSize
                                      ?.height ??
                                  720,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.pistachio.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppColors.pistachio,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Enfocá tu plato de comida',
                                  style: AppTextStyles.body(
                                    size: 13,
                                    color: Colors.white70,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Overlay de análisis IA
                        if (scanVM.escaneando)
                          Container(
                            color: Colors.black.withValues(alpha: 0.75),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.pistachio,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Analizando nutrientes...',
                                    style: AppTextStyles.body(
                                      size: 13,
                                      color: Colors.white,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Esquinas de enfoque
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: _CornerTick(isTop: true, isLeft: true),
                        ),
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: _CornerTick(isTop: true, isLeft: false),
                        ),
                        const Positioned(
                          bottom: 8,
                          left: 8,
                          child: _CornerTick(isTop: false, isLeft: true),
                        ),
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: _CornerTick(isTop: false, isLeft: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Toggle compacto de alacena
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111D18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scanVM.preferirAlacena
                        ? AppColors.pistachio.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: scanVM.preferirAlacena
                          ? AppColors.pistachio
                          : Colors.white60,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Usar ingredientes de mi alacena',
                        style: AppTextStyles.body(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: scanVM.preferirAlacena,
                        activeThumbColor: AppColors.pistachio,
                        activeTrackColor: AppColors.forestDark,
                        onChanged: scanVM.escaneando
                            ? null
                            : scanVM.setPreferirAlacena,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Controles inferiores compactos
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fototeca
                  IconButton(
                    tooltip: 'Fototeca',
                    onPressed: scanVM.escaneando ? null : _seleccionarDeGaleria,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white70,
                      size: 26,
                    ),
                  ),

                  // Obturador principal
                  GestureDetector(
                    onTap: scanVM.escaneando ? null : _dispararObturador,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scanVM.escaneando
                              ? AppColors.forestDark
                              : AppColors.pistachio,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.forestDark,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  // Retomar / Limpiar foto
                  if (foto != null && !scanVM.escaneando)
                    IconButton(
                      tooltip: 'Retomar',
                      onPressed: scanVM.descartarFotoCapturada,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white70,
                        size: 26,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerTick extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerTick({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.pistachio, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.pistachio, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.pistachio, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.pistachio, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
