// SERVICIO DE PERSISTENCIA LOCAL OFFLINE-FIRST
// Centraliza el guardado y recuperación de entidades del dominio serializadas en JSON
// utilizando SharedPreferences con degradación elegante a memoria en caso de fallo.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/alacena/domain/entities/ingrediente_alacena.dart';
import '../../features/diario/domain/entities/diario_dia.dart';
import '../../features/perfil/domain/entities/configuracion_nutricional.dart';

/// Servicio de persistencia local offline-first respaldado por SharedPreferences.
/// Permite mantener el historial del diario, la alacena y el perfil tras recargar el navegador o reiniciar la app.
class LocalStorageService {
  static const _keyDias = 'nutrilens_dias_mes_v2';
  static const _keyAlacena = 'nutrilens_alacena_items_v1';
  static const _keyConfig = 'nutrilens_configuracion_perfil_v1';

  final SharedPreferences? _prefs;

  LocalStorageService([this._prefs]);

  static Future<LocalStorageService> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return LocalStorageService(prefs);
    } catch (e) {
      debugPrint('No se pudo inicializar SharedPreferences: $e');
      return LocalStorageService();
    }
  }

  // ---------------------------------------------------------------------------
  // Diario
  // ---------------------------------------------------------------------------
  Future<void> guardarDias(Map<int, DiarioDia> dias) async {
    if (_prefs == null) return;
    try {
      final list = dias.values.map((d) => d.toJson()).toList();
      final jsonStr = jsonEncode(list);
      await _prefs.setString(_keyDias, jsonStr);
    } catch (e) {
      debugPrint('Error al guardar días en LocalStorage: $e');
    }
  }

  Map<int, DiarioDia>? obtenerDias() {
    if (_prefs == null) return null;
    try {
      final jsonStr = _prefs.getString(_keyDias);
      if (jsonStr == null || jsonStr.trim().isEmpty) return null;

      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final map = <int, DiarioDia>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final dia = DiarioDia.fromJson(item);
          map[dia.diaIndex] = dia;
        }
      }
      return map.isEmpty ? null : map;
    } catch (e) {
      debugPrint('Error al leer días desde LocalStorage: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Alacena
  // ---------------------------------------------------------------------------
  Future<void> guardarAlacena(List<IngredienteAlacena> items) async {
    if (_prefs == null) return;
    try {
      final list = items.map((i) => i.toJson()).toList();
      final jsonStr = jsonEncode(list);
      await _prefs.setString(_keyAlacena, jsonStr);
    } catch (e) {
      debugPrint('Error al guardar alacena en LocalStorage: $e');
    }
  }

  List<IngredienteAlacena>? obtenerAlacena() {
    if (_prefs == null) return null;
    try {
      final jsonStr = _prefs.getString(_keyAlacena);
      if (jsonStr == null || jsonStr.trim().isEmpty) return null;

      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(IngredienteAlacena.fromJson)
          .toList();
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('Error al leer alacena desde LocalStorage: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Perfil & Configuración Nutricional
  // ---------------------------------------------------------------------------
  Future<void> guardarConfiguracion(ConfiguracionNutricional config) async {
    if (_prefs == null) return;
    try {
      final jsonStr = jsonEncode(config.toJson());
      await _prefs.setString(_keyConfig, jsonStr);
    } catch (e) {
      debugPrint('Error al guardar configuración en LocalStorage: $e');
    }
  }

  ConfiguracionNutricional? obtenerConfiguracion() {
    if (_prefs == null) return null;
    try {
      final jsonStr = _prefs.getString(_keyConfig);
      if (jsonStr == null || jsonStr.trim().isEmpty) return null;

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ConfiguracionNutricional.fromJson(decoded);
    } catch (e) {
      debugPrint('Error al leer configuración desde LocalStorage: $e');
      return null;
    }
  }
}
