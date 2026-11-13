import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../alacena/presentation/viewmodels/alacena_viewmodel.dart';
import '../../../diario/presentation/viewmodels/diario_viewmodel.dart';
import '../../data/services/camera_preview_controller_impl.dart';
import '../../domain/services/camera_preview_controller.dart';
import '../viewmodels/scanner_state.dart';
import '../viewmodels/scanner_viewmodel.dart';
import '../widgets/camera_preview_viewport.dart';
import '../widgets/conflicto_marca_dialog.dart';
import '../widgets/review_comida_sheet.dart';

class ScannerScreen extends StatefulWidget {
  final CameraPreviewController? cameraControllerOverride;

  const ScannerScreen({super.key, this.cameraControllerOverride});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final CameraPreviewController _cameraController;
  late final bool _ownsCameraController;
  bool _pickingExternalMedia = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsCameraController = widget.cameraControllerOverride == null;
    _cameraController =
        widget.cameraControllerOverride ?? CameraPreviewControllerImpl();
    _cameraController.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsCameraController) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_pickingExternalMedia) {
        _cameraController.pauseAndDispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.resume();
    }
  }

  void _handleClose() {
    context.read<ScannerViewModel>().reiniciar();
    Navigator.pop(context);
  }

  Future<void> _handleShutterTap() async {
    final scanVM = context.read<ScannerViewModel>();
    if (scanVM.isBusy) return;
    HapticFeedback.mediumImpact();

    final pantryItems = context.read<AlacenaViewModel>().todosLosIngredientes;
    _pickingExternalMedia = true;
    try {
      final ok = await scanVM.capturarYAnalizar(
        alacenaUsuario: pantryItems,
        liveCapture: _cameraController.isReady
            ? _cameraController.takePicture
            : null,
      );
      if (ok && mounted) {
        await _onScanSuccess();
      }
    } finally {
      _pickingExternalMedia = false;
    }
  }

  Future<void> _handleGalleryTap() async {
    final scanVM = context.read<ScannerViewModel>();
    if (scanVM.isBusy) return;

    final pantryItems = context.read<AlacenaViewModel>().todosLosIngredientes;
    _pickingExternalMedia = true;
    try {
      final ok = await scanVM.seleccionarGaleriaYAnalizar(
        alacenaUsuario: pantryItems,
      );
      if (ok && mounted) {
        await _onScanSuccess();
      }
    } finally {
      _pickingExternalMedia = false;
    }
  }

  Future<void> _handleRetryTap() async {
    final scanVM = context.read<ScannerViewModel>();
    if (scanVM.isBusy) return;

    final pantryItems = context.read<AlacenaViewModel>().todosLosIngredientes;
    final ok = await scanVM.reintentarAnalisis(alacenaUsuario: pantryItems);
    if (ok && mounted) {
      await _onScanSuccess();
    }
  }

  Future<void> _handleManualTap() async {
    final scanVM = context.read<ScannerViewModel>();
    if (scanVM.isBusy) return;

    if (scanVM.iniciarComidaManual()) {
      await _openReviewSheet();
    }
  }

  Future<void> _onScanSuccess() async {
    final scanVM = context.read<ScannerViewModel>();
    final dish = scanVM.platoActual;
    if (dish == null) return;

    if (dish.tieneConflictosMarcas) {
      for (final conflict in dish.conflictosMarcas) {
        if (!mounted) return;
        final chosen = await ConflictoMarcaDialog.show(
          context,
          conflicto: conflict,
        );
        if (chosen != null && mounted) {
          scanVM.resolverConflictoMarca(
            nombreGenerico: conflict.nombreGenerico,
            alacenaElegida: chosen,
          );
        }
      }
    }

    if (!mounted) return;
    await _openReviewSheet();
  }

  Future<void> _openReviewSheet() async {
    final scanVM = context.read<ScannerViewModel>();
    final diarioVM = context.read<DiarioViewModel>();
    final navigator = Navigator.of(context);

    final added = await ReviewComidaSheet.show(
      context,
      numeroComidaDefault: diarioVM.diaActual.cantidadComidas + 1,
    );

    if (!mounted) return;
    scanVM.reiniciar();
    if (added == true) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.select<ScannerViewModel, ScannerState>(
      (vm) => vm.state,
    );
    final preferPantry = context.select<ScannerViewModel, bool>(
      (vm) => vm.preferirAlacena,
    );
    final isBusy = state is ScannerCapturing || state is ScannerAnalyzing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final activeImage = switch (state) {
      ScannerAnalyzing(:final imagen) => imagen,
      ScannerSuccess(:final imagen) => imagen,
      ScannerError(:final imagen) => imagen,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.webBg,
      body: SafeArea(
        child: Column(
          children: [
            _ScannerTopBar(
              cameraController: _cameraController,
              onClose: _handleClose,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.pistachio.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      color: AppColors.scannerSurfaceDark,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (activeImage != null)
                            Image.memory(activeImage.bytes, fit: BoxFit.cover)
                          else
                            CameraPreviewViewport(
                              controller: _cameraController,
                            ),
                          const Positioned(
                            top: 14,
                            left: 14,
                            child: _CornerTick(isTop: true, isLeft: true),
                          ),
                          const Positioned(
                            top: 14,
                            right: 14,
                            child: _CornerTick(isTop: true, isLeft: false),
                          ),
                          const Positioned(
                            bottom: 14,
                            left: 14,
                            child: _CornerTick(isTop: false, isLeft: true),
                          ),
                          const Positioned(
                            bottom: 14,
                            right: 14,
                            child: _CornerTick(isTop: false, isLeft: false),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 16,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: activeImage != null && !isBusy
                                    ? 1.0
                                    : 0.0,
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: IgnorePointer(
                                  ignoring: activeImage == null || isBusy,
                                  child: _RetakePillButton(
                                    onTap: () => context
                                        .read<ScannerViewModel>()
                                        .reiniciar(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              child: isBusy
                                  ? _AnalyzingOverlay(
                                      key: ValueKey(state.runtimeType),
                                      isCapturing: state is ScannerCapturing,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: _ErrorBannerHost(
                              errorState: state is ScannerError ? state : null,
                              reduceMotion: reduceMotion,
                              onRetry: _handleRetryTap,
                              onDismiss: () => context
                                  .read<ScannerViewModel>()
                                  .descartarError(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PantryTogglePill(
                    value: preferPantry,
                    enabled: !isBusy,
                    reduceMotion: reduceMotion,
                    onChanged: (val) => context
                        .read<ScannerViewModel>()
                        .setPreferirAlacena(val),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _DockActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Fototeca',
                            semanticsLabel: 'Elegir foto de fototeca',
                            enabled: !isBusy,
                            reduceMotion: reduceMotion,
                            onTap: _handleGalleryTap,
                          ),
                        ),
                      ),
                      _ShutterButton(
                        isBusy: isBusy,
                        reduceMotion: reduceMotion,
                        onTap: _handleShutterTap,
                      ),
                      Expanded(
                        child: Center(
                          child: _DockActionButton(
                            icon: Icons.edit_note_rounded,
                            label: 'Manual',
                            semanticsLabel: 'Armar comida manual',
                            enabled: !isBusy,
                            reduceMotion: reduceMotion,
                            onTap: _handleManualTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerTopBar extends StatelessWidget {
  final CameraPreviewController cameraController;
  final VoidCallback onClose;

  const _ScannerTopBar({required this.cameraController, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'Cerrar escáner',
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                    size: 24,
                  ),
                  onPressed: onClose,
                ),
              ),
            ),
            Text(
              'Escanear Plato',
              style: AppTextStyles.title(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.textLight,
              ),
            ),
            ListenableBuilder(
              listenable: cameraController,
              builder: (context, _) {
                if (!cameraController.isReady) {
                  return const SizedBox(width: 48, height: 48);
                }
                final flashOn = cameraController.isFlashOn;
                return Semantics(
                  button: true,
                  toggled: flashOn,
                  label: flashOn ? 'Apagar flash' : 'Encender flash',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: flashOn ? 'Apagar flash' : 'Encender flash',
                      icon: Icon(
                        flashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: flashOn
                            ? AppColors.pistachio
                            : AppColors.textMutedLight,
                        size: 22,
                      ),
                      onPressed: cameraController.toggleFlash,
                    ),
                  ),
                );
              },
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
    final borderColor = AppColors.pistachio.withValues(alpha: 0.75);
    return SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(4) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(4) : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(4)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(4)
                : Radius.zero,
          ),
          border: Border(
            top: isTop
                ? BorderSide(color: borderColor, width: 2.5)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: borderColor, width: 2.5)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: borderColor, width: 2.5)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: borderColor, width: 2.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _RetakePillButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RetakePillButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retomar foto',
      child: Material(
        color: AppColors.pistachio,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.forestDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Retomar',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyzingOverlay extends StatelessWidget {
  final bool isCapturing;

  const _AnalyzingOverlay({super.key, required this.isCapturing});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.pistachio),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCapturing ? 'Abriendo cámara...' : 'Analizando nutrientes...',
              style: AppTextStyles.title(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
            if (!isCapturing) ...[
              const SizedBox(height: 4),
              Text(
                'Esto toma unos segundos',
                style: AppTextStyles.body(
                  size: 12,
                  color: AppColors.textMutedLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBannerHost extends StatelessWidget {
  final ScannerError? errorState;
  final bool reduceMotion;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ErrorBannerHost({
    required this.errorState,
    required this.reduceMotion,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: errorState == null
          ? const SizedBox.shrink()
          : _ScannerErrorBanner(
              key: ValueKey(errorState!.message),
              error: errorState!,
              onRetry: onRetry,
              onDismiss: onDismiss,
            ),
    );
  }
}

class _ScannerErrorBanner extends StatelessWidget {
  final ScannerError error;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ScannerErrorBanner({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.errorSurfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.alertRed, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.exceedRedSoft,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.textLight,
                height: 1.3,
              ),
            ),
          ),
          if (error.imagen != null)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: AppColors.exceedRedSoft,
              ),
              onPressed: onRetry,
              child: Text(
                'Reintentar',
                style: AppTextStyles.body(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: AppColors.exceedRedSoft,
                ),
              ),
            ),
          Semantics(
            button: true,
            label: 'Descartar error',
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Cerrar aviso',
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textLight,
                  size: 18,
                ),
                onPressed: onDismiss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryTogglePill extends StatelessWidget {
  final bool value;
  final bool enabled;
  final bool reduceMotion;
  final ValueChanged<bool> onChanged;

  const _PantryTogglePill({
    required this.value,
    required this.enabled,
    required this.reduceMotion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Usar ingredientes de mi alacena',
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? () => onChanged(!value) : null,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.scannerControlDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: value
                    ? AppColors.pistachio.withValues(alpha: 0.40)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: value ? AppColors.pistachio : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usar ingredientes de mi alacena',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  activeThumbColor: AppColors.pistachio,
                  activeTrackColor: AppColors.forestDark,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool enabled;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _DockActionButton({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.enabled,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_DockActionButton> createState() => _DockActionButtonState();
}

class _DockActionButtonState extends State<_DockActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final duration = widget.reduceMotion
        ? Duration.zero
        : Duration(milliseconds: _pressed ? 120 : 180);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.4,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () {
            if (_pressed) setState(() => _pressed = false);
          },
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 68),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.scannerControlDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.textLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  final bool isBusy;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.isBusy,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isBusy;
    final duration = widget.reduceMotion
        ? Duration.zero
        : Duration(milliseconds: _pressed ? 120 : 180);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Escanear plato con cámara',
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () {
          if (_pressed) setState(() => _pressed = false);
        },
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? AppColors.textLight
                    : AppColors.textLight.withValues(alpha: 0.35),
                width: 3,
              ),
            ),
            child: AnimatedContainer(
              duration: widget.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? AppColors.pistachio : AppColors.forestDeep,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: enabled
                    ? AppColors.forestDark
                    : AppColors.textMutedLight,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
