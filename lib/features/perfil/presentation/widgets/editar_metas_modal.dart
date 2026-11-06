import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/configuracion_nutricional.dart';

class EditarMetasModal extends StatefulWidget {
  final ConfiguracionNutricional configActual;

  const EditarMetasModal({super.key, required this.configActual});

  static Future<Map<String, num>?> show(
    BuildContext context, {
    required ConfiguracionNutricional configActual,
  }) {
    return showModalBottomSheet<Map<String, num>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditarMetasModal(configActual: configActual),
    );
  }

  @override
  State<EditarMetasModal> createState() => _EditarMetasModalState();
}

class _EditarMetasModalState extends State<EditarMetasModal> {
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _pCtrl;
  late final TextEditingController _cCtrl;
  late final TextEditingController _gCtrl;

  @override
  void initState() {
    super.initState();
    _kcalCtrl = TextEditingController(
      text: widget.configActual.metaCalorias.toString(),
    );
    _pCtrl = TextEditingController(
      text: widget.configActual.metaProteinas.round().toString(),
    );
    _cCtrl = TextEditingController(
      text: widget.configActual.metaCarbos.round().toString(),
    );
    _gCtrl = TextEditingController(
      text: widget.configActual.metaGrasas.round().toString(),
    );
  }

  @override
  void dispose() {
    _kcalCtrl.dispose();
    _pCtrl.dispose();
    _cCtrl.dispose();
    _gCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 2000;
    final p = double.tryParse(_pCtrl.text.trim()) ?? 140.0;
    final c = double.tryParse(_cCtrl.text.trim()) ?? 220.0;
    final g = double.tryParse(_gCtrl.text.trim()) ?? 65.0;

    Navigator.pop(context, {
      'kcal': kcal.clamp(800, 6000),
      'p': p.clamp(20.0, 400.0),
      'c': c.clamp(20.0, 800.0),
      'g': g.clamp(10.0, 300.0),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MODIFICAR METAS DIARIAS',
                style: AppTextStyles.title(size: 15, weight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInput(
            controller: _kcalCtrl,
            label: 'Calorías diarias objetivo',
            suffix: 'kcal',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _pCtrl,
                  label: 'Proteínas',
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInput(
                  controller: _cCtrl,
                  label: 'Carbos',
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInput(
                  controller: _gCtrl,
                  label: 'Grasas',
                  suffix: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _guardar,
            child: Text(
              'Actualizar metas',
              style: AppTextStyles.body(
                size: 14,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTextStyles.number(
            size: 14,
            weight: FontWeight.w800,
            color: AppColors.forestDark,
          ),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: AppTextStyles.body(
              size: 11.5,
              weight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
