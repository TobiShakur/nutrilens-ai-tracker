import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../domain/entities/alimento_conflicto_marca.dart';

class ConflictoMarcaDialog extends StatelessWidget {
  final AlimentoConflictoMarca conflicto;

  const ConflictoMarcaDialog({super.key, required this.conflicto});

  static Future<IngredienteAlacena?> show(
    BuildContext context, {
    required AlimentoConflictoMarca conflicto,
  }) {
    return showDialog<IngredienteAlacena>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConflictoMarcaDialog(conflicto: conflicto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                color: AppColors.forestDark,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.brandConflictTitle,
                  style: AppTextStyles.title(
                    size: 16.5,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.brandConflictMessage(conflicto.nombreGenerico),
            style: AppTextStyles.body(
              size: 12.5,
              color: AppColors.textMuted,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: conflicto.opcionesAlacena.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final opcion = conflicto.opcionesAlacena[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context, opcion),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: Row(
                  children: [
                    Text(
                      opcion.categoria.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opcion.nombreConMarca,
                            style: AppTextStyles.body(
                              size: 13.5,
                              weight: FontWeight.w800,
                              color: AppColors.forestDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.brandConflictOptionMacros(
                              opcion.calorias,
                              opcion.porcionLabel,
                              opcion.proteinas.round(),
                              opcion.carbohidratos.round(),
                              opcion.grasas.round(),
                            ),
                            style: AppTextStyles.body(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.forestDark,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
