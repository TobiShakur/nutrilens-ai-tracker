import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../domain/entities/ingrediente_alacena.dart';
import '../viewmodels/alacena_viewmodel.dart';
import 'agregar_ingrediente_sheet.dart';

class DetalleIngredienteSheet extends StatelessWidget {
  final IngredienteAlacena ingrediente;

  const DetalleIngredienteSheet({super.key, required this.ingrediente});

  static Future<void> show(
    BuildContext context,
    IngredienteAlacena ingrediente,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleIngredienteSheet(ingrediente: ingrediente),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final l10n = context.l10n;
    final confirmado = await ConfirmDeleteDialog.show(
      context,
      titulo: l10n.deleteIngredientTitle,
      mensaje: l10n.deleteIngredientMessage(ingrediente.nombreConMarca),
    );
    if (confirmado && context.mounted) {
      await context.read<AlacenaViewModel>().borrarIngrediente(ingrediente.id);
      if (context.mounted) {
        Navigator.pop(context); // Cierra el bottom sheet
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool esPorcion100 = ingrediente.gramosPorcion == 100.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
          const SizedBox(height: 14),
          // Header minimalista con emoji y nombre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  ingrediente.categoria.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingrediente.nombreConMarca,
                      style: AppTextStyles.title(
                        size: 16.5,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            localizedCategoriaLabel(
                              ingrediente.categoria,
                              l10n,
                            ),
                            style: AppTextStyles.body(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.ingredientPortionLabel(ingrediente.porcionLabel),
                          style: AppTextStyles.body(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Bloque de Calorías destacado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ingredientPortionEnergy,
                      style: AppTextStyles.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${ingrediente.calorias}',
                          style: AppTextStyles.number(
                            size: 28,
                            weight: FontWeight.w900,
                            color: AppColors.forestDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.kcalUnit,
                          style: AppTextStyles.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pistachio.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ingrediente.porcionLabel,
                    style: AppTextStyles.number(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 3 Pastillas de Macros
          Row(
            children: [
              Expanded(
                child: _MacroPill(
                  label: l10n.macroProtein,
                  value: '${ingrediente.proteinas.toStringAsFixed(1)}g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: l10n.macroCarbs,
                  value: '${ingrediente.carbohidratos.toStringAsFixed(1)}g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPill(
                  label: l10n.macroFat,
                  value: '${ingrediente.grasas.toStringAsFixed(1)}g',
                ),
              ),
            ],
          ),
          if (!esPorcion100) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                l10n.ingredientPer100g(
                  ingrediente.caloriasPor100g,
                  ingrediente.proteinasPor100g.round(),
                  ingrediente.carbohidratosPor100g.round(),
                  ingrediente.grasasPor100g.round(),
                ),
                style: AppTextStyles.body(size: 11, color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Acciones: Modificar y Eliminar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forestDark,
                    side: const BorderSide(
                      color: AppColors.forestDark,
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    l10n.edit,
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    AgregarIngredienteSheet.show(
                      context,
                      ingredienteAEditar: ingrediente,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alertRed,
                    side: BorderSide(
                      color: AppColors.alertRed.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    l10n.delete,
                    style: AppTextStyles.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AppColors.alertRed,
                    ),
                  ),
                  onPressed: () => _confirmarEliminar(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;

  const _MacroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.number(
              size: 14,
              weight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
