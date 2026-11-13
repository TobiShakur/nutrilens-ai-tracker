import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../../alacena/presentation/widgets/selector_alacena_modal.dart';
import '../../domain/entities/comida_ingrediente.dart';
import '../../domain/entities/comida_item.dart';
import '../../domain/usecases/evaluate_meal_health_usecase.dart';
import '../viewmodels/diario_viewmodel.dart';
import '../viewmodels/editar_comida_viewmodel.dart';
import '../viewmodels/health_score_eval_state.dart';
import 'health_score_badge.dart';
import 'health_score_detail_sheet.dart';

class EditarComidaSheet extends StatefulWidget {
  final ComidaItem comida;

  const EditarComidaSheet({super.key, required this.comida});

  static Future<void> show(
    BuildContext context, {
    required ComidaItem comida,
    EditarComidaViewModel? viewModelOverride,
  }) {
    final evaluateUseCase = _tryReadEvaluateUseCase(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => viewModelOverride != null
          ? ChangeNotifierProvider<EditarComidaViewModel>.value(
              value: viewModelOverride,
              child: EditarComidaSheet(comida: comida),
            )
          : ChangeNotifierProvider<EditarComidaViewModel>(
              create: (_) => EditarComidaViewModel(
                comida: comida,
                evaluateMealHealthUseCase: evaluateUseCase,
              ),
              child: EditarComidaSheet(comida: comida),
            ),
    );
  }

  static EvaluateMealHealthUseCase? _tryReadEvaluateUseCase(
    BuildContext context,
  ) {
    try {
      return context.read<EvaluateMealHealthUseCase>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  State<EditarComidaSheet> createState() => _EditarComidaSheetState();
}

class _EditarComidaSheetState extends State<EditarComidaSheet> {
  late final TextEditingController _tituloCtrl;
  EditarComidaViewModel? _fallbackVm;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.comida.titulo);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _fallbackVm?.dispose();
    super.dispose();
  }

  EditarComidaViewModel _resolveViewModel(BuildContext context) {
    try {
      return Provider.of<EditarComidaViewModel>(context, listen: true);
    } on ProviderNotFoundException {
      return _fallbackVm ??= EditarComidaViewModel(comida: widget.comida);
    }
  }

  Future<void> _editarGramosManual(
    EditarComidaViewModel vm,
    int index,
    ComidaIngrediente ing,
  ) async {
    final res = await showDialog<double>(
      context: context,
      builder: (_) => _EditGramsDialog(
        ingredientName: ing.nombreConMarca,
        initialGrams: ing.gramos,
      ),
    );

    if (res != null && res > 0 && mounted) {
      vm.fijarGramos(index, res);
    }
  }

  Future<void> _sumarDesdeAlacena(EditarComidaViewModel vm) async {
    final seleccionado = await SelectorAlacenaModal.show(context);
    if (seleccionado != null && mounted) {
      vm.agregarIngrediente(seleccionado, seleccionado.gramosPorcion);
    }
  }

  void _guardar(EditarComidaViewModel vm) {
    vm.setTitulo(_tituloCtrl.text);
    final comidaActualizada = vm.buildUpdatedComida();
    final totalCalorias = vm.totalCalorias;
    final totalIngredientes = vm.ingredientes.length;

    context.read<DiarioViewModel>().actualizarComida(comidaActualizada);
    Navigator.pop(context); // Cierra editor

    if (mounted) {
      final l10n = context.l10n;
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
              l10n.mealUpdatedSnackbar(totalIngredientes, totalCalorias),
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = _resolveViewModel(context);
    final ingredientes = vm.ingredientes;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editMealTitle,
                      style: AppTextStyles.title(
                        size: 17,
                        weight: FontWeight.w800,
                        color: AppColors.forestDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.editMealSubtitle,
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textMutedAccessible,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HealthScoreBadge(
                healthScore: vm.healthScore,
                isStale: vm.healthScoreDesactualizado,
                isLoading: vm.healthScoreEvalState is HealthScoreEvaluating,
                hasError: vm.healthScoreEvalState is HealthScoreEvalError,
                onTap: () {
                  final lang = context.activeLanguageCode;
                  HealthScoreDetailSheet.show(
                    context,
                    listenable: vm,
                    readSnapshot: () => vm.healthScoreSnapshot,
                    onEvaluate: () => vm.evaluarHealthScore(languageCode: lang),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Selector horizontal de Tipo de Comida
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: EditarComidaViewModel.availableMealTypes.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tipo = EditarComidaViewModel.availableMealTypes[index];
                final activo = tipo == vm.tipoComida;
                return ChoiceChip(
                  label: Text(localizedMealType(tipo, l10n)),
                  selected: activo,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) vm.setTipoComida(tipo);
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
            child: ingredientes.isEmpty
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
                          l10n.editMealNoIngredients,
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
                    itemCount: ingredientes.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = ingredientes[index];
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StepperBtn(
                                  icon: Icons.remove,
                                  onTap: () => vm.ajustarGramos(index, -10),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      _editarGramosManual(vm, index, item),
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
                                  onTap: () => vm.ajustarGramos(index, 10),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.alertRed,
                              ),
                              onPressed: () async {
                                final confirmar =
                                    await ConfirmDeleteDialog.show(
                                      context,
                                      titulo: l10n.removeIngredientTitle,
                                      mensaje: l10n.removeIngredientMessage(
                                        item.nombreConMarca,
                                      ),
                                      textoConfirmar: l10n.remove,
                                    );
                                if (confirmar && mounted) {
                                  vm.eliminarIngrediente(index);
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
              l10n.addIngredientFromPantry,
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.forestDark,
              ),
            ),
            onPressed: () => _sumarDesdeAlacena(vm),
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
                      l10n.recalculatedTotal,
                      style: AppTextStyles.body(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.pistachio,
                      ),
                    ),
                    Text(
                      '${vm.totalCalorias} ${l10n.kcalUnit}',
                      style: AppTextStyles.number(
                        size: 18,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${l10n.macroProteinShort[0]} ${vm.totalProteinas.round()}g · ${l10n.macroCarbsShort[0]} ${vm.totalCarbos.round()}g · ${l10n.macroFatShort[0]} ${vm.totalGrasas.round()}g',
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
              onPressed: () => _guardar(vm),
              child: Text(
                l10n.saveChanges,
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

class _EditGramsDialog extends StatefulWidget {
  final String ingredientName;
  final double initialGrams;

  const _EditGramsDialog({
    required this.ingredientName,
    required this.initialGrams,
  });

  @override
  State<_EditGramsDialog> createState() => _EditGramsDialogState();
}

class _EditGramsDialogState extends State<_EditGramsDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialGrams.round().toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.gramsAmountTitle,
        style: AppTextStyles.title(size: 16, weight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.ingredientName,
            style: AppTextStyles.body(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              suffixText: l10n.gramsUnit,
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
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
            final val = double.tryParse(_ctrl.text.trim());
            Navigator.pop(context, val);
          },
          child: Text(l10n.apply),
        ),
      ],
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
