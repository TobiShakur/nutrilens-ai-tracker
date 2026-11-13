import 'package:flutter/material.dart';
import '../storage/local_storage_service.dart';

/// Manages the active application [Locale] ('es' or 'en') and persists
/// the user's selection in [LocalStorageService].
class LocaleProvider extends ChangeNotifier {
  static const List<String> supportedLanguageCodes = ['es', 'en'];
  static const Locale defaultLocale = Locale('es');

  final LocalStorageService _storageService;
  Locale _locale;

  LocaleProvider({LocalStorageService? storageService})
    : _storageService = storageService ?? LocalStorageService(),
      _locale = _resolveInitialLocale(storageService);

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isSpanish => _locale.languageCode == 'es';
  bool get isEnglish => _locale.languageCode == 'en';

  static Locale _resolveInitialLocale(LocalStorageService? storageService) {
    final savedCode = storageService?.obtenerLocale();
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      return Locale(savedCode);
    }
    return defaultLocale;
  }

  /// Updates the active locale if supported ('es' or 'en') and persists it.
  Future<void> setLocale(Locale newLocale) async {
    final code = newLocale.languageCode.toLowerCase();
    if (!supportedLanguageCodes.contains(code)) return;
    if (_locale.languageCode == code) return;

    _locale = Locale(code);
    notifyListeners();
    await _storageService.guardarLocale(code);
  }
}
