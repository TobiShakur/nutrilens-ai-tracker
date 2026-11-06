import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../../alacena/presentation/widgets/selector_alacena_modal.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../../diario/domain/entities/comida_item.dart';
import '../../../diario/presentation/viewmodels/diario_viewmodel.dart';
import '../../domain/entities/plato_detectado.dart';
import '../viewmodels/scanner_viewmodel.dart';

class ReviewComidaSheet extends StatefulWidget {
  final int numeroComidaDefault;

  const ReviewComidaSheet({super.key, required this.numeroComidaDefault});

  static Future<bool?> show(
    BuildContext context, {
    required int numeroComidaDefault,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReviewComidaSheet(numeroComidaDefault: numeroComidaDefault),
    );
  }

  @override
  State<ReviewComidaSheet> createState() => _ReviewComidaSheetState();
}

class _ReviewComidaSheetState extends State<ReviewComidaSheet> {
  late String _titulo;
  String _tipoSeleccionado = 'Almuerzo';

  final List<String> _tipos = const [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _titulo = 'Comida ${widget.numeroComidaDefault}';
  }

  Future<void> _editarTitulo() async {
    final ctrl = TextEditingController(text: _titulo);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nombre de la comida',
          style: AppTextStyles.title(size: 16.5, weight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTextStyles.body(size: 14, weight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Ej: Almuerzo liviano, Bowl post entreno',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevo != null && nuevo.isNotEmpty && mounted) {
      setState(() => _titulo = nuevo);
    }
  }

  Future<void> _editarGramosManual(ComidaIngrediente item) async {
    final ctrl = TextEditingController(text: item.gramos.round().toString());
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
              item.nombreConMarca,
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
      context.read<ScannerViewModel>().fijarGramosIngrediente(item.id, res);
    }
  }

  Future<void> _agregarDesdeAlacena() async {
    final seleccionado = await SelectorAlacenaModal.show(context);
    if (seleccionado != null && mounted) {
      context.read<ScannerViewModel>().agregarIngredienteDesdeAlacena(
        seleccionado,
        seleccionado.gramosPorcion,
      );
    }
  }

  void _confirmarAgregarComida() {
    final scanVM = context.read<ScannerViewModel>();
    final plato = scanVM.platoDetectado;
    if (plato == null || plato.ingredientes.isEmpty) return;

    final comida = ComidaItem(
      id: 'comida_${DateTime.now().microsecondsSinceEpoch}',
      titulo: _titulo,
      tipoComida: _tipoSeleccionado.toUpperCase(),
      descripcion: plato.nombreSugerido,
      healthScore: plato.healthScore,
      explicacionHealthScore: plato.explicacionHealthScore,
      hora:
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      icono: Icons.restaurant_outlined,
      ingredientes: plato.ingredientes,
    );

    context.read<DiarioViewModel>().registrarComida(comida);
    scanVM.reiniciar();
    Navigator.pop(context, true); // Devuelve true a la pantalla anterior

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
            '¡$_titulo agregada! (+${comida.calorias} kcal)',
            style: AppTextStyles.body(
              size: 13,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  void _mostrarExplicacionScore(BuildContext context, PlatoDetectado plato) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF27AE60),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Score · ${plato.healthScore}/100',
                        style: AppTextStyles.title(
                          size: 16,
                          weight: FontWeight.w900,
                          color: AppColors.forestDark,
                        ),
                      ),
                      Text(
                        'Evaluación nutricional de Gemini IA',
                        style: AppTextStyles.body(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                plato.explicacionHealthScore.trim().isNotEmpty
                    ? plato.explicacionHealthScore.trim()
                    : 'Aporte balanceado de nutrientes, con predominancia de alimentos reales y bajo nivel de ultraprocesados.',
                style: AppTextStyles.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.forestDark,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Entendido',
                  style: AppTextStyles.body(
                    size: 13.5,
                    weight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    final scanVM = context.watch<ScannerViewModel>();
    final plato = scanVM.platoDetectado;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (plato == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Título de la comida con lápiz a la derecha de todo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title(
                          size: 18,
                          weight: FontWeight.w900,
                          color: AppColors.forestDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _mostrarExplicacionScore(context, plato),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestDark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.pistachio.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: Color(0xFF27AE60),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Score ${plato.healthScore}/100',
                              style: AppTextStyles.body(
                                size: 11,
                                weight: FontWeight.w800,
                                color: AppColors.forestDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.help_outline_rounded,
                              size: 12.5,
                              color: AppColors.forestDark.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.forestDark,
                ),
                tooltip: 'Cambiar nombre',
                onPressed: _editarTitulo,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Selector horizontal de Tipo de Comida
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tipos.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final t = _tipos[index];
                final activo = t == _tipoSeleccionado;
                return ChoiceChip(
                  label: Text(t),
                  selected: activo,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _tipoSeleccionado = t);
                  },
                  selectedColor: AppColors.forestDark,
                  backgroundColor: AppColors.scaffoldBg,
                  labelStyle: AppTextStyles.body(
                    size: 11.5,
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
          const SizedBox(height: 14),
          // Resumen de Energía y Macros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.forestDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DETECTADO',
                      style: AppTextStyles.body(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.pistachio,
                      ),
                    ),
                    Text(
                      '${plato.totalCalorias} kcal',
                      style: AppTextStyles.number(
                        size: 22,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'P ${plato.totalProteinas.round()}g · C ${plato.totalCarbos.round()}g · G ${plato.totalGrasas.round()}g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Encabezado de la lista
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredientes detectados (${plato.ingredientes.length})',
                style: AppTextStyles.title(size: 14, weight: FontWeight.w800),
              ),
              Text(
                'Deslizá para quitar',
                style: AppTextStyles.body(size: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Lista vertical simple de ingredientes con swipe-to-delete
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: plato.ingredientes.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = plato.ingredientes[index];
                final vieneDeAlacena = item.ingredienteAlacenaId != null;

                return Dismissible(
                  key: ValueKey('review_ing_${item.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quitar',
                          style: AppTextStyles.body(
                            size: 12,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await ConfirmDeleteDialog.show(
                      context,
                      titulo: '¿Quitar ingrediente?',
                      mensaje:
                          'Se quitará "${item.nombreConMarca}" de esta comida.',
                      textoConfirmar: 'Quitar',
                    );
                  },
                  onDismissed: (_) {
                    scanVM.eliminarIngrediente(item.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.nombreConMarca,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: AppColors.forestDark,
                                      ),
                                    ),
                                  ),
                                  if (vieneDeAlacena) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pistachio.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Alacena',
                                        style: AppTextStyles.body(
                                          size: 9.5,
                                          weight: FontWeight.w800,
                                          color: AppColors.forestDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
                        const SizedBox(width: 6),
                        // Controles de porción: (-) 100g (+)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SmallStepBtn(
                              icon: Icons.remove,
                              onTap: () =>
                                  scanVM.ajustarGramosIngrediente(item.id, -10),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _editarGramosManual(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  item.porcionLabel,
                                  style: AppTextStyles.number(
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    color: AppColors.forestDark,
                                  ),
                                ),
                              ),
                            ),
                            _SmallStepBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  scanVM.ajustarGramosIngrediente(item.id, 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Botón para agregar ingredientes desde la Alacena
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
            onPressed: _agregarDesdeAlacena,
          ),
          const SizedBox(height: 12),
          // Botón flotante inferior para confirmar y agregar comida
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pistachio,
                foregroundColor: AppColors.forestDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _confirmarAgregarComida,
              child: Text(
                'Agregar comida',
                style: AppTextStyles.body(
                  size: 15,
                  weight: FontWeight.w900,
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

class _SmallStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, size: 13, color: AppColors.forestDark),
      ),
    );
  }
}
