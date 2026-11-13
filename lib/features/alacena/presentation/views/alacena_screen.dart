// PANTALLA DE ALACENA: GESTIÓN DE INVENTARIO Y ALIMENTOS
// Permite buscar, filtrar por categorías predeterminadas y custom, crear nuevos alimentos
// con macro proporciones automáticas y editar o eliminar existencias.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/l10n_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../domain/entities/categoria_alacena.dart';
import '../viewmodels/alacena_viewmodel.dart';
import '../widgets/agregar_ingrediente_sheet.dart';
import '../widgets/categoria_chip_filter.dart';
import '../widgets/categoria_dialog.dart';
import '../widgets/detalle_ingrediente_sheet.dart';
import '../widgets/ingrediente_card.dart';

class AlacenaScreen extends StatelessWidget {
  const AlacenaScreen({super.key});

  Future<void> _abrirDialogoNuevaCategoria(BuildContext context) async {
    final res = await CategoriaDialog.show(context);
    if (res != null && context.mounted) {
      context.read<AlacenaViewModel>().agregarCategoria(res.nombre, res.emoji);
    }
  }

  void _mostrarOpcionesCategoria(BuildContext context, CategoriaAlacena cat) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizedCategoriaLabel(cat, l10n),
                    style: AppTextStyles.title(
                      size: 16,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.forestDark,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.pantryEditCatTitle,
                style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await CategoriaDialog.show(
                  context,
                  categoriaAEditar: cat,
                );
                if (res != null && context.mounted) {
                  context.read<AlacenaViewModel>().editarCategoria(
                    cat.id,
                    nuevoNombre: res.nombre,
                    nuevoEmoji: res.emoji,
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.alertRed,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.pantryDeleteCatTitle,
                style: AppTextStyles.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: AppColors.alertRed,
                ),
              ),
              subtitle: Text(
                l10n.pantryDeleteCatSubtitle,
                style: AppTextStyles.body(
                  size: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarEliminarCategoria(context, cat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarCategoria(
    BuildContext context,
    CategoriaAlacena cat,
  ) async {
    final l10n = context.l10n;
    final confirmado = await ConfirmDeleteDialog.show(
      context,
      titulo: l10n.pantryDeleteCatConfirmTitle(
        localizedCategoriaLabel(cat, l10n),
      ),
      mensaje: l10n.pantryDeleteCatConfirmMsg,
    );
    if (confirmado && context.mounted) {
      context.read<AlacenaViewModel>().eliminarCategoria(cat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = context.watch<AlacenaViewModel>();
    final items = vm.ingredientesFiltrados;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _AlacenaHeader(totalIngredientes: vm.totalIngredientes),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.pistachio.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.pistachioDark.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.forestDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.pantryInfoBanner,
                      style: AppTextStyles.body(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: AppColors.forestDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _SearchBar(
                query: vm.busquedaQuery,
                onChanged: context.read<AlacenaViewModel>().actualizarBusqueda,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoriaChipFilter(
                categorias: vm.categorias,
                seleccionada: vm.categoriaSeleccionada,
                onSelected: context
                    .read<AlacenaViewModel>()
                    .seleccionarCategoria,
                onLongPress: (cat) => _mostrarOpcionesCategoria(context, cat),
                onAddCustom: () => _abrirDialogoNuevaCategoria(context),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 125),
            sliver: SliverList.builder(
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AgregarIngredienteCard(
                    query: vm.busquedaQuery,
                    onTap: () => AgregarIngredienteSheet.show(context),
                  );
                }

                final item = items[index - 1];
                return IngredienteCard(
                  ingrediente: item,
                  onTap: () => DetalleIngredienteSheet.show(context, item),
                  onDelete: () => context
                      .read<AlacenaViewModel>()
                      .borrarIngrediente(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgregarIngredienteCard extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const _AgregarIngredienteCard({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool tieneQuery = query.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.pistachioDark.withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestDark.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.pistachio.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.forestDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieneQuery
                        ? l10n.pantryAddSpecific(query)
                        : l10n.pantryAddNew,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: AppColors.forestDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.pantryAddSubtitle,
                    style: AppTextStyles.body(
                      size: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.forestDark,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlacenaHeader extends StatelessWidget {
  final int totalIngredientes;

  const _AlacenaHeader({required this.totalIngredientes});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pantryTitle,
              style: AppTextStyles.title(
                size: 20,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pantryActiveCount(totalIngredientes),
              style: AppTextStyles.body(
                size: 13,
                color: AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.query, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _ctrl.text) {
      _ctrl.text = widget.query;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: context.l10n.pantrySearchHint,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.forestDark,
            size: 22,
          ),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
