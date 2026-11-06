import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/categoria_alacena.dart';

class CategoriaDialog extends StatefulWidget {
  final CategoriaAlacena? categoriaAEditar;

  const CategoriaDialog({super.key, this.categoriaAEditar});

  static Future<CategoriaAlacenaData?> show(
    BuildContext context, {
    CategoriaAlacena? categoriaAEditar,
  }) {
    return showDialog<CategoriaAlacenaData>(
      context: context,
      builder: (_) => CategoriaDialog(categoriaAEditar: categoriaAEditar),
    );
  }

  @override
  State<CategoriaDialog> createState() => _CategoriaDialogState();
}

class CategoriaAlacenaData {
  final String nombre;
  final String emoji;
  const CategoriaAlacenaData({required this.nombre, required this.emoji});
}

class _CategoriaDialogState extends State<CategoriaDialog> {
  late final TextEditingController _nombreCtrl;
  late String _emojiSeleccionado;

  static const List<String> _emojisComida = [
    '🥩',
    '🍞',
    '🧀',
    '🥑',
    '🥦',
    '🧂',
    '🍎',
    '🍌',
    '🍗',
    '🐟',
    '🍚',
    '🍝',
    '🥛',
    '🍳',
    '🥕',
    '🥜',
    '🍫',
    '☕',
    '🥤',
    '🥫',
    '🍯',
    '🥞',
    '🥙',
    '🍣',
    '🍕',
    '🥗',
    '🍪',
    '💊',
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(
      text: widget.categoriaAEditar?.label ?? '',
    );
    _emojiSeleccionado = widget.categoriaAEditar?.emoji ?? '🍎';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.categoriaAEditar != null;

    return AlertDialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
        style: AppTextStyles.title(size: 16.5, weight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _emojiSeleccionado,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nombreCtrl,
                    autofocus: true,
                    style: AppTextStyles.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej: Suplementos, Snacks',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Elegí un ícono de comida:',
              style: AppTextStyles.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            // Cuadrícula visual de emojis de comida
            Container(
              height: 120,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _emojisComida.map((emoji) {
                    final bool activo = emoji == _emojiSeleccionado;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _emojiSeleccionado = emoji),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: activo
                              ? AppColors.cardWhite
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activo
                                ? AppColors.forestDark
                                : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final nombre = _nombreCtrl.text.trim();
            if (nombre.isEmpty) return;
            Navigator.pop(
              context,
              CategoriaAlacenaData(nombre: nombre, emoji: _emojiSeleccionado),
            );
          },
          child: Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
