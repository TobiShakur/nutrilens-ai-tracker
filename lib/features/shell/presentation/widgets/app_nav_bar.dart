import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Split Floating Dock navigation bar: 3-tab destination capsule + 58dp Scanner FAB.
class AppNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onCenterTap;

  const AppNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onItemSelected,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavTabItem(
                            icon: Icons.cottage_rounded,
                            label: 'Inicio',
                            isActive: selectedIndex == 0,
                            reduceMotion: reduceMotion,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onItemSelected(0);
                            },
                          ),
                        ),
                        Expanded(
                          child: _NavTabItem(
                            icon: Icons.inventory_2_rounded,
                            label: 'Alacena',
                            isActive: selectedIndex == 1,
                            reduceMotion: reduceMotion,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onItemSelected(1);
                            },
                          ),
                        ),
                        Expanded(
                          child: _NavTabItem(
                            icon: Icons.person_rounded,
                            label: 'Perfil',
                            isActive: selectedIndex == 2,
                            reduceMotion: reduceMotion,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onItemSelected(2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ScannerFabButton(
                  reduceMotion: reduceMotion,
                  onTap: onCenterTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? AppColors.forestDark
        : AppColors.textMutedAccessible;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.pistachioLight : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      size: 11.5,
                      weight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: foreground,
                    ),
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

class _ScannerFabButton extends StatefulWidget {
  final bool reduceMotion;
  final VoidCallback? onTap;

  const _ScannerFabButton({required this.reduceMotion, this.onTap});

  @override
  State<_ScannerFabButton> createState() => _ScannerFabButtonState();
}

class _ScannerFabButtonState extends State<_ScannerFabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final duration = widget.reduceMotion
        ? Duration.zero
        : Duration(milliseconds: _pressed ? 120 : 180);

    return Semantics(
      button: true,
      label: 'Escanear plato o cargar comida',
      child: Tooltip(
        message: 'Escanear plato',
        excludeFromSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap != null
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.onTap != null
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () {
            if (_pressed) setState(() => _pressed = false);
          },
          onTap: widget.onTap != null
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.forestDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pistachio, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: AppColors.pistachio,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
