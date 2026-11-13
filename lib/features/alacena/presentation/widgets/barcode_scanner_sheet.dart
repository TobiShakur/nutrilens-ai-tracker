import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../scanner/data/services/image_picker_capture_service_impl.dart';
import '../../../scanner/domain/services/image_capture_service.dart';
import '../../data/datasources/barcode_demo_local_datasource.dart';
import '../../data/datasources/barcode_product_service_impl.dart';
import '../../domain/datasources/barcode_demo_datasource.dart';
import '../../domain/entities/barcode_demo_chip.dart';
import '../../domain/entities/barcode_product_data.dart';
import '../../domain/services/barcode_product_service.dart';
import '../viewmodels/barcode_scanner_state.dart';
import '../viewmodels/barcode_scanner_viewmodel.dart';

/// Bottom Sheet modal interactivo para escanear productos por código de barras
/// (Open Food Facts API) o mediante fotografía de etiquetas y empaques (Gemini Vision).
class BarcodeScannerSheet extends StatelessWidget {
  const BarcodeScannerSheet({super.key});

  static Future<BarcodeProductData?> show(
    BuildContext context, {
    BarcodeScannerViewModel? viewModelOverride,
  }) {
    final Widget content;
    if (viewModelOverride != null) {
      content = ChangeNotifierProvider<BarcodeScannerViewModel>.value(
        value: viewModelOverride,
        child: const BarcodeScannerSheet(),
      );
    } else {
      final barcodeService =
          _tryRead<BarcodeProductService>(context) ??
          BarcodeProductServiceImpl();
      final imageCaptureService =
          _tryRead<ImageCaptureService>(context) ??
          ImagePickerCaptureServiceImpl();
      final demoDatasource =
          _tryRead<BarcodeDemoDatasource>(context) ??
          const BarcodeDemoLocalDatasource();

      content = ChangeNotifierProvider<BarcodeScannerViewModel>(
        create: (_) => BarcodeScannerViewModel(
          barcodeService: barcodeService,
          imageCaptureService: imageCaptureService,
          demoDatasource: demoDatasource,
        ),
        child: const BarcodeScannerSheet(),
      );
    }

    return showModalBottomSheet<BarcodeProductData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => content,
    );
  }

  static T? _tryRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            const SizedBox(height: 14),
            _SheetHeader(onClose: () => Navigator.pop(context)),
            const SizedBox(height: 16),
            const _ModeSelector(),
            const SizedBox(height: 18),
            Consumer<BarcodeScannerViewModel>(
              builder: (context, vm, _) {
                final state = vm.state;
                return switch (state) {
                  BarcodeScannerLoading(:final mensaje) => _LoadingCard(
                    mensaje: mensaje,
                  ),
                  BarcodeScannerSuccess(:final producto) => _ResultadoCard(
                    resultado: producto,
                    onUsar: () => Navigator.pop(context, producto),
                    onReintentar: () => context
                        .read<BarcodeScannerViewModel>()
                        .reiniciarEscaneo(),
                  ),
                  BarcodeScannerIdle() || BarcodeScannerError() => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.modo == ModoEscaneoProducto.camara)
                        _ModoCamaraView(
                          onCamaraTap: () => context
                              .read<BarcodeScannerViewModel>()
                              .capturarConCamara(),
                          onGaleriaTap: () => context
                              .read<BarcodeScannerViewModel>()
                              .seleccionarDeGaleria(),
                        )
                      else
                        _ModoCodigoView(
                          chips: vm.chipsDemo,
                          onBuscar: (codigo) => context
                              .read<BarcodeScannerViewModel>()
                              .buscarPorCodigoBarras(codigo),
                        ),
                      if (state case BarcodeScannerError(:final mensaje)) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(mensaje: mensaje),
                      ],
                    ],
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESCANEAR PRODUCTO',
              style: AppTextStyles.title(size: 16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Código de barras o tabla nutricional',
              style: AppTextStyles.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    final modo = context.select<BarcodeScannerViewModel, ModoEscaneoProducto>(
      (vm) => vm.modo,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Foto',
              icon: Icons.camera_alt_rounded,
              isActive: modo == ModoEscaneoProducto.camara,
              onTap: () => context.read<BarcodeScannerViewModel>().cambiarModo(
                ModoEscaneoProducto.camara,
              ),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Código de barras',
              icon: Icons.barcode_reader,
              isActive: modo == ModoEscaneoProducto.codigo,
              onTap: () => context.read<BarcodeScannerViewModel>().cambiarModo(
                ModoEscaneoProducto.codigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.forestDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive ? AppColors.pistachio : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body(
                size: 12,
                weight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String mensaje;

  const _LoadingCard({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestDark),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.forestDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String mensaje;

  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.alertRed.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.alertRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: AppTextStyles.body(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModoCamaraView extends StatelessWidget {
  final VoidCallback onCamaraTap;
  final VoidCallback onGaleriaTap;

  const _ModoCamaraView({
    required this.onCamaraTap,
    required this.onGaleriaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.forestDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: AppColors.pistachio,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sacale una foto al producto',
            textAlign: TextAlign.center,
            style: AppTextStyles.title(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Escaneá el frente del envase o la tabla nutricional para cargar sus datos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onCamaraTap,
                  icon: const Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: AppColors.pistachio,
                  ),
                  label: Text(
                    'Sacar foto',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forestDark,
                    side: const BorderSide(
                      color: AppColors.forestDark,
                      width: 1.3,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onGaleriaTap,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(
                    'Subir foto',
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModoCodigoView extends StatefulWidget {
  final List<BarcodeDemoChip> chips;
  final ValueChanged<String> onBuscar;

  const _ModoCodigoView({required this.chips, required this.onBuscar});

  @override
  State<_ModoCodigoView> createState() => _ModoCodigoViewState();
}

class _ModoCodigoViewState extends State<_ModoCodigoView> {
  final TextEditingController _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  void _enviar([String? override]) {
    FocusScope.of(context).unfocus();
    widget.onBuscar(override ?? _codigoCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: 'Ingresá el código de barras',
                  prefixIcon: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 22,
                    color: AppColors.forestDark,
                  ),
                  filled: true,
                  fillColor: AppColors.scaffoldBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.forestDark,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _enviar,
              child: const Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.pistachio,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Ejemplos rápidos:',
          style: AppTextStyles.body(
            size: 11.5,
            color: AppColors.textMuted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.chips.map((chip) {
            return ActionChip(
              backgroundColor: AppColors.scaffoldBg,
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: Text(
                '${chip.label} (${chip.codigo})',
                style: AppTextStyles.body(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.forestDark,
                ),
              ),
              onPressed: () {
                _codigoCtrl.text = chip.codigo;
                _enviar(chip.codigo);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final BarcodeProductData resultado;
  final VoidCallback onUsar;
  final VoidCallback onReintentar;

  const _ResultadoCard({
    required this.resultado,
    required this.onUsar,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pistachio, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.pistachio.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.forestDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resultado.nombre,
                      style: AppTextStyles.title(
                        size: 15,
                        weight: FontWeight.w800,
                      ),
                    ),
                    if (resultado.marca.trim().isNotEmpty &&
                        resultado.marca.trim().toLowerCase() !=
                            'sin marca') ...[
                      const SizedBox(height: 2),
                      Text(
                        resultado.marca.trim(),
                        style: AppTextStyles.body(
                          size: 12,
                          color: AppColors.textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NutrienteMini(
                  label: 'Porción',
                  valor: '${resultado.porcionGramos.round()}g',
                ),
                _NutrienteMini(
                  label: 'Calorías',
                  valor: '${resultado.calorias} kcal',
                  isBold: true,
                ),
                _NutrienteMini(label: 'Prot', valor: '${resultado.proteinas}g'),
                _NutrienteMini(
                  label: 'Carbos',
                  valor: '${resultado.carbohidratos}g',
                ),
                _NutrienteMini(label: 'Grasas', valor: '${resultado.grasas}g'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pistachio,
              foregroundColor: AppColors.forestDark,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onUsar,
            child: Text(
              'Confirmar',
              style: AppTextStyles.body(
                size: 13.5,
                weight: FontWeight.w900,
                color: AppColors.forestDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onReintentar,
            child: Text(
              'Volver a escanear',
              style: AppTextStyles.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrienteMini extends StatelessWidget {
  final String label;
  final String valor;
  final bool isBold;

  const _NutrienteMini({
    required this.label,
    required this.valor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            size: 10.5,
            color: AppColors.textMuted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: AppTextStyles.body(
            size: 12,
            weight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: AppColors.forestDark,
          ),
        ),
      ],
    );
  }
}
