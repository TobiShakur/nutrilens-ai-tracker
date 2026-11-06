import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ingrediente_alacena.dart';
import '../viewmodels/alacena_viewmodel.dart';
import 'agregar_ingrediente_sheet.dart';
import 'categoria_chip_filter.dart';
import 'ingrediente_card.dart';

class SelectorAlacenaModal extends StatefulWidget {
  const SelectorAlacenaModal({super.key});

  static Future<IngredienteAlacena?> show(BuildContext context) {
    return showModalBottomSheet<IngredienteAlacena>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectorAlacenaModal(),
    );
  }

  @override
  State<SelectorAlacenaModal> createState() => _SelectorAlacenaModalState();
}

class _SelectorAlacenaModalState extends State<SelectorAlacenaModal> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlacenaViewModel>();
    final items = vm.ingredientesFiltrados;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECCIONAR DE ALACENA',
                      style: AppTextStyles.title(
                        size: 15,
                        weight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: context
                      .read<AlacenaViewModel>()
                      .actualizarBusqueda,
                  style: AppTextStyles.body(
                    size: 13.5,
                    weight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o marca...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.forestDark,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              context
                                  .read<AlacenaViewModel>()
                                  .actualizarBusqueda('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CategoriaChipFilter(
            categorias: vm.categorias,
            seleccionada: vm.categoriaSeleccionada,
            onSelected: context.read<AlacenaViewModel>().seleccionarCategoria,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.kitchen_outlined,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No encontramos este ingrediente',
                            style: AppTextStyles.body(
                              size: 14,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Podés sumarlo ahora mismo a tu alacena.',
                            style: AppTextStyles.body(
                              size: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pistachio,
                              foregroundColor: AppColors.forestDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Crear ingrediente',
                              style: AppTextStyles.body(
                                size: 13,
                                weight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () =>
                                AgregarIngredienteSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return IngredienteCard(
                        ingrediente: item,
                        onTap: () => Navigator.pop(context, item),
                        onDelete: () => context
                            .read<AlacenaViewModel>()
                            .borrarIngrediente(item.id),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: AppColors.cardWhite,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forestDark,
                side: const BorderSide(color: AppColors.forestDark, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Nuevo ingrediente manual',
                style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800),
              ),
              onPressed: () => AgregarIngredienteSheet.show(context),
            ),
          ),
        ],
      ),
    );
  }
}
