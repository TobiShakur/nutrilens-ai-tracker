import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../domain/entities/comida_item.dart';
import 'health_score_badge.dart';

class MealCardWidget extends StatelessWidget {
  final ComidaItem comida;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onScoreTap;
  final bool isEvaluatingScore;
  final bool hasScoreError;

  const MealCardWidget({
    super.key,
    required this.comida,
    required this.onDelete,
    this.onTap,
    this.onScoreTap,
    this.isEvaluatingScore = false,
    this.hasScoreError = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mealDisplayName = localizedMealType(comida.encabezadoTipo, l10n);
    return Dismissible(
      key: Key('meal_card_${comida.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.alertRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.delete,
              style: AppTextStyles.body(
                size: 13,
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
          titulo: l10n.deleteMealTitle,
          mensaje: l10n.deleteMealMessage(mealDisplayName),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Ícono contorneado de comida / bebida estilo referencia
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      comida.icono,
                      color: AppColors.forestDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título superior, badge Health Score, kcal y lista de alimentos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                mealDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title(
                                  size: 15.5,
                                  weight: FontWeight.w900,
                                  color: AppColors.forestDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            HealthScoreBadge(
                              healthScore: comida.healthScore,
                              isStale: comida.healthScoreDesactualizado,
                              isLoading: isEvaluatingScore,
                              hasError: hasScoreError,
                              compact: true,
                              onTap: onScoreTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comida.metaCalorias != null
                              ? '${comida.calorias} / ${comida.metaCalorias} kcal'
                              : '${comida.calorias} kcal',
                          style: AppTextStyles.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.forestDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comida.detalleComida,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flecha chevron sutil para indicar apertura de detalle
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 22,
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
