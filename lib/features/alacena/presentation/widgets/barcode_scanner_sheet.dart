import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/barcode_product_service_impl.dart';
import '../../domain/entities/barcode_product_data.dart';
import '../../domain/services/barcode_product_service.dart';

enum _ModoEscaneo { camara, codigo }

/// Bottom Sheet modal interactivo para escanear productos por código de barras
/// (Open Food Facts API) o mediante fotografía de etiquetas y empaques (Gemini Vision).
class BarcodeScannerSheet extends StatefulWidget {
  final BarcodeProductService? barcodeService;

  const BarcodeScannerSheet({super.key, this.barcodeService});

  static Future<BarcodeProductData?> show(
    BuildContext context, {
    BarcodeProductService? service,
  }) {
    return showModalBottomSheet<BarcodeProductData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerSheet(barcodeService: service),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final BarcodeProductService _service;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _codigoCtrl = TextEditingController();

  _ModoEscaneo _modo = _ModoEscaneo.camara;
  bool _cargando = false;
  String _mensajeCarga = '';
  String? _error;
  BarcodeProductData? _resultado;

  static const List<({String label, String codigo})> _chipsDemostracion = [
    (label: 'Nutella', codigo: '3017620422003'),
    (label: 'Coca-Cola', codigo: '5449000000996'),
    (label: 'Yogur EAN', codigo: '7790070507305'),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.barcodeService ?? BarcodeProductServiceImpl();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturarConCamara() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return;
      await _procesarBytesImagen(
        await xfile.readAsBytes(),
        xfile.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo acceder a la cámara: $e');
    }
  }

  Future<void> _elegirDeGaleria() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return;
      await _procesarBytesImagen(
        await xfile.readAsBytes(),
        xfile.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo abrir la galería: $e');
    }
  }

  Future<void> _procesarBytesImagen(Uint8List bytes, String mimeType) async {
    setState(() {
      _cargando = true;
      _mensajeCarga = 'Analizando código y tabla nutricional con IA...';
      _error = null;
      _resultado = null;
    });

    try {
      final data = await _service.analizarFotoEtiqueta(
        bytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;
      if (data == null) {
        setState(() {
          _cargando = false;
          _error =
              'No se pudo detectar un producto legible. Probá enfocando mejor la tabla nutricional o el código.';
        });
      } else {
        setState(() {
          _cargando = false;
          _resultado = data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Ocurrió un error al procesar la imagen: $e';
      });
    }
  }

  Future<void> _buscarCodigoManual([String? codigoOverride]) async {
    final codigo = (codigoOverride ?? _codigoCtrl.text).trim();
    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresá los números del código de barras.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _mensajeCarga = 'Consultando base de alimentos Open Food Facts...';
      _error = null;
      _resultado = null;
    });

    try {
      final data = await _service.buscarPorCodigoBarras(codigo);

      if (!mounted) return;
      if (data == null) {
        setState(() {
          _cargando = false;
          _error =
              'No encontramos el producto con código $codigo en la base de datos.';
        });
      } else {
        setState(() {
          _cargando = false;
          _resultado = data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Error de conexión: $e';
      });
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
            // Indicador de arrastre superior
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESCANEAR PRODUCTO',
                      style: AppTextStyles.title(
                        size: 16,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Código de barras o tabla nutricional',
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de pestaña (Foto con IA vs Código Manual)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Cámara / Foto (IA)',
                      icon: Icons.camera_alt_rounded,
                      isActive: _modo == _ModoEscaneo.camara,
                      onTap: () => setState(() {
                        _modo = _ModoEscaneo.camara;
                        _error = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Código de Barras',
                      icon: Icons.barcode_reader,
                      isActive: _modo == _ModoEscaneo.codigo,
                      onTap: () => setState(() {
                        _modo = _ModoEscaneo.codigo;
                        _error = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Contenido según el modo o resultado
            if (_cargando) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.forestDark,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mensajeCarga,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_resultado != null) ...[
              _ResultadoCard(
                resultado: _resultado!,
                onUsar: () => Navigator.pop(context, _resultado),
                onReintentar: () => setState(() {
                  _resultado = null;
                  _error = null;
                }),
              ),
            ] else if (_modo == _ModoEscaneo.camara) ...[
              _ModoCamaraView(
                onCamaraTap: _capturarConCamara,
                onGaleriaTap: _elegirDeGaleria,
              ),
            ] else ...[
              _ModoCodigoView(
                controller: _codigoCtrl,
                chips: _chipsDemostracion,
                onBuscar: () => _buscarCodigoManual(),
                onChipTap: (cod) {
                  _codigoCtrl.text = cod;
                  _buscarCodigoManual(cod);
                },
              ),
            ],

            if (_error != null && !_cargando && _resultado == null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE57373), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFC62828),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
            'Enfocá el empaque o la tabla nutricional',
            textAlign: TextAlign.center,
            style: AppTextStyles.title(size: 14, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Gemini Vision leerá el código impreso, nombre, porción y macronutrientes al instante.',
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
                    'Galería',
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

class _ModoCodigoView extends StatelessWidget {
  final TextEditingController controller;
  final List<({String label, String codigo})> chips;
  final VoidCallback onBuscar;
  final ValueChanged<String> onChipTap;

  const _ModoCodigoView({
    required this.controller,
    required this.chips,
    required this.onBuscar,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onBuscar(),
                decoration: InputDecoration(
                  hintText: 'Ej: 7790070507305 o 3017620422003',
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
              onPressed: onBuscar,
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
          'O probá con estos alimentos de muestra:',
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
          children: chips.map((chip) {
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
              onPressed: () => onChipTap(chip.codigo),
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
                    if (resultado.marca.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Marca: ${resultado.marca}',
                        style: AppTextStyles.body(
                          size: 12,
                          color: AppColors.textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forestDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✓ ${resultado.fuente}',
                        style: AppTextStyles.body(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.pistachio,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges de información nutricional
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
              'Autocompletar en mi Ingrediente',
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
              'Escanear o buscar otro producto',
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
