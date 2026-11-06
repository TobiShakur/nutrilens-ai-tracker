// SELECTOR HORIZONTAL DE DÍAS (DISEÑO CLEAN CON CENTRADO PRECISO POR SCROLLABLE)
// Utiliza Scrollable.ensureVisible(alignment: 0.5) con insets dinámicos de LayoutBuilder
// para garantizar que cualquier día seleccionado (inclusive el primero y el último)
// se ubique matemáticamente en el centro exacto del viewport.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Selector horizontal de días deslizable con autocentrado garantizado.
class WeekSelector extends StatefulWidget {
  final List<String> nombres;
  final int seleccionado;
  final ValueChanged<int> onSelected;

  const WeekSelector({
    super.key,
    required this.nombres,
    required this.seleccionado,
    required this.onSelected,
  });

  @override
  State<WeekSelector> createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _sincronizarKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centrarSeleccionado(widget.seleccionado, animar: false);
    });
  }

  void _sincronizarKeys() {
    if (_itemKeys.length != widget.nombres.length) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(widget.nombres.length, (_) => GlobalKey()));
    }
  }

  @override
  void didUpdateWidget(WeekSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarKeys();
    if (oldWidget.seleccionado != widget.seleccionado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centrarSeleccionado(widget.seleccionado, animar: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centrarSeleccionado(int index, {required bool animar}) {
    if (!mounted || index < 0 || index >= _itemKeys.length) return;
    final itemContext = _itemKeys[index].currentContext;
    if (itemContext == null) return;

    Scrollable.ensureVisible(
      itemContext,
      alignment: 0.5,
      duration: animar ? const Duration(milliseconds: 320) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Inset dinámico para que cualquier pastilla en los extremos (principio o fin)
        // cuente con espacio de scroll suficiente para alcanzar el 50% exacto del contenedor.
        final sideInset = constraints.maxWidth > 70
            ? (constraints.maxWidth / 2) - 35.0
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (sideInset > 0) SizedBox(width: sideInset),
                for (var i = 0; i < widget.nombres.length; i++) ...[
                  GestureDetector(
                    key: _itemKeys[i],
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onSelected(i);
                      _centrarSeleccionado(i, animar: true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: i == widget.seleccionado
                            ? AppColors.pistachio
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.nombres[i],
                        style: AppTextStyles.body(
                          size: 13,
                          weight: i == widget.seleccionado
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: i == widget.seleccionado
                              ? AppColors.forestDark
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  if (i < widget.nombres.length - 1) const SizedBox(width: 4),
                ],
                if (sideInset > 0) SizedBox(width: sideInset),
              ],
            ),
          ),
        );
      },
    );
  }
}
