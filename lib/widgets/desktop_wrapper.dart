import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'external_link_opener.dart';

/// Responsive portfolio showcase wrapper.
///
/// - On viewports narrower than `860px` (mobile / compact tablet), renders
///   [child] edge-to-edge with zero wrapper chrome.
/// - On desktop viewports (`>= 860px`), frames the live mobile app beside an
///   engineering showcase column sized to fit cleanly within `100vh`.
class DesktopWrapper extends StatelessWidget {
  static const double _desktopBreakpoint = 860.0;
  static const double _wideDesktopBreakpoint = 1080.0;
  static const double _logicalPhoneWidth = 390.0;

  static const Color _surfaceElevated = Color(0xFF0E2018);
  static const Color _bezelColor = Color(0xFF040B08);
  static const Color _bodyInk = Color(0xFFD0E2D8);
  static const Color _pillInk = Color(0xFFE3EFE8);
  static const Color _avatarBg = Color(0xFF153024);
  static const Color _stepBg = Color(0xFF173326);
  static const Color _linkHoverBg = Color(0xFF13291F);

  static const List<String> _stackPills = [
    'Dart & Flutter',
    'Clean Architecture',
    'MVVM + Provider',
    'Gemini API (LLM)',
    'Open Food Facts API v2',
    '153 Unit & Widget Tests',
  ];

  final Widget child;

  @visibleForTesting
  final void Function(String url)? onLinkTap;

  const DesktopWrapper({super.key, required this.child, this.onLinkTap});

  void _handleLinkTap(String url) {
    final override = onLinkTap;
    if (override != null) {
      override(url);
      return;
    }
    openExternalLink(url);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _desktopBreakpoint) {
          return Material(
            type: MaterialType.transparency,
            textStyle: AppTextStyles.body(),
            child: child,
          );
        }

        final isCompactDesktop = constraints.maxWidth < _wideDesktopBreakpoint;
        final horizontalPadding = isCompactDesktop ? 24.0 : 48.0;
        final columnGap = isCompactDesktop ? 28.0 : 56.0;
        final leftMaxWidth = isCompactDesktop ? 380.0 : 460.0;

        final availableHeight = (constraints.maxHeight - 56.0).clamp(
          520.0,
          812.0,
        );
        final logicalPhoneHeight = availableHeight.clamp(680.0, 800.0);
        final maxFrameHeight = (constraints.maxHeight - 40.0).clamp(
          0.0,
          double.infinity,
        );

        return Material(
          color: AppColors.webBg,
          textStyle: AppTextStyles.body(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: leftMaxWidth),
                      child: SingleChildScrollView(
                        child: _ShowcaseInfoColumn(
                          isCompactDesktop: isCompactDesktop,
                          onLinkTap: _handleLinkTap,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: columnGap),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxFrameHeight),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: _PhoneBezelFrame(
                        phoneWidth: _logicalPhoneWidth,
                        phoneHeight: logicalPhoneHeight,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShowcaseInfoColumn extends StatelessWidget {
  final bool isCompactDesktop;
  final void Function(String url) onLinkTap;

  const _ShowcaseInfoColumn({
    required this.isCompactDesktop,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final sectionGap = isCompactDesktop ? 12.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShowcasePillBadge(),
        SizedBox(height: sectionGap),
        Text(
          'NutriLens AI',
          style: AppTextStyles.display(
            size: isCompactDesktop ? 34 : 40,
            weight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: -1.0,
          ).copyWith(height: 1.08),
        ),
        const SizedBox(height: 8),
        Text(
          'Accurate macro tracking for home-cooked and prepared meals—calculated from your real pantry ingredients instead of generic estimates.',
          style: AppTextStyles.body(
            size: isCompactDesktop ? 14 : 15,
            weight: FontWeight.w500,
            color: DesktopWrapper._bodyInk,
            height: 1.45,
          ),
        ),
        SizedBox(height: sectionGap),
        const _AuthorCard(),
        SizedBox(height: sectionGap),
        const _ProductOverviewCard(),
        SizedBox(height: sectionGap),
        Text(
          'Architecture & Stack',
          style: AppTextStyles.title(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final label in DesktopWrapper._stackPills)
              _StackPill(label: label),
          ],
        ),
        SizedBox(height: isCompactDesktop ? 14 : 16),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _ShowcaseLinkButton(
              icon: Icons.code_rounded,
              label: 'github.com/TobiShakur',
              onTap: () => onLinkTap('https://github.com/TobiShakur'),
            ),
            _ShowcaseLinkButton(
              icon: Icons.work_outline_rounded,
              label: 'LinkedIn',
              onTap: () => onLinkTap(
                'https://www.linkedin.com/in/tobias-gutierrez-reboredo-991084279/',
              ),
            ),
            _ShowcaseLinkButton(
              icon: Icons.mail_outline_rounded,
              label: 'tobigutierrez26@gmail.com',
              onTap: () => onLinkTap('mailto:tobigutierrez26@gmail.com'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShowcasePillBadge extends StatelessWidget {
  const _ShowcasePillBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pistachio.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.pistachio.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.pistachio,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Mobile Engineering Showcase',
              style: AppTextStyles.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.pistachio,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: DesktopWrapper._surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DesktopWrapper._avatarBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.pistachio.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'TG',
              style: AppTextStyles.title(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.pistachio,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tobías Gutiérrez',
                  style: AppTextStyles.title(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mobile Software Engineer',
                  style: AppTextStyles.body(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StackPill extends StatelessWidget {
  final String label;

  const _StackPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: DesktopWrapper._surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: AppTextStyles.body(
          size: 11.5,
          weight: FontWeight.w600,
          color: DesktopWrapper._pillInk,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class _ProductOverviewCard extends StatelessWidget {
  const _ProductOverviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: DesktopWrapper._surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pistachio.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.kitchen_rounded,
                      size: 16,
                      color: AppColors.pistachio,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'How It Works',
                        style: AppTextStyles.title(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Try live →',
                  style: AppTextStyles.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.pistachio,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _OverviewStepRow(
            step: '1',
            spans: [
              _OverviewSpan('Build your pantry: ', bold: true),
              _OverviewSpan(
                'Save the ingredients you use every day by scanning a ',
              ),
              _OverviewSpan('barcode', bold: true),
              _OverviewSpan(', snapping a '),
              _OverviewSpan('product photo', bold: true),
              _OverviewSpan(', or reading the '),
              _OverviewSpan('nutrition facts label', bold: true),
              _OverviewSpan(' on the package.'),
            ],
          ),
          const SizedBox(height: 8),
          const _OverviewStepRow(
            step: '2',
            spans: [
              _OverviewSpan('Log prepared meals: ', bold: true),
              _OverviewSpan('When you track a '),
              _OverviewSpan('prepared / home-cooked meal', bold: true),
              _OverviewSpan(', NutriLens matches it against your pantry for '),
              _OverviewSpan('real macros', bold: true),
              _OverviewSpan(' and a personalized experience.'),
            ],
          ),
          const SizedBox(height: 8),
          const _OverviewStepRow(
            step: '3',
            spans: [
              _OverviewSpan('Score every meal: ', bold: true),
              _OverviewSpan('NutriLens also calculates a '),
              _OverviewSpan('Health Score', bold: true),
              _OverviewSpan(' by analyzing '),
              _OverviewSpan('macronutrients and micronutrients', bold: true),
              _OverviewSpan(
                ', so you know at a glance how healthy each meal is.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewSpan {
  final String text;
  final bool bold;

  const _OverviewSpan(this.text, {this.bold = false});
}

class _OverviewStepRow extends StatelessWidget {
  final String step;
  final List<_OverviewSpan> spans;

  const _OverviewStepRow({required this.step, required this.spans});

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.body(
      size: 12.5,
      weight: FontWeight.w500,
      color: DesktopWrapper._bodyInk,
      height: 1.4,
    );
    final boldStyle = AppTextStyles.body(
      size: 12.5,
      weight: FontWeight.w700,
      color: AppColors.textLight,
      height: 1.4,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DesktopWrapper._stepBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.pistachio.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            step,
            style: AppTextStyles.number(
              size: 11,
              weight: FontWeight.w800,
              color: AppColors.pistachio,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                for (final part in spans)
                  TextSpan(
                    text: part.text,
                    style: part.bold ? boldStyle : baseStyle,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseLinkButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShowcaseLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ShowcaseLinkButton> createState() => _ShowcaseLinkButtonState();
}

class _ShowcaseLinkButtonState extends State<_ShowcaseLinkButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isActive => _isHovered || _isFocused;

  @override
  Widget build(BuildContext context) {
    final foreground = _isActive
        ? AppColors.pistachio
        : AppColors.textMutedLight;

    return Semantics(
      link: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: _isActive
                      ? DesktopWrapper._linkHoverBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 15, color: foreground),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: AppTextStyles.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneBezelFrame extends StatelessWidget {
  final double phoneWidth;
  final double phoneHeight;
  final Widget child;

  const _PhoneBezelFrame({
    required this.phoneWidth,
    required this.phoneHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DesktopWrapper._bezelColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(phoneWidth, phoneHeight),
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: SizedBox(width: phoneWidth, height: phoneHeight, child: child),
        ),
      ),
    );
  }
}
