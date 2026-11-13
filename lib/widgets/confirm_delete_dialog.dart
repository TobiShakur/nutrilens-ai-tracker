import 'package:flutter/material.dart';
import '../core/localization/l10n_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ConfirmDeleteDialog {
  static Future<bool> show(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String? textoConfirmar,
    String? textoCancelar,
  }) async {
    final l10n = context.l10n;
    final confirmLabel = textoConfirmar ?? l10n.delete;
    final cancelLabel = textoCancelar ?? l10n.cancel;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          titulo,
          style: AppTextStyles.title(size: 16.5, weight: FontWeight.w800),
        ),
        content: Text(
          mensaje,
          style: AppTextStyles.body(
            size: 13.5,
            color: AppColors.textMuted,
            weight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelLabel,
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: AppTextStyles.body(
                size: 13,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }
}
