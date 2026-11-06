import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../../alacena/presentation/widgets/selector_alacena_modal.dart';
import '../../domain/entities/comida_ingrediente.dart';
import '../../domain/entities/comida_item.dart';
import '../viewmodels/diario_viewmodel.dart';

class EditarComidaSheet extends StatefulWidget {
  final ComidaItem comida;

  const EditarComidaSheet({super.key, required this.comida});

  static Future<void> show(BuildContext context, {required ComidaItem comida}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditarComidaSheet(comida: comida),
    );
  }

  @override
  State<EditarComidaSheet> createState() => _EditarComidaSheetState();
}

class _EditarComidaSheetState extends State<EditarComidaSheet> {
  late final TextEditingController _tituloCtrl;
  late List<ComidaIngrediente> _ingredientes;
  late String _tipoComida;

  final List<String> _tiposDisponibles = const [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.comida.titulo);
    _ingredientes = List<ComidaIngrediente>.from(widget.comida.ingredientes);
    _tipoComida = widget.comida.encabezadoTipo;
    if (!_tiposDisponibles.contains(_tipoComida)) {
      _tipoComida = _tiposDisponibles.first;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  int get _totalCalorias => _ingredientes.fold(0, (acc, i) => acc + i.calorias);

  double get _totalProteinas => double.parse(
    _ingredientes.fold(0.0, (acc, i) => acc + i.proteinas).toStringAsFixed(1),
  );

  double get _totalCarbos => double.parse(
    _ingredientes
        .fold(0.0, (acc, i) => acc + i.carbohidratos)
        .toStringAsFixed(1),
  );

  double get _totalGrasas => double.parse(
    _ingredientes.fold(0.0, (acc, i) => acc + i.grasas).toStringAsFixed(1),
  );

  void _ajustarGramos(int index, double delta) {
    setState(() {
      final actual = _ingredientes[index];
      final nuevosGramos = (actual.gramos + delta).clamp(5.0, 1000.0);
      _ingredientes[index] = actual.conGramos(nuevosGramos);
    });
  }

  Future<void> _editarGramosManual(int index) async {
    final ing = _ingredientes[index];
    final ctrl = TextEditingController(text: ing.gramos.round().toString());

    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cantidad en gramos',
          style: AppTextStyles.title(size: 16, weight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ing.nombreConMarca,
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: InputDecoration(
                suffixText: 'gramos',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, val);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (res != null && res > 0 && mounted) {
      setState(() {
        _ingredientes[index] = ing.conGramos(res);
      });
    }
  }

  Future<void> _sumarDesdeAlacena() async {
    final seleccionado = await SelectorAlacenaModal.show(context);
    if (seleccionado != null && mounted) {
      setState(() {
        final nuevo = ComidaIngrediente.desdeAlacena(
          alacena: seleccionado,
          gramos: seleccionado.gramosPorcion,
        );
        _ingredientes.add(nuevo);
      });
    }
  }

  void _guardar() {
    final tituloLimpio = _tituloCtrl.text.trim();
    final comidaActualizada = widget.comida.copyWith(
      titulo: tituloLimpio.isEmpty ? widget.comida.titulo : tituloLimpio,
      tipoComida: _tipoComida.toUpperCase(),
      ingredientes: _ingredientes,
    );

    context.read<DiarioViewModel>().actualizarComida(comidaActualizada);
    Navigator.pop(context); // Cierra editor

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
            'Comida modificada (${_ingredientes.length} ingredientes · $_totalCalorias kcal)',
            style: AppTextStyles.body(
              size: 13,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 14),
          // Encabezado
          Text(
            'MODIFICAR COMIDA',
            style: AppTextStyles.title(size: 16.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Ajustá ingredientes, porciones en gramos y macros.',
            style: AppTextStyles.body(size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          // Selector horizontal de Tipo de Comida
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tiposDisponibles.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tipo = _tiposDisponibles[index];
                final activo = tipo == _tipoComida;
                return ChoiceChip(
                  label: Text(tipo),
                  selected: activo,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _tipoComida = tipo);
                  },
                  selectedColor: AppColors.forestDark,
                  backgroundColor: AppColors.cardWhite,
                  labelStyle: AppTextStyles.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: activo ? Colors.white : AppColors.forestDark,
                  ),
                  side: BorderSide(
                    color: activo
                        ? AppColors.forestDark
                        : AppColors.borderLight,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Lista de Ingredientes scrolleable
          Expanded(
            child: _ingredientes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.kitchen_outlined,
                          size: 38,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay ingredientes en esta comida',
                          style: AppTextStyles.body(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _ingredientes.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _ingredientes[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombreConMarca,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(
                                      size: 13.5,
                                      weight: FontWeight.w800,
                                      color: AppColors.forestDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.calorias} kcal · P ${item.proteinas}g · C ${item.carbohidratos}g · G ${item.grasas}g',
                                    style: AppTextStyles.body(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Stepper de gramos (- / +) y tap para ingresar número exacto
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StepperBtn(
                                  icon: Icons.remove,
                                  onTap: () => _ajustarGramos(index, -10),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _editarGramosManual(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      item.porcionLabel,
                                      style: AppTextStyles.number(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: AppColors.forestDark,
                                      ),
                                    ),
                                  ),
                                ),
                                _StepperBtn(
                                  icon: Icons.add,
                                  onTap: () => _ajustarGramos(index, 10),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            // Botón borrar ingrediente
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.alertRed,
                              ),
                              onPressed: () async {
                                final confirmar = await ConfirmDeleteDialog.show(
                                  context,
                                  titulo: '¿Quitar ingrediente?',
                                  mensaje:
                                      'Se quitará "${item.nombreConMarca}" de esta comida.',
                                  textoConfirmar: 'Quitar',
                                );
                                if (confirmar && mounted) {
                                  setState(() {
                                    _ingredientes.removeAt(index);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          // Botón para sumar desde la Alacena
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forestDark,
              side: const BorderSide(color: AppColors.forestDark, width: 1.3),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              'Agregar ingrediente desde Mi Alacena',
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.forestDark,
              ),
            ),
            onPressed: _sumarDesdeAlacena,
          ),
          const SizedBox(height: 12),
          // Totales en vivo (Kcal y Macros)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.forestDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RECALCULADO',
                      style: AppTextStyles.body(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.pistachio,
                      ),
                    ),
                    Text(
                      '$_totalCalorias kcal',
                      style: AppTextStyles.number(
                        size: 18,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'P ${_totalProteinas.round()}g · C ${_totalCarbos.round()}g · G ${_totalGrasas.round()}g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botón Guardar Cambios
          SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pistachio,
                foregroundColor: AppColors.forestDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _guardar,
              child: Text(
                'Guardar cambios',
                style: AppTextStyles.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.forestDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, size: 14, color: AppColors.forestDark),
      ),
    );
  }
}
