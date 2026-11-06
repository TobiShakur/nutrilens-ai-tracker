// VIEWMODEL DEL DIARIO NUTRICIONAL SEMANAL (PATRÓN MVVM)
// Gestiona el estado reactivo del día seleccionado, registro y edición de comidas,
// cálculo de salud metabólica (Health Score) y delegación a la capa de persistencia.

import 'package:flutter/foundation.dart';
import '../../domain/entities/comida_item.dart';
import '../../domain/entities/diario_dia.dart';
import '../../domain/repositories/diario_repository.dart';

/// Estado del diario de toda la semana. La vista lee con watch/select y dispara con read.
class DiarioViewModel extends ChangeNotifier {
  final DiarioRepository repository;

  late final Map<int, DiarioDia> _dias;
  late int _diaSeleccionadoIndex;

  DiarioViewModel({required this.repository}) {
    _dias = repository.getDiasIniciales();
    final hoyIdx = _dias.values.toList().indexWhere(
      (d) => d.diaNombre == 'Hoy',
    );
    _diaSeleccionadoIndex = hoyIdx != -1 ? hoyIdx : 30;
  }

  /// Días consecutivos de racha alcanzados calculados cronológicamente
  int get rachaDias {
    final lista = _dias.values.toList();
    final hoyIdx = lista.indexWhere((d) => d.diaNombre == 'Hoy');
    final actualIdx = hoyIdx != -1 ? hoyIdx : lista.length - 1;

    int racha = 0;
    if (lista[actualIdx].caloriasActuales > 0) {
      racha = 1;
    }

    for (int i = actualIdx - 1; i >= 0; i--) {
      final dia = lista[i];
      final min = (dia.metaCalorias * 0.9).round();
      final max = (dia.metaCalorias * 1.1).round();
      if (dia.caloriasActuales >= min && dia.caloriasActuales <= max) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }

  /// Indica si un día específico cumplió el objetivo calórico dentro del rango
  bool diaTieneRacha(int index) {
    final dia = _dias[index];
    if (dia == null || dia.caloriasActuales == 0) return false;
    final min = (dia.metaCalorias * 0.9).round();
    final max = (dia.metaCalorias * 1.1).round();
    return dia.caloriasActuales >= min && dia.caloriasActuales <= max;
  }

  /// Índice donde se encuentra el día "Hoy"
  int get indexHoy {
    final idx = _dias.values.toList().indexWhere((d) => d.diaNombre == 'Hoy');
    return idx != -1 ? idx : 30;
  }

  DiarioDia get diaActual => _dias[_diaSeleccionadoIndex]!;

  int get diaSeleccionadoIndex => _diaSeleccionadoIndex;

  List<String> get nombresDias => _dias.values.map((d) => d.labelPill).toList();

  List<String> get numerosDias => _dias.values.map((d) {
    final match = RegExp(r'\d+').firstMatch(d.labelPill);
    return match?.group(0) ?? '';
  }).toList();

  void seleccionarDia(int index) {
    if (index < 0 || index >= _dias.length) return;
    if (_diaSeleccionadoIndex == index) return;

    _diaSeleccionadoIndex = index;
    notifyListeners();
  }

  /// Suma una comida de muestra al día seleccionado y la devuelve para que la vista dé feedback.
  ComidaItem agregarComidaAleatoria() {
    final actual = diaActual;
    final nueva = repository.generarComidaAleatoria(actual.cantidadComidas + 1);

    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      comidas: [...actual.comidas, nueva],
    );
    notifyListeners();
    return nueva;
  }

  /// Agrega una comida armada al día seleccionado
  void registrarComida(ComidaItem nuevaComida) {
    final actual = diaActual;
    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      comidas: [...actual.comidas, nuevaComida],
    );
    repository.guardarDias(_dias);
    notifyListeners();
  }

  /// Actualiza los ingredientes o datos de una comida existente y recalcula los totales del día
  bool actualizarComida(ComidaItem comidaActualizada) {
    final actual = diaActual;
    final index = actual.comidas.indexWhere(
      (c) => c.id == comidaActualizada.id,
    );
    if (index == -1) return false;

    final nuevas = List<ComidaItem>.from(actual.comidas);
    nuevas[index] = comidaActualizada;

    _dias[_diaSeleccionadoIndex] = actual.copyWith(comidas: nuevas);
    repository.guardarDias(_dias);
    notifyListeners();
    return true;
  }

  /// Devuelve false si la comida no existe en el día seleccionado.
  bool eliminarComida(String comidaId) {
    final actual = diaActual;
    final restantes = actual.comidas.where((c) => c.id != comidaId).toList();
    if (restantes.length == actual.comidas.length) return false;

    _dias[_diaSeleccionadoIndex] = actual.copyWith(comidas: restantes);
    repository.guardarDias(_dias);
    notifyListeners();
    return true;
  }

  /// Lista ordenada de todos los días de la semana para análisis histórico.
  List<DiarioDia> get todosLosDias => _dias.values.toList();

  /// Actualiza las metas nutricionales del día actual o seleccionado, preservando los días pasados.
  void actualizarMetasDiaSeleccionado({
    int? metaCalorias,
    double? metaProteinas,
    double? metaCarbos,
    double? metaGrasas,
  }) {
    final actual = diaActual;
    _dias[_diaSeleccionadoIndex] = actual.copyWith(
      metaCalorias: metaCalorias ?? actual.metaCalorias,
      metaProteinas: metaProteinas ?? actual.metaProteinas,
      metaCarbos: metaCarbos ?? actual.metaCarbos,
      metaGrasas: metaGrasas ?? actual.metaGrasas,
    );
    repository.guardarDias(_dias);
    notifyListeners();
  }
}
