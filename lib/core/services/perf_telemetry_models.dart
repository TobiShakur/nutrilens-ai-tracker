import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Network transfer & cache breakdown for one resource category.
@immutable
final class PerfResourceBucket {
  const PerfResourceBucket({
    required this.transferSizeKb,
    required this.decodedBodySizeKb,
    required this.count,
    required this.cachedCount,
    required this.opaqueCount,
  });

  factory PerfResourceBucket.fromJson(Map<String, dynamic> json) {
    return PerfResourceBucket(
      transferSizeKb: (json['transferSizeKb'] as num?)?.toDouble() ?? 0.0,
      decodedBodySizeKb: (json['decodedBodySizeKb'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      cachedCount: (json['cachedCount'] as num?)?.toInt() ?? 0,
      opaqueCount: (json['opaqueCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const PerfResourceBucket empty = PerfResourceBucket(
    transferSizeKb: 0.0,
    decodedBodySizeKb: 0.0,
    count: 0,
    cachedCount: 0,
    opaqueCount: 0,
  );

  final double transferSizeKb;
  final double decodedBodySizeKb;
  final int count;
  final int cachedCount;
  final int opaqueCount;

  Map<String, dynamic> toJson() => {
    'transferSizeKb': transferSizeKb,
    'decodedBodySizeKb': decodedBodySizeKb,
    'count': count,
    'cachedCount': cachedCount,
    'opaqueCount': opaqueCount,
  };
}

/// Complete boot, network, and memory snapshot captured from `window.__portfolioPerf`.
@immutable
final class PortfolioPerfSnapshot {
  const PortfolioPerfSnapshot({
    required this.version,
    required this.renderer,
    required this.readySource,
    required this.htmlFirstPaintMs,
    required this.engineLoadMs,
    required this.dartBootMs,
    required this.assetsAndFontsMs,
    required this.totalReadyMs,
    required this.transferSizeKb,
    required this.decodedBodySizeKb,
    required this.byType,
    required this.cachedCount,
    required this.networkCount,
    required this.opaqueCount,
    required this.allFromCache,
    required this.jsHeapUsedMb,
    required this.jsHeapTotalMb,
  });

  factory PortfolioPerfSnapshot.fromJson(Map<String, dynamic> json) {
    final rawByType = json['byType'];
    final parsedByType = <String, PerfResourceBucket>{};
    if (rawByType is Map<String, dynamic>) {
      for (final entry in rawByType.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          parsedByType[entry.key] = PerfResourceBucket.fromJson(value);
        }
      }
    }

    return PortfolioPerfSnapshot(
      version: (json['version'] as num?)?.toInt() ?? 1,
      renderer: (json['renderer'] as String?) ?? 'unknown',
      readySource: json['readySource'] as String?,
      htmlFirstPaintMs: (json['htmlFirstPaintMs'] as num?)?.toDouble(),
      engineLoadMs: (json['engineLoadMs'] as num?)?.toDouble(),
      dartBootMs: (json['dartBootMs'] as num?)?.toDouble(),
      assetsAndFontsMs: (json['assetsAndFontsMs'] as num?)?.toDouble(),
      totalReadyMs: (json['totalReadyMs'] as num?)?.toDouble(),
      transferSizeKb: (json['transferSizeKb'] as num?)?.toDouble() ?? 0.0,
      decodedBodySizeKb: (json['decodedBodySizeKb'] as num?)?.toDouble() ?? 0.0,
      byType: Map<String, PerfResourceBucket>.unmodifiable(parsedByType),
      cachedCount: (json['cachedCount'] as num?)?.toInt() ?? 0,
      networkCount: (json['networkCount'] as num?)?.toInt() ?? 0,
      opaqueCount: (json['opaqueCount'] as num?)?.toInt() ?? 0,
      allFromCache: (json['allFromCache'] as bool?) ?? false,
      jsHeapUsedMb: (json['jsHeapUsedMb'] as num?)?.toDouble(),
      jsHeapTotalMb: (json['jsHeapTotalMb'] as num?)?.toDouble(),
    );
  }

  static PortfolioPerfSnapshot? tryDecodeJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return PortfolioPerfSnapshot.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  final int version;
  final String renderer;
  final String? readySource;
  final double? htmlFirstPaintMs;
  final double? engineLoadMs;
  final double? dartBootMs;
  final double? assetsAndFontsMs;
  final double? totalReadyMs;
  final double transferSizeKb;
  final double decodedBodySizeKb;
  final Map<String, PerfResourceBucket> byType;
  final int cachedCount;
  final int networkCount;
  final int opaqueCount;
  final bool allFromCache;
  final double? jsHeapUsedMb;
  final double? jsHeapTotalMb;

  PerfResourceBucket bucket(String key) =>
      byType[key] ?? PerfResourceBucket.empty;

  Map<String, dynamic> toJson() => {
    'version': version,
    'renderer': renderer,
    'readySource': readySource,
    'htmlFirstPaintMs': htmlFirstPaintMs,
    'engineLoadMs': engineLoadMs,
    'dartBootMs': dartBootMs,
    'assetsAndFontsMs': assetsAndFontsMs,
    'totalReadyMs': totalReadyMs,
    'transferSizeKb': transferSizeKb,
    'decodedBodySizeKb': decodedBodySizeKb,
    'byType': {
      for (final entry in byType.entries) entry.key: entry.value.toJson(),
    },
    'cachedCount': cachedCount,
    'networkCount': networkCount,
    'opaqueCount': opaqueCount,
    'allFromCache': allFromCache,
    'jsHeapUsedMb': jsHeapUsedMb,
    'jsHeapTotalMb': jsHeapTotalMb,
  };

  String toJsonString() => jsonEncode(toJson());
}

/// Comparison delta between a live metric and a saved baseline metric.
@immutable
final class PerfMetricDelta {
  const PerfMetricDelta({
    required this.delta,
    required this.percentChange,
    required this.improved,
  });

  final double delta;
  final double? percentChange;
  final bool improved;

  static PerfMetricDelta? compute({
    required double? current,
    required double? baseline,
    bool lowerIsBetter = true,
  }) {
    if (current == null || baseline == null) {
      return null;
    }
    final diff = current - baseline;
    if (diff.abs() < 0.05) {
      return null;
    }
    final pct = baseline.abs() > 0.001 ? (diff / baseline) * 100.0 : null;
    final improved = lowerIsBetter ? diff < 0 : diff > 0;
    return PerfMetricDelta(delta: diff, percentChange: pct, improved: improved);
  }

  String format(String unit, {int decimals = 0}) {
    final sign = delta > 0 ? '+' : '';
    final valueText = decimals == 0
        ? '${delta.round()}'
        : delta.toStringAsFixed(decimals);
    final pctText = percentChange == null
        ? ''
        : ' (${percentChange! > 0 ? '+' : ''}${percentChange!.round()}%)';
    return '$sign$valueText$unit$pctText';
  }
}
