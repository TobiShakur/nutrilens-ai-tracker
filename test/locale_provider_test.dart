import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/core/localization/locale_provider.dart';
import 'package:nutrilens_provider/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleProvider', () {
    test('defaults to Spanish (es) when no preference is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.inicializar();
      final provider = LocaleProvider(storageService: storage);

      expect(provider.locale, const Locale('es'));
      expect(provider.languageCode, 'es');
      expect(provider.isSpanish, isTrue);
      expect(provider.isEnglish, isFalse);
    });

    test('restores saved English locale from LocalStorageService', () async {
      SharedPreferences.setMockInitialValues({'nutrilens_locale_v1': 'en'});
      final storage = await LocalStorageService.inicializar();
      final provider = LocaleProvider(storageService: storage);

      expect(provider.locale, const Locale('en'));
      expect(provider.languageCode, 'en');
      expect(provider.isEnglish, isTrue);
      expect(provider.isSpanish, isFalse);
    });

    test(
      'setLocale switches between es and en, notifies listeners, and persists',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorageService.inicializar();
        final provider = LocaleProvider(storageService: storage);

        int notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setLocale(const Locale('en'));
        expect(provider.locale, const Locale('en'));
        expect(notifications, 1);
        expect(storage.obtenerLocale(), 'en');

        // Re-selecting same locale is a no-op.
        await provider.setLocale(const Locale('en'));
        expect(notifications, 1);

        await provider.setLocale(const Locale('es'));
        expect(provider.locale, const Locale('es'));
        expect(notifications, 2);
        expect(storage.obtenerLocale(), 'es');
      },
    );

    test('ignores unsupported locales', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.inicializar();
      final provider = LocaleProvider(storageService: storage);

      int notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setLocale(const Locale('fr'));
      expect(provider.locale, const Locale('es'));
      expect(notifications, 0);
      expect(storage.obtenerLocale(), isNull);
    });
  });
}
