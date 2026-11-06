import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/categoria_alacena.dart';
import '../../domain/entities/ingrediente_alacena.dart';
import '../../domain/results/alacena_result.dart';
import '../viewmodels/alacena_viewmodel.dart';
import 'categoria_dialog.dart';

class AgregarIngredienteSheet extends StatefulWidget {
  final IngredienteAlacena? ingredienteAEditar;

  const AgregarIngredienteSheet({super.key, this.ingredienteAEditar});

  static Future<void> show(
    BuildContext context, {
    IngredienteAlacena? ingredienteAEditar,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AgregarIngredienteSheet(ingredienteAEditar: ingredienteAEditar),
    );
  }

  @override
  State<AgregarIngredienteSheet> createState() =>
      _AgregarIngredienteSheetState();
}

class _AgregarIngredienteSheetState extends State<AgregarIngredienteSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _porcionCtrl;
  late final TextEditingController _caloriasCtrl;
  late final TextEditingController _proteinasCtrl;
  late final TextEditingController _carbosCtrl;
  late final TextEditingController _grasasCtrl;

  late CategoriaAlacena _categoria;
  String? _error;

  bool get _esEdicion => widget.ingredienteAEditar != null;

  @override
  void initState() {
    super.initState();
    final editar = widget.ingredienteAEditar;
    if (editar != null) {
      _nombreCtrl = TextEditingController(text: editar.nombre);
      _marcaCtrl = TextEditingController(text: editar.marca ?? '');
      _porcionCtrl = TextEditingController(
        text: editar.gramosPorcion.round().toString(),
      );
      _caloriasCtrl = TextEditingController(text: editar.calorias.toString());
      _proteinasCtrl = TextEditingController(text: editar.proteinas.toString());
      _carbosCtrl = TextEditingController(
        text: editar.carbohidratos.toString(),
      );
      _grasasCtrl = TextEditingController(text: editar.grasas.toString());
      _categoria = editar.categoria;
    } else {
      _nombreCtrl = TextEditingController();
      _marcaCtrl = TextEditingController();
      _porcionCtrl = TextEditingController(text: '100');
      _caloriasCtrl = TextEditingController();
      _proteinasCtrl = TextEditingController();
      _carbosCtrl = TextEditingController();
      _grasasCtrl = TextEditingController();
      _categoria = CategoriaAlacena.proteinas;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _marcaCtrl.dispose();
    _porcionCtrl.dispose();
    _caloriasCtrl.dispose();
    _proteinasCtrl.dispose();
    _carbosCtrl.dispose();
    _grasasCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirDialogoNuevaCategoria(BuildContext ctxPadre) async {
    final res = await CategoriaDialog.show(ctxPadre);
    if (res != null && mounted) {
      final nueva = context.read<AlacenaViewModel>().agregarCategoria(
        res.nombre,
        res.emoji,
      );
      setState(() => _categoria = nueva);
    }
  }

  void _mostrarSelectorCategorias(BuildContext context) {
    final vm = context.read<AlacenaViewModel>();
    final categorias = vm.categorias.where((c) => c.id != 'todos').toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECCIONAR CATEGORÍA',
                    style: AppTextStyles.title(
                      size: 15,
                      weight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Lista de ancho 2 columnas
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categorias.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  // Último elemento: botón para agregar nueva categoría
                  if (index == categorias.length) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(ctx);
                        _abrirDialogoNuevaCategoria(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.forestDark,
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.forestDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Nueva categoría',
                              style: AppTextStyles.body(
                                size: 12,
                                weight: FontWeight.w800,
                                color: AppColors.forestDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final cat = categorias[index];
                  final bool esSeleccionada = cat == _categoria;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() => _categoria = cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: esSeleccionada
                            ? AppColors.forestDark
                            : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: esSeleccionada
                              ? AppColors.forestDark
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                size: 12.5,
                                weight: esSeleccionada
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: esSeleccionada
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (esSeleccionada)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final marca = _marcaCtrl.text.trim();
    final porcion = double.tryParse(_porcionCtrl.text.trim()) ?? 100.0;
    final calorias = int.tryParse(_caloriasCtrl.text.trim()) ?? 0;
    final proteinas = double.tryParse(_proteinasCtrl.text.trim()) ?? 0.0;
    final carbos = double.tryParse(_carbosCtrl.text.trim()) ?? 0.0;
    final grasas = double.tryParse(_grasasCtrl.text.trim()) ?? 0.0;

    final vm = context.read<AlacenaViewModel>();
    final AlacenaResult<IngredienteAlacena> resultado;

    if (_esEdicion) {
      resultado = await vm.editarIngrediente(
        id: widget.ingredienteAEditar!.id,
        nombre: nombre,
        marca: marca.isEmpty ? null : marca,
        categoria: _categoria,
        gramosPorcion: porcion,
        calorias: calorias,
        proteinas: proteinas,
        carbohidratos: carbos,
        grasas: grasas,
      );
    } else {
      resultado = await vm.crearIngrediente(
        nombre: nombre,
        marca: marca.isEmpty ? null : marca,
        categoria: _categoria,
        gramosPorcion: porcion,
        calorias: calorias,
        proteinas: proteinas,
        carbohidratos: carbos,
        grasas: grasas,
      );
    }

    if (!mounted) return;

    switch (resultado) {
      case AlacenaExito(datos: final item):
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.forestDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                _esEdicion
                    ? 'Modificado: ${item.nombreConMarca} (${item.porcionLabel})'
                    : 'Agregado: ${item.nombreConMarca} (${item.porcionLabel})',
                style: AppTextStyles.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
      case AlacenaFallo(:final mensaje):
        setState(() => _error = mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _esEdicion
                            ? 'MODIFICAR INGREDIENTE'
                            : 'NUEVO INGREDIENTE',
                        style: AppTextStyles.title(
                          size: 16,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _esEdicion
                            ? 'Actualizá los valores de este alimento.'
                            : 'Cargá los datos según tu porción de paquete.',
                        style: AppTextStyles.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: AppColors.pistachio.withValues(alpha: 0.35),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.forestDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Text(
                                'Escáner de código de barras listo para vincular.',
                                style: AppTextStyles.body(
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.pistachio,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.forestDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.alertRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre del alimento *',
              hint: 'Ej: Pan Integral, Yogur Griego, Galletitas',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _marcaCtrl,
                    label: 'Marca (opcional)',
                    hint: 'Ej: Fargo, La Serenísima',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _porcionCtrl,
                    label: 'Porción (g) *',
                    hint: '100',
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Selector de Categoría compacto en 1 sola línea con borde verde
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoría Nutricional',
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _mostrarSelectorCategorias(context),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.forestDark.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.forestDark,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _categoria.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _categoria.label,
                              style: AppTextStyles.body(
                                size: 13,
                                weight: FontWeight.w800,
                                color: AppColors.forestDark,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Elegir',
                              style: AppTextStyles.body(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.forestDark,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.forestDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Valores Nutricionales de la Porción',
              style: AppTextStyles.body(
                size: 11.5,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _caloriasCtrl,
                    label: 'Calorías *',
                    hint: 'kcal',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _proteinasCtrl,
                    label: 'Proteínas',
                    hint: 'gramos',
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _carbosCtrl,
                    label: 'Carbos',
                    hint: 'gramos',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _grasasCtrl,
                    label: 'Grasas',
                    hint: 'gramos',
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _guardar,
                child: Text(
                  _esEdicion ? 'Guardar cambios' : 'Guardar ingrediente',
                  style: AppTextStyles.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            size: 11.5,
            weight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: AppTextStyles.body(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
