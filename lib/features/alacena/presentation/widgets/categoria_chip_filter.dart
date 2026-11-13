import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/categoria_alacena.dart';

class CategoriaChipFilter extends StatelessWidget {
  final List<CategoriaAlacena> categorias;
  final CategoriaAlacena seleccionada;
  final ValueChanged<CategoriaAlacena> onSelected;
  final void Function(CategoriaAlacena cat)? onLongPress;
  final VoidCallback? onAddCustom;

  const CategoriaChipFilter({
    super.key,
    required this.categorias,
    required this.seleccionada,
    required this.onSelected,
    this.onLongPress,
    this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = categorias.length + (onAddCustom != null ? 1 : 0);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: total,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == categorias.length && onAddCustom != null) {
            return GestureDetector(
              onTap: onAddCustom,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.forestDark.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.forestDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.add,
                      style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final cat = categorias[index];
          final bool esActivo = cat == seleccionada;

          return GestureDetector(
            onTap: () => onSelected(cat),
            onLongPress: cat.id == 'todos'
                ? null
                : () => onLongPress?.call(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: esActivo ? AppColors.forestDark : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esActivo
                      ? AppColors.forestDark
                      : AppColors.borderLight,
                  width: 1.2,
                ),
                boxShadow: esActivo
                    ? [
                        BoxShadow(
                          color: AppColors.forestDark.withValues(alpha: 0.20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    localizedCategoriaLabel(cat, l10n),
                    style: AppTextStyles.body(
                      size: 12.5,
                      weight: esActivo ? FontWeight.w800 : FontWeight.w600,
                      color: esActivo ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
