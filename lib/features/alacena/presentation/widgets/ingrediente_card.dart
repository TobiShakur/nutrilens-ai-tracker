import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../domain/entities/ingrediente_alacena.dart';

class IngredienteCard extends StatelessWidget {
  final IngredienteAlacena ingrediente;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const IngredienteCard({
    super.key,
    required this.ingrediente,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(ingrediente.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.alertRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.alertRed,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              'Eliminar',
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.alertRed,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await ConfirmDeleteDialog.show(
          context,
          titulo: '¿Eliminar ingrediente?',
          mensaje: 'Se quitará "${ingrediente.nombreConMarca}" de tu alacena.',
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  ingrediente.categoria.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingrediente.nombreConMarca,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title(
                        size: 14.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pistachio.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${ingrediente.calorias} kcal / ${ingrediente.porcionLabel}',
                            style: AppTextStyles.number(
                              size: 11,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'P ${ingrediente.proteinas.round()}g · C ${ingrediente.carbohidratos.round()}g · G ${ingrediente.grasas.round()}g',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
