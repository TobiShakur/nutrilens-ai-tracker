import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../../alacena/presentation/widgets/selector_alacena_modal.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../../diario/presentation/viewmodels/diario_viewmodel.dart';
import '../../../diario/presentation/viewmodels/health_score_eval_state.dart';
import '../../../diario/presentation/widgets/health_score_badge.dart';
import '../../../diario/presentation/widgets/health_score_detail_sheet.dart';
import '../viewmodels/scanner_state.dart';
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
  String _titulo = '';
  bool _hasCustomTitle = false;
  String _tipoSeleccionado = 'Almuerzo';

  final List<String> _tipos = const [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Snack',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCustomTitle) {
      _titulo = context.l10n.reviewDefaultMealTitle(widget.numeroComidaDefault);
    }
  }

  Future<void> _editarTitulo() async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _EditMealTitleDialog(initialTitle: _titulo),
    );

    if (updated != null && updated.isNotEmpty && mounted) {
      setState(() {
        _hasCustomTitle = true;
        _titulo = updated;
      });
    }
  }

  Future<void> _editarGramosManual(ComidaIngrediente item) async {
    final res = await showDialog<double>(
      context: context,
      builder: (_) => _EditGramsDialog(
        ingredientName: item.nombreConMarca,
        initialGrams: item.gramos,
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
    final comida = scanVM.construirComidaParaDiario(
      titulo: _titulo,
      tipoComida: _tipoSeleccionado,
    );
    if (comida == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    context.read<DiarioViewModel>().registrarComida(comida);
    Navigator.pop(context, true);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forestDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            l10n.reviewMealAddedSnackbar(_titulo, comida.calorias),
            style: AppTextStyles.body(
              size: 13,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  void _openHealthScoreDetail(BuildContext context) {
    final scanVM = context.read<ScannerViewModel>();
    final languageCode = context.activeLanguageCode;
    HealthScoreDetailSheet.show(
      context,
      listenable: scanVM,
      readSnapshot: () {
        final s = scanVM.state;
        if (s is! ScannerSuccess) {
          return const HealthScoreSheetSnapshot(
            healthScore: null,
            razonHealthScore: null,
            isStale: false,
            hasIngredients: false,
            evalState: HealthScoreEvalIdle(),
          );
        }
        return HealthScoreSheetSnapshot(
          healthScore: s.plato.healthScore,
          razonHealthScore: s.plato.explicacionHealthScore,
          isStale: s.healthScoreDesactualizado,
          hasIngredients: s.plato.ingredientes.isNotEmpty,
          evalState: s.healthScoreEvalState,
        );
      },
      onEvaluate: () => scanVM.evaluarHealthScore(
        titulo: _titulo,
        languageCode: languageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.select<ScannerViewModel, ScannerState>(
      (vm) => vm.state,
    );
    if (state is! ScannerSuccess) {
      return const SizedBox.shrink();
    }

    final plato = state.plato;
    final esManual = state.esManual;
    final hasIngredients = plato.ingredientes.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        HealthScoreBadge(
                          healthScore: plato.healthScore,
                          isStale: state.healthScoreDesactualizado,
                          isLoading:
                              state.healthScoreEvalState
                                  is HealthScoreEvaluating,
                          hasError:
                              state.healthScoreEvalState
                                  is HealthScoreEvalError,
                          onTap: () => _openHealthScoreDetail(context),
                        ),
                      ],
                    ),
                    if (esManual) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.reviewManualBuildTag,
                        style: AppTextStyles.body(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: AppColors.textMutedAccessible,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.forestDark,
                  ),
                  tooltip: l10n.reviewChangeNameTooltip,
                  onPressed: _editarTitulo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  label: Text(localizedMealType(t, l10n)),
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
                      esManual
                          ? l10n.reviewManualTotal
                          : l10n.reviewDetectedTotal,
                      style: AppTextStyles.body(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.pistachio,
                      ),
                    ),
                    Text(
                      '${plato.totalCalorias} ${l10n.kcalUnit}',
                      style: AppTextStyles.number(
                        size: 22,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'P ${plato.totalProteinas.round()}g · C ${plato.totalCarbos.round()}g · ${l10n.macroFatShort[0]} ${plato.totalGrasas.round()}g',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                esManual
                    ? l10n.reviewIngredientsCount(plato.ingredientes.length)
                    : l10n.reviewDetectedIngredientsCount(
                        plato.ingredientes.length,
                      ),
                style: AppTextStyles.title(size: 14, weight: FontWeight.w800),
              ),
              if (hasIngredients)
                Text(
                  l10n.reviewSwipeToRemove,
                  style: AppTextStyles.body(
                    size: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hasIngredients
                ? ListView.separated(
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
                          context.read<ScannerViewModel>().eliminarIngrediente(
                            item.id,
                          );
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
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
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
                                              color: AppColors.pistachio
                                                  .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              l10n.pantryTag,
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
                                      '${item.calorias} ${l10n.kcalUnit} · P ${item.proteinas}g · C ${item.carbohidratos}g · ${l10n.macroFatShort[0]} ${item.grasas}g',
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SmallStepBtn(
                                    icon: Icons.remove,
                                    onTap: () => context
                                        .read<ScannerViewModel>()
                                        .ajustarGramosIngrediente(item.id, -10),
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
                                    onTap: () => context
                                        .read<ScannerViewModel>()
                                        .ajustarGramosIngrediente(item.id, 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const _EmptyIngredientsPlaceholder(),
          ),
          const SizedBox(height: 8),
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
            onPressed: _agregarDesdeAlacena,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pistachio,
                foregroundColor: AppColors.forestDark,
                disabledBackgroundColor: AppColors.borderLight,
                disabledForegroundColor: AppColors.textMutedAccessible,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: hasIngredients ? _confirmarAgregarComida : null,
              child: Text(
                l10n.reviewAddMealBtn,
                style: AppTextStyles.body(
                  size: 15,
                  weight: FontWeight.w900,
                  color: hasIngredients
                      ? AppColors.forestDark
                      : AppColors.textMutedAccessible,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyIngredientsPlaceholder extends StatelessWidget {
  const _EmptyIngredientsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                size: 30,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reviewNoIngredientsTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.title(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.forestDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reviewNoIngredientsSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  size: 12,
                  color: AppColors.textMutedAccessible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditMealTitleDialog extends StatefulWidget {
  final String initialTitle;

  const _EditMealTitleDialog({required this.initialTitle});

  @override
  State<_EditMealTitleDialog> createState() => _EditMealTitleDialogState();
}

class _EditMealTitleDialogState extends State<_EditMealTitleDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTitle);
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
        l10n.reviewMealNameTitle,
        style: AppTextStyles.title(size: 16.5, weight: FontWeight.w800),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: AppTextStyles.body(size: 14, weight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: l10n.reviewMealNameHint,
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
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
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(l10n.save),
        ),
      ],
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
