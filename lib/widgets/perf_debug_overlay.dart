import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../core/services/perf_telemetry_models.dart';
import '../core/services/perf_telemetry_service.dart';
import '../core/services/perf_telemetry_service_platform.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Floating DevTools-style performance HUD toggled via `?perf=1` or
/// `Ctrl+Shift+P` / `Alt+P`. Zero runtime overhead when hidden.
class PerfDebugOverlay extends StatefulWidget {
  const PerfDebugOverlay({
    super.key,
    this.telemetryService,
    this.initialVisible,
  });

  final PerfTelemetryService? telemetryService;
  final bool? initialVisible;

  @override
  State<PerfDebugOverlay> createState() => _PerfDebugOverlayState();
}

class _PerfDebugOverlayState extends State<PerfDebugOverlay> {
  static const int _maxTimingSamples = 60;
  static const int _maxReadyPollAttempts = 10;
  static const Duration _readyPollInterval = Duration(milliseconds: 300);

  static const Color _improvedColor = Color(0xFF34D399);
  static const Color _regressedColor = Color(0xFFF87171);
  static const Color _hudBg = Color(0xFF0B1812);
  static const Color _cardBg = Color(0xFF0E2018);
  static const Color _chipBg = Color(0xFF152D22);
  static const Color _borderColor = Color(0xFF234234);
  static const Color _hairlineColor = Color(0xFF1A3428);
  static const Color _textPrimary = Color(0xFFF2F7F4);
  static const Color _textSecondary = Color(0xFFB5C7BD);
  static const Color _textMuted = Color(0xFF7D9589);

  late final PerfTelemetryService _telemetryService;
  final List<FrameTiming> _frameSamples = <FrameTiming>[];

  bool _visible = false;
  bool _collapsed = false;
  bool _timingsRegistered = false;
  PortfolioPerfSnapshot? _snapshot;
  PortfolioPerfSnapshot? _baseline;
  DateTime _lastTimingUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _readyPollTimer;
  int _readyPollAttempts = 0;

  @override
  void initState() {
    super.initState();
    _telemetryService =
        widget.telemetryService ?? PlatformPerfTelemetryService();
    _visible = widget.initialVisible ?? _telemetryService.isPerfQueryEnabled();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    if (_visible) {
      _activateHud();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _cancelReadyPoll();
    _unregisterTimings();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyP) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    final ctrlShiftP = keyboard.isControlPressed && keyboard.isShiftPressed;
    final altP = keyboard.isAltPressed;
    if (!ctrlShiftP && !altP) {
      return false;
    }

    _toggleVisibility();
    return true;
  }

  void _toggleVisibility() {
    setState(() {
      _visible = !_visible;
      if (_visible) {
        _activateHud();
      } else {
        _cancelReadyPoll();
        _unregisterTimings();
      }
    });
  }

  void _activateHud() {
    _snapshot = _telemetryService.readSnapshot();
    _baseline = _telemetryService.loadBaseline();
    _registerTimings();
    _scheduleReadyPollIfNeeded();
  }

  void _scheduleReadyPollIfNeeded() {
    _cancelReadyPoll();
    if (!_visible || _snapshot?.totalReadyMs != null) {
      return;
    }
    _readyPollAttempts = 0;
    _readyPollTimer = Timer.periodic(_readyPollInterval, _onReadyPollTick);
  }

  void _onReadyPollTick(Timer timer) {
    if (!mounted || !_visible) {
      _cancelReadyPoll();
      return;
    }
    _readyPollAttempts++;
    final latest = _telemetryService.readSnapshot();
    final baseline = _telemetryService.loadBaseline();
    setState(() {
      _snapshot = latest;
      _baseline = baseline;
    });
    if (latest?.totalReadyMs != null ||
        _readyPollAttempts >= _maxReadyPollAttempts) {
      _cancelReadyPoll();
    }
  }

  void _cancelReadyPoll() {
    _readyPollTimer?.cancel();
    _readyPollTimer = null;
  }

  void _registerTimings() {
    if (_timingsRegistered) {
      return;
    }
    _timingsRegistered = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _unregisterTimings() {
    if (!_timingsRegistered) {
      return;
    }
    _timingsRegistered = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || !_visible) {
      return;
    }
    _frameSamples.addAll(timings);
    if (_frameSamples.length > _maxTimingSamples) {
      _frameSamples.removeRange(0, _frameSamples.length - _maxTimingSamples);
    }
    final now = DateTime.now();
    if (now.difference(_lastTimingUiUpdate).inMilliseconds >= 250) {
      _lastTimingUiUpdate = now;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _refreshSnapshot() {
    final latest = _telemetryService.readSnapshot();
    final baseline = _telemetryService.loadBaseline();
    setState(() {
      _snapshot = latest;
      _baseline = baseline;
    });
    if (latest?.totalReadyMs != null) {
      _cancelReadyPoll();
    }
  }

  void _saveBaseline() {
    final current = _snapshot ?? _telemetryService.readSnapshot();
    if (current == null) {
      return;
    }
    _telemetryService.saveBaseline(current);
    setState(() {
      _snapshot = current;
      _baseline = current;
    });
  }

  void _clearBaseline() {
    _telemetryService.clearBaseline();
    setState(() {
      _baseline = null;
    });
  }

  static TextStyle _labelStyle({
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
    bool tabular = false,
  }) {
    final base = AppTextStyles.body(
      size: 11.5,
      weight: fontWeight,
      color: color,
    );
    if (!tabular) {
      return base;
    }
    return base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final panelWidth = math.min(392.0, math.max(260.0, size.width - 24.0));
    final maxPanelHeight = math.max(200.0, size.height - 32.0);

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          minimum: const EdgeInsets.all(12.0),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: panelWidth,
                maxHeight: maxPanelHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _hudBg.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: _borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.48),
                      blurRadius: 24.0,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _collapsed
                    ? _buildCollapsedPill()
                    : _buildExpandedPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedPill() {
    final readyMs = _snapshot?.totalReadyMs;
    final label = readyMs == null
        ? 'Perf HUD'
        : 'Perf HUD · ${readyMs.round()}ms';
    return InkWell(
      onTap: () => setState(() => _collapsed = false),
      borderRadius: BorderRadius.circular(14.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.speed_rounded,
              size: 16.0,
              color: AppColors.pistachio,
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: _labelStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                tabular: true,
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: _toggleVisibility,
              child: const Icon(Icons.close, size: 15.0, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    final snapshot = _snapshot;
    final baseline = _baseline;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(snapshot),
          const SizedBox(height: 10.0),
          _buildActionsRow(snapshot: snapshot, hasBaseline: baseline != null),
          const SizedBox(height: 12.0),
          _buildBootSection(snapshot: snapshot, baseline: baseline),
          const SizedBox(height: 12.0),
          _buildMemoryAndNetworkSection(snapshot: snapshot, baseline: baseline),
          const SizedBox(height: 12.0),
          _buildFpsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(PortfolioPerfSnapshot? snapshot) {
    return Row(
      children: [
        const Icon(Icons.speed_rounded, size: 16.0, color: AppColors.pistachio),
        const SizedBox(width: 8.0),
        Expanded(
          child: Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'PERF DEBUG HUD',
                style: _labelStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ).copyWith(letterSpacing: 0.7),
              ),
              if (snapshot != null) ...[
                _MiniBadge(
                  text: snapshot.renderer,
                  accent: AppColors.pistachio,
                ),
                if (snapshot.readySource != null)
                  _MiniBadge(
                    text: snapshot.readySource!,
                    accent: _textSecondary,
                  ),
              ],
            ],
          ),
        ),
        _HeaderIconButton(
          semanticsLabel: 'Collapse',
          icon: Icons.unfold_less_rounded,
          onTap: () => setState(() => _collapsed = true),
        ),
        _HeaderIconButton(
          semanticsLabel: 'Close (Ctrl+Shift+P)',
          icon: Icons.close,
          onTap: _toggleVisibility,
        ),
      ],
    );
  }

  Widget _buildActionsRow({
    required PortfolioPerfSnapshot? snapshot,
    required bool hasBaseline,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      children: [
        _HudActionChip(
          label: 'Save as Baseline',
          enabled: snapshot != null,
          accent: AppColors.pistachio,
          onTap: _saveBaseline,
        ),
        if (hasBaseline)
          _HudActionChip(label: 'Clear', enabled: true, onTap: _clearBaseline),
        _HudActionChip(
          label: 'Refresh',
          enabled: true,
          onTap: _refreshSnapshot,
        ),
      ],
    );
  }

  Widget _buildBootSection({
    required PortfolioPerfSnapshot? snapshot,
    required PortfolioPerfSnapshot? baseline,
  }) {
    return _SectionCard(
      title: 'BOOT TIMELINE (MS)',
      child: snapshot == null
          ? Text(
              'Web performance telemetry unavailable on this target.',
              style: _labelStyle(color: _textMuted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BootProportionBar(snapshot: snapshot),
                const SizedBox(height: 10.0),
                _MetricRow(
                  label: 'HTML Paint',
                  valueText: _formatMs(snapshot.htmlFirstPaintMs),
                  delta: PerfMetricDelta.compute(
                    current: snapshot.htmlFirstPaintMs,
                    baseline: baseline?.htmlFirstPaintMs,
                  ),
                  unit: 'ms',
                ),
                _MetricRow(
                  label: 'WASM Engine',
                  valueText: _formatMs(snapshot.engineLoadMs),
                  delta: PerfMetricDelta.compute(
                    current: snapshot.engineLoadMs,
                    baseline: baseline?.engineLoadMs,
                  ),
                  unit: 'ms',
                ),
                _MetricRow(
                  label: 'Dart Boot',
                  valueText: _formatMs(snapshot.dartBootMs),
                  delta: PerfMetricDelta.compute(
                    current: snapshot.dartBootMs,
                    baseline: baseline?.dartBootMs,
                  ),
                  unit: 'ms',
                ),
                _MetricRow(
                  label: 'Fonts & Assets',
                  valueText: _formatMs(snapshot.assetsAndFontsMs),
                  delta: PerfMetricDelta.compute(
                    current: snapshot.assetsAndFontsMs,
                    baseline: baseline?.assetsAndFontsMs,
                  ),
                  unit: 'ms',
                ),
                _MetricRow(
                  label: 'Total Ready',
                  valueText: _formatMs(snapshot.totalReadyMs),
                  delta: PerfMetricDelta.compute(
                    current: snapshot.totalReadyMs,
                    baseline: baseline?.totalReadyMs,
                  ),
                  unit: 'ms',
                  emphasize: true,
                ),
              ],
            ),
    );
  }

  Widget _buildMemoryAndNetworkSection({
    required PortfolioPerfSnapshot? snapshot,
    required PortfolioPerfSnapshot? baseline,
  }) {
    final imageCache = PaintingBinding.instance.imageCache;
    final rasterMb = imageCache.currentSizeBytes / (1024 * 1024);

    final jsHeapText = snapshot?.jsHeapUsedMb == null
        ? 'Chromium only'
        : '${snapshot!.jsHeapUsedMb!.toStringAsFixed(1)} / '
              '${(snapshot.jsHeapTotalMb ?? snapshot.jsHeapUsedMb!).toStringAsFixed(1)} MB';

    final cacheLabel = snapshot == null
        ? null
        : snapshot.allFromCache ||
              (snapshot.networkCount == 0 && snapshot.cachedCount > 0)
        ? 'Cached (0 KB)'
        : 'Network (${snapshot.networkCount} net · ${snapshot.cachedCount} cache)';

    return _SectionCard(
      title: 'MEMORY & NETWORK',
      trailing: cacheLabel == null
          ? null
          : _MiniBadge(
              text: cacheLabel,
              accent: snapshot!.allFromCache ? _improvedColor : _textSecondary,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'JS Heap',
            valueText: jsHeapText,
            delta: PerfMetricDelta.compute(
              current: snapshot?.jsHeapUsedMb,
              baseline: baseline?.jsHeapUsedMb,
            ),
            unit: 'MB',
            decimals: 1,
          ),
          _MetricRow(
            label: 'Raster Cache',
            valueText:
                '${imageCache.currentSize} img · ${rasterMb.toStringAsFixed(1)} MB',
          ),
          if (snapshot != null) ...[
            _MetricRow(
              label: 'Network Transfer',
              valueText: '${snapshot.transferSizeKb.toStringAsFixed(1)} KB',
              delta: PerfMetricDelta.compute(
                current: snapshot.transferSizeKb,
                baseline: baseline?.transferSizeKb,
              ),
              unit: 'KB',
            ),
            _MetricRow(
              label: 'Decoded Body',
              valueText: '${snapshot.decodedBodySizeKb.toStringAsFixed(1)} KB',
              delta: PerfMetricDelta.compute(
                current: snapshot.decodedBodySizeKb,
                baseline: baseline?.decodedBodySizeKb,
              ),
              unit: 'KB',
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                for (final key in const ['wasm', 'js', 'images', 'fonts'])
                  _MiniBadge(
                    text:
                        '$key: ${snapshot.bucket(key).transferSizeKb.toStringAsFixed(0)}/'
                        '${snapshot.bucket(key).decodedBodySizeKb.toStringAsFixed(0)} KB',
                    accent: _textSecondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFpsSection() {
    final stats = _FrameStats.fromSamples(_frameSamples);

    return _SectionCard(
      title: 'LIVE FPS & FRAME TIMING',
      child: Column(
        children: [
          _MetricRow(
            label: 'Rolling FPS',
            valueText: stats.sampleCount == 0
                ? 'Idle (60.0)'
                : stats.fps.toStringAsFixed(1),
            emphasize: true,
          ),
          _MetricRow(
            label: 'UI Build',
            valueText: '${stats.avgBuildMs.toStringAsFixed(2)} ms',
          ),
          _MetricRow(
            label: 'GPU Raster',
            valueText: '${stats.avgRasterMs.toStringAsFixed(2)} ms',
          ),
          _MetricRow(
            label: 'Jank (>16.6ms)',
            valueText: '${stats.jankCount} / ${stats.sampleCount}',
          ),
        ],
      ),
    );
  }

  static String _formatMs(double? value) {
    if (value == null) {
      return '—';
    }
    return '${value.round()} ms';
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          width: 28.0,
          height: 28.0,
          child: Icon(
            icon,
            size: 16.0,
            color: _PerfDebugOverlayState._textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FrameStats {
  const _FrameStats({
    required this.sampleCount,
    required this.fps,
    required this.avgBuildMs,
    required this.avgRasterMs,
    required this.jankCount,
  });

  factory _FrameStats.fromSamples(List<FrameTiming> samples) {
    if (samples.isEmpty) {
      return const _FrameStats(
        sampleCount: 0,
        fps: 60.0,
        avgBuildMs: 0.0,
        avgRasterMs: 0.0,
        jankCount: 0,
      );
    }

    var buildUs = 0;
    var rasterUs = 0;
    var jank = 0;
    final intervalsMs = <double>[];
    int? prevStartUs;

    for (final t in samples) {
      buildUs += t.buildDuration.inMicroseconds;
      rasterUs += t.rasterDuration.inMicroseconds;
      if (t.totalSpan.inMicroseconds > 16667) {
        jank += 1;
      }
      final startUs = t.timestampInMicroseconds(FramePhase.vsyncStart);
      if (prevStartUs != null && startUs > prevStartUs) {
        final dtMs = (startUs - prevStartUs) / 1000.0;
        if (dtMs <= 250.0) {
          intervalsMs.add(dtMs);
        }
      }
      prevStartUs = startUs;
    }

    final count = samples.length;
    final avgBuild = (buildUs / count) / 1000.0;
    final avgRaster = (rasterUs / count) / 1000.0;
    final double fps;
    if (intervalsMs.isNotEmpty) {
      final avgDt = intervalsMs.reduce((a, b) => a + b) / intervalsMs.length;
      fps = (1000.0 / math.max(8.33, avgDt)).clamp(1.0, 120.0);
    } else {
      final avgSpanMs = (buildUs + rasterUs) / count / 1000.0;
      fps = (1000.0 / math.max(16.67, avgSpanMs)).clamp(1.0, 60.0);
    }

    return _FrameStats(
      sampleCount: count,
      fps: fps,
      avgBuildMs: avgBuild,
      avgRasterMs: avgRaster,
      jankCount: jank,
    );
  }

  final int sampleCount;
  final double fps;
  final double avgBuildMs;
  final double avgRasterMs;
  final int jankCount;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: _PerfDebugOverlayState._cardBg,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: _PerfDebugOverlayState._hairlineColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: _PerfDebugOverlayState._labelStyle(
                    color: _PerfDebugOverlayState._textMuted,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.7),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          child,
        ],
      ),
    );
  }
}

class _BootProportionBar extends StatelessWidget {
  const _BootProportionBar({required this.snapshot});

  final PortfolioPerfSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final segments = [
      (snapshot.htmlFirstPaintMs ?? 0.0, const Color(0xFF38BDF8)),
      (snapshot.engineLoadMs ?? 0.0, const Color(0xFF34D399)),
      (snapshot.dartBootMs ?? 0.0, const Color(0xFFD2F07A)),
      (snapshot.assetsAndFontsMs ?? 0.0, const Color(0xFFFBBF24)),
    ];
    final total = segments.fold<double>(
      0.0,
      (sum, item) => sum + math.max(0.0, item.$1),
    );
    if (total <= 0.0) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999.0),
      child: SizedBox(
        height: 6.0,
        child: Row(
          children: [
            for (final (value, color) in segments)
              if (value > 0.0)
                Expanded(
                  flex: math.max(1, value.round()),
                  child: ColoredBox(color: color),
                ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.valueText,
    this.delta,
    this.unit = '',
    this.decimals = 0,
    this.emphasize = false,
  });

  final String label;
  final String valueText;
  final PerfMetricDelta? delta;
  final String unit;
  final int decimals;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _PerfDebugOverlayState._labelStyle(
                color: emphasize
                    ? _PerfDebugOverlayState._textPrimary
                    : _PerfDebugOverlayState._textSecondary,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6.0,
              children: [
                Text(
                  valueText,
                  style: _PerfDebugOverlayState._labelStyle(
                    color: _PerfDebugOverlayState._textPrimary,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                    tabular: true,
                  ),
                ),
                if (delta != null)
                  Text(
                    delta!.format(unit, decimals: decimals),
                    style: _PerfDebugOverlayState._labelStyle(
                      color: delta!.improved
                          ? _PerfDebugOverlayState._improvedColor
                          : _PerfDebugOverlayState._regressedColor,
                      fontWeight: FontWeight.w600,
                      tabular: true,
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        text,
        style: _PerfDebugOverlayState._labelStyle(
          color: accent,
          fontWeight: FontWeight.w600,
          tabular: true,
        ),
      ),
    );
  }
}

class _HudActionChip extends StatelessWidget {
  const _HudActionChip({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.accent,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? _PerfDebugOverlayState._textMuted
        : (accent ?? _PerfDebugOverlayState._textPrimary);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: _PerfDebugOverlayState._chipBg,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: enabled
                ? _PerfDebugOverlayState._borderColor
                : _PerfDebugOverlayState._hairlineColor,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: _PerfDebugOverlayState._labelStyle(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
