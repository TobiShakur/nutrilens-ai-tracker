import 'package:flutter/material.dart';
import '../../features/alacena/domain/entities/categoria_alacena.dart';
import '../../features/alacena/domain/results/alacena_result.dart';
import '../../features/alacena/presentation/viewmodels/barcode_scanner_state.dart';
import '../../features/diario/domain/entities/diario_dia.dart';
import '../../features/diario/presentation/viewmodels/health_score_eval_state.dart';
import '../../features/perfil/domain/entities/resumen_semanal_metricas.dart';
import '../../features/scanner/presentation/viewmodels/scanner_state.dart';
import '../../l10n/app_localizations.dart';

extension BuildContextL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get activeLanguageCode => Localizations.localeOf(this).languageCode;
}

String localizedCategoriaLabel(CategoriaAlacena cat, AppLocalizations l10n) {
  return switch (cat.id) {
    'todos' => l10n.categoryAll,
    'proteinas' => l10n.categoryProteins,
    'carbohidratos' => l10n.categoryCarbs,
    'lacteos' => l10n.categoryDairy,
    'grasas' => l10n.categoryFats,
    'vegetales' => l10n.categoryVegetables,
    'otros' => l10n.categoryOthers,
    _ => cat.label,
  };
}

String localizedMealType(String tipoComida, AppLocalizations l10n) {
  return switch (tipoComida.trim().toUpperCase()) {
    'DESAYUNO' || 'BREAKFAST' => l10n.mealTypeBreakfast,
    'ALMUERZO' || 'LUNCH' => l10n.mealTypeLunch,
    'MERIENDA' || 'AFTERNOON SNACK' => l10n.mealTypeSnackAfternoon,
    'CENA' || 'DINNER' => l10n.mealTypeDinner,
    'SNACK' => l10n.mealTypeSnack,
    'COMIDA' || 'MEAL' => l10n.mealTypeGeneric,
    _ => tipoComida,
  };
}

String localizedDiaPill(DiarioDia dia, AppLocalizations l10n) {
  if (dia.diaNombre == 'Hoy') return l10n.today;
  final fechaIso = dia.fechaIso;
  final parsed = fechaIso != null ? DateTime.tryParse(fechaIso) : null;
  if (parsed != null) {
    return switch (parsed.weekday) {
      DateTime.sunday => l10n.weekdaySun(parsed.day),
      DateTime.monday => l10n.weekdayMon(parsed.day),
      DateTime.tuesday => l10n.weekdayTue(parsed.day),
      DateTime.wednesday => l10n.weekdayWed(parsed.day),
      DateTime.thursday => l10n.weekdayThu(parsed.day),
      DateTime.friday => l10n.weekdayFri(parsed.day),
      DateTime.saturday => l10n.weekdaySat(parsed.day),
      _ => dia.labelPill,
    };
  }
  return dia.labelPill;
}

String localizedMonthShort(int month, AppLocalizations l10n) {
  return switch (month) {
    1 => l10n.monthJan,
    2 => l10n.monthFeb,
    3 => l10n.monthMar,
    4 => l10n.monthApr,
    5 => l10n.monthMay,
    6 => l10n.monthJun,
    7 => l10n.monthJul,
    8 => l10n.monthAug,
    9 => l10n.monthSep,
    10 => l10n.monthOct,
    11 => l10n.monthNov,
    12 => l10n.monthDec,
    _ => '',
  };
}

String localizedWeekTitle(
  ResumenSemanalMetricas metricas,
  AppLocalizations l10n,
) {
  final lunes = metricas.lunesSemana;
  final domingo = metricas.domingoSemana;
  if (lunes == null || domingo == null) return metricas.semanaTitulo;

  final startMonth = localizedMonthShort(lunes.month, l10n);
  final endMonth = localizedMonthShort(domingo.month, l10n);
  final rango = l10n.localeName.startsWith('en')
      ? '$startMonth ${lunes.day} - $endMonth ${domingo.day}'
      : '${lunes.day} $startMonth - ${domingo.day} $endMonth';

  if (metricas.offset == 0) return l10n.statsWeekCurrent(rango);
  if (metricas.offset == -1) return l10n.statsWeekLast(rango);
  if (metricas.offset < -1) {
    return l10n.statsWeekWeeksAgo(metricas.offset.abs(), rango);
  }
  return l10n.statsWeekNext(rango);
}

String localizedHealthScoreError(
  HealthScoreEvalError error,
  AppLocalizations l10n,
) {
  return switch (error.type) {
    ScannerErrorType.missingApiKey => l10n.healthScoreErrorMissingKey,
    ScannerErrorType.network => l10n.healthScoreErrorNetwork,
    ScannerErrorType.timeout => l10n.healthScoreErrorTimeout,
    ScannerErrorType.rateLimit => l10n.healthScoreErrorRateLimit,
    ScannerErrorType.serviceUnavailable => l10n.healthScoreErrorUnavailable,
    ScannerErrorType.invalidResponse => l10n.healthScoreErrorInvalidResponse,
    ScannerErrorType.noFoodDetected => l10n.healthScoreErrorNoIngredients,
    ScannerErrorType.invalidImage ||
    ScannerErrorType.permissionDenied ||
    ScannerErrorType.unknown => l10n.healthScoreErrorGeneric,
  };
}

String localizedScannerError(ScannerError error, AppLocalizations l10n) {
  switch (error.detail) {
    case ScannerErrorDetail.missingImage:
      return l10n.scannerErrorMissingImage;
    case ScannerErrorDetail.emptyImage:
      return l10n.scannerErrorEmptyImage;
    case ScannerErrorDetail.tooLargeImage:
      return l10n.scannerErrorTooLarge;
    case ScannerErrorDetail.unsupportedFormat:
      return l10n.scannerErrorUnsupportedFormat;
    case ScannerErrorDetail.cameraPermission:
      return l10n.scannerErrorCameraPerm;
    case ScannerErrorDetail.galleryPermission:
      return l10n.scannerErrorGalleryPerm;
    case ScannerErrorDetail.emptyIngredients:
      return l10n.scannerErrorEmptyIngredients;
    case ScannerErrorDetail.noFoodDetected:
      return l10n.scannerErrorNoFood;
    case ScannerErrorDetail.none:
      break;
  }
  return switch (error.type) {
    ScannerErrorType.missingApiKey => l10n.scannerErrorMissingKey,
    ScannerErrorType.invalidImage => l10n.scannerErrorInvalidImage,
    ScannerErrorType.permissionDenied => l10n.scannerErrorCameraPerm,
    ScannerErrorType.network => l10n.scannerErrorNetwork,
    ScannerErrorType.timeout => l10n.scannerErrorTimeout,
    ScannerErrorType.rateLimit => l10n.scannerErrorRateLimit,
    ScannerErrorType.serviceUnavailable => l10n.scannerErrorUnavailable,
    ScannerErrorType.invalidResponse => l10n.scannerErrorInvalidResponse,
    ScannerErrorType.noFoodDetected => l10n.scannerErrorNoFood,
    ScannerErrorType.unknown => l10n.scannerErrorUnknown,
  };
}

String localizedBarcodeLoading(
  BarcodeScannerLoading loading,
  AppLocalizations l10n,
) {
  return switch (loading.step) {
    BarcodeLoadingStep.openingPicker => l10n.barcodeLoadingOpening,
    BarcodeLoadingStep.analyzingLabel => l10n.barcodeLoadingAnalyzing,
    BarcodeLoadingStep.lookingUpBarcode => l10n.barcodeLoadingLookup,
  };
}

String localizedBarcodeError(BarcodeScannerError error, AppLocalizations l10n) {
  switch (error.code) {
    case BarcodeErrorCode.cameraPermission:
      return l10n.barcodeErrCameraPerm;
    case BarcodeErrorCode.galleryPermission:
      return l10n.barcodeErrGalleryPerm;
    case BarcodeErrorCode.emptyImage:
      return l10n.barcodeErrEmptyImage;
    case BarcodeErrorCode.tooLargeImage:
      return l10n.barcodeErrTooLarge;
    case BarcodeErrorCode.unsupportedMime:
      return l10n.barcodeErrUnsupportedMime;
    case BarcodeErrorCode.labelNotFound:
      return l10n.barcodeErrLabelNotFound;
    case BarcodeErrorCode.missingBarcode:
      return l10n.barcodeErrMissingCode;
    case BarcodeErrorCode.invalidBarcode:
      return l10n.barcodeErrInvalidCode;
    case BarcodeErrorCode.productNotFound:
      return l10n.barcodeErrProductNotFound(error.barcode ?? '');
    case BarcodeErrorCode.missingApiKey:
      return l10n.barcodeErrMissingKey;
    case BarcodeErrorCode.network:
      return l10n.barcodeErrNetwork;
    case BarcodeErrorCode.timeout:
      return l10n.barcodeErrTimeout;
    case BarcodeErrorCode.rateLimit:
      return l10n.barcodeErrRateLimit;
    case BarcodeErrorCode.serviceUnavailable:
      return l10n.barcodeErrUnavailable;
    case BarcodeErrorCode.invalidResponse:
      return l10n.barcodeErrInvalidResponse;
    case BarcodeErrorCode.unknown:
      return l10n.barcodeErrUnknown;
    case BarcodeErrorCode.none:
      break;
  }
  return switch (error.tipo) {
    BarcodeErrorTipo.permisoDenegado => l10n.barcodeErrCameraPerm,
    BarcodeErrorTipo.codigoInvalido => l10n.barcodeErrInvalidCode,
    BarcodeErrorTipo.imagenInvalida => l10n.barcodeErrEmptyImage,
    BarcodeErrorTipo.noEncontrado => l10n.barcodeErrLabelNotFound,
    BarcodeErrorTipo.sinApiKey => l10n.barcodeErrMissingKey,
    BarcodeErrorTipo.red => l10n.barcodeErrNetwork,
    BarcodeErrorTipo.timeout => l10n.barcodeErrTimeout,
    BarcodeErrorTipo.rateLimit => l10n.barcodeErrRateLimit,
    BarcodeErrorTipo.servicioNoDisponible => l10n.barcodeErrUnavailable,
    BarcodeErrorTipo.desconocido => l10n.barcodeErrUnknown,
  };
}

String localizedAlacenaError(
  AlacenaFallo<dynamic> fallo,
  AppLocalizations l10n,
) {
  return switch (fallo.code) {
    AlacenaErrorCode.emptyName => l10n.pantryErrEmptyName,
    AlacenaErrorCode.invalidCategory => l10n.pantryErrInvalidCat,
    AlacenaErrorCode.nonPositiveGrams => l10n.pantryErrNonPositiveGrams,
    AlacenaErrorCode.negativeCalories => l10n.pantryErrNegativeCalories,
    AlacenaErrorCode.negativeMacros => l10n.pantryErrNegativeMacros,
    AlacenaErrorCode.notFound => l10n.pantryErrNotFound,
    AlacenaErrorCode.none => fallo.mensaje,
  };
}
