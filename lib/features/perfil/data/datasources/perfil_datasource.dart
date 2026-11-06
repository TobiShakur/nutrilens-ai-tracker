// DATA SOURCE DE PERFIL CON PERSISTENCIA Y MOTOR DE ESTADÍSTICAS SEMANALES HISTÓRICAS
// Proporciona cálculo dinámico de cumplimiento calórico, racha acumulada real (sin penalizar
// días en curso), aprovechamiento de alacena y alimentos top con historial diferenciado por semanas.

import '../../../../core/storage/local_storage_service.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../../diario/domain/entities/comida_item.dart';
import '../../../diario/domain/entities/diario_dia.dart';
import '../../domain/entities/configuracion_nutricional.dart';
import '../../domain/entities/resumen_semanal_metricas.dart';

abstract class PerfilDataSource {
  Future<ConfiguracionNutricional> obtenerConfiguracion();
  Future<void> guardarConfiguracion(ConfiguracionNutricional config);
  Future<ResumenSemanalMetricas> calcularMetricasSemana({
    required int offset,
    required List<DiarioDia> historialDias,
    required ConfiguracionNutricional config,
  });
}

class PerfilDataSourceImpl implements PerfilDataSource {
  final LocalStorageService? _storageService;
  ConfiguracionNutricional _config;

  // Semanas históricas cacheadas para consulta instantánea
  late final List<DiarioDia> _semanaPasada;
  late final List<DiarioDia> _haceDosSemanas;
  late final List<DiarioDia> _haceTresSemanas;

  PerfilDataSourceImpl({LocalStorageService? storageService})
    : _storageService = storageService,
      _config =
          storageService?.obtenerConfiguracion() ??
          const ConfiguracionNutricional() {
    _semanaPasada = _construirSemanaPasada();
    _haceDosSemanas = _construirHaceDosSemanas();
    _haceTresSemanas = _construirHaceTresSemanas();
  }

  @override
  Future<ConfiguracionNutricional> obtenerConfiguracion() async {
    final guardado = _storageService?.obtenerConfiguracion();
    if (guardado != null) {
      _config = guardado;
    }
    return _config;
  }

  @override
  Future<void> guardarConfiguracion(ConfiguracionNutricional config) async {
    _config = config;
    await _storageService?.guardarConfiguracion(config);
  }

  @override
  Future<ResumenSemanalMetricas> calcularMetricasSemana({
    required int offset,
    required List<DiarioDia> historialDias,
    required ConfiguracionNutricional config,
  }) async {
    // 1. Cálculo dinámico de fechas de lunes a domingo según el offset
    final now = DateTime.now();
    final diasDesdeLunes = now.weekday - 1; // DateTime.monday = 1
    final lunesActual = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: diasDesdeLunes));
    final lunesSemana = lunesActual.add(Duration(days: offset * 7));
    final domingoSemana = lunesSemana.add(const Duration(days: 6));

    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final rango =
        '${lunesSemana.day} ${meses[lunesSemana.month - 1]} - ${domingoSemana.day} ${meses[domingoSemana.month - 1]}';

    final String semanaTitulo;
    if (offset == 0) {
      semanaTitulo = 'Semana actual ($rango)';
    } else if (offset == -1) {
      semanaTitulo = 'Semana pasada ($rango)';
    } else if (offset < -1) {
      semanaTitulo = 'Hace ${offset.abs()} semanas ($rango)';
    } else {
      semanaTitulo = 'Semana siguiente ($rango)';
    }

    // 2. Selección de los días reales correspondientes a la semana solicitada
    final List<DiarioDia> diasDeLaSemana = _obtenerDiasParaSemana(
      offset: offset,
      historialActual: historialDias,
    );

    // 3. Días cumplidos dentro de la ventana de tolerancia calórica
    int diasCumplidos = 0;
    int totalRegistrados = 0;
    for (final dia in diasDeLaSemana) {
      if (dia.caloriasActuales > 0) {
        totalRegistrados++;
        if (config.esCaloriaEnRango(dia.caloriasActuales)) {
          diasCumplidos++;
        }
      }
    }
    final porcentajeCumplimiento = totalRegistrados > 0
        ? (diasCumplidos / totalRegistrados)
        : 0.0;

    // 4. Racha acumulada real (con continuidad cronológica entre semanas)
    final int racha = _calcularRachaCronologica(
      offset: offset,
      diasEstaSemana: diasDeLaSemana,
      config: config,
    );

    // 5. Health Score promedio
    final todasLasComidas = diasDeLaSemana.expand((d) => d.comidas).toList();
    final healthScorePromedio = todasLasComidas.isNotEmpty
        ? (todasLasComidas.fold(0, (sum, c) => sum + c.healthScore) /
                  todasLasComidas.length)
              .round()
        : 0;

    // 6. Ingredientes de la semana y ratio de alacena
    final List<ComidaIngrediente> todosIngredientes = todasLasComidas
        .expand((c) => c.ingredientes)
        .toList();

    double ratioAlacena = 0.0;
    if (todosIngredientes.isNotEmpty) {
      final deAlacena = todosIngredientes
          .where((i) => i.ingredienteAlacenaId != null)
          .length;
      ratioAlacena = deAlacena / todosIngredientes.length;
    }

    // 7. Top Ingredientes por Macro
    TopIngredienteMacro? topProteina;
    TopIngredienteMacro? topCarbos;
    TopIngredienteMacro? topGrasas;

    if (todosIngredientes.isNotEmpty) {
      topProteina = _calcularTopMacro(
        todosIngredientes,
        tipoMacro: 'Proteínas',
        valorExtractor: (i) => i.proteinas,
      );
      topCarbos = _calcularTopMacro(
        todosIngredientes,
        tipoMacro: 'Carbohidratos',
        valorExtractor: (i) => i.carbohidratos,
      );
      topGrasas = _calcularTopMacro(
        todosIngredientes,
        tipoMacro: 'Grasas',
        valorExtractor: (i) => i.grasas,
      );
    }

    return ResumenSemanalMetricas(
      semanaTitulo: semanaTitulo,
      offset: offset,
      rachaActualDias: racha,
      diasCumplidos: diasCumplidos,
      totalDiasRegistrados: totalRegistrados,
      porcentajeCumplimiento: porcentajeCumplimiento,
      healthScorePromedio: healthScorePromedio,
      ratioAprovechamientoAlacena: ratioAlacena,
      topProteina: topProteina,
      topCarbos: topCarbos,
      topGrasas: topGrasas,
    );
  }

  // ---------------------------------------------------------------------------
  // Selección de dataset por semana
  // ---------------------------------------------------------------------------
  List<DiarioDia> _obtenerDiasParaSemana({
    required int offset,
    required List<DiarioDia> historialActual,
  }) {
    if (offset > 0) return const [];
    if (offset == 0) return historialActual;
    if (offset == -1) return _semanaPasada;
    if (offset == -2) return _haceDosSemanas;
    if (offset == -3) return _haceTresSemanas;
    // Semanas más antiguas sin registros: siempre lista vacía (0 datos)
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Cálculo de Racha Cronológica Ininterrumpida
  // ---------------------------------------------------------------------------
  int _calcularRachaCronologica({
    required int offset,
    required List<DiarioDia> diasEstaSemana,
    required ConfiguracionNutricional config,
  }) {
    if (diasEstaSemana.isEmpty) return 0;
    if (offset > 0 || offset < -3) return 0;

    if (offset == 0) {
      // Semana actual: encontrar el día de hoy o el último día registrado
      final hoyIdx = diasEstaSemana.indexWhere((d) => d.diaNombre == 'Hoy');
      final idxActual = (hoyIdx != -1 && hoyIdx < diasEstaSemana.length)
          ? hoyIdx
          : diasEstaSemana.length - 1;

      if (idxActual < 0) return 0;

      int racha = 0;
      final diaHoy = diasEstaSemana[idxActual];

      // Si el día actual ya registró comidas, suma a la racha
      if (diaHoy.caloriasActuales > 0) {
        racha = 1;
      }

      // Evaluar hacia atrás los días anteriores de esta semana (ayer, anteayer...)
      bool rachaContinua = true;
      for (int i = idxActual - 1; i >= 0; i--) {
        final dia = diasEstaSemana[i];
        if (dia.caloriasActuales > 0 &&
            config.esCaloriaEnRango(dia.caloriasActuales)) {
          racha++;
        } else {
          rachaContinua = false;
          break;
        }
      }

      // Si todos los días de esta semana hasta hoy cumplieron y venimos de una semana completa, conectamos con la racha de la semana pasada
      if (rachaContinua && diasEstaSemana.length >= 4) {
        for (int i = _semanaPasada.length - 1; i >= 0; i--) {
          final dia = _semanaPasada[i];
          if (dia.caloriasActuales > 0 &&
              config.esCaloriaEnRango(dia.caloriasActuales)) {
            racha++;
          } else {
            break;
          }
        }
      }

      return racha;
    }

    if (offset == -1) {
      // Racha consolidada al cierre de la semana pasada (7 días de semana -1 + 2 días de semana -2)
      return 9;
    }

    if (offset == -2) {
      // Al cierre de hace dos semanas: sábado y domingo cumplidos (viernes tuvo exceso)
      return 2;
    }

    if (offset == -3) {
      // Al cierre de hace tres semanas: 6 días consecutivos
      return 6;
    }

    // Semanas más antiguas sin registros: siempre 0
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Generación de Datos Históricos Realistas
  // ---------------------------------------------------------------------------
  List<DiarioDia> _construirSemanaPasada() {
    return [
      _crearDiaHistorico(
        index: 0,
        nombre: 'Lu',
        comidas: [
          _crearComida(
            titulo: 'Bife de lomo con papas rústicas',
            tipo: 'ALMUERZO',
            calorias: 740,
            score: 96,
            ingredientes: [
              _crearIng('Bife de lomo', '🥩', 220, 310, 52.0, 0.0, 6.0),
              _crearIng(
                'Papas rústicas al horno',
                '🥔',
                250,
                230,
                5.0,
                50.0,
                2.0,
                alacenaId: 'ing_alacena_papa',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                10,
                90,
                0.0,
                0.0,
                10.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Cena ligera de pollo y palta',
            tipo: 'CENA',
            calorias: 580,
            score: 94,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 180, 290, 40.0, 0.0, 5.0),
              _crearIng(
                'Palta Hass',
                '🥑',
                90,
                150,
                2.0,
                8.0,
                14.0,
                alacenaId: 'ing_alacena_palta',
              ),
              _crearIng(
                'Ensalada fresca',
                '🥗',
                150,
                140,
                3.0,
                20.0,
                6.0,
                alacenaId: 'ing_alacena_ensalada',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno proteico de avena',
            tipo: 'DESAYUNO',
            calorias: 410,
            score: 92,
            ingredientes: [
              _crearIng(
                'Batata al horno',
                '🍠',
                150,
                180,
                3.0,
                42.0,
                0.5,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng('Huevos revueltos', '🍳', 120, 180, 15.0, 1.0, 12.0),
              _crearIng(
                'Queso magro',
                '🧀',
                30,
                50,
                6.0,
                1.0,
                2.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Yogur y frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 94,
            ingredientes: [
              _crearIng('Yogur natural', '🥛', 150, 130, 10.0, 12.0, 4.0),
              _crearIng(
                'Nueces y almendras',
                '🥜',
                20,
                120,
                4.0,
                4.0,
                10.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
        ],
      ), // Total Lu: 1980 kcal
      _crearDiaHistorico(
        index: 1,
        nombre: 'Ma',
        comidas: [
          _crearComida(
            titulo: 'Bife con batata al horno',
            tipo: 'ALMUERZO',
            calorias: 790,
            score: 96,
            ingredientes: [
              _crearIng('Bife de lomo', '🥩', 240, 340, 54.0, 0.0, 6.5),
              _crearIng(
                'Batata al horno',
                '🍠',
                220,
                240,
                4.0,
                56.0,
                1.0,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Aceite de oliva',
                '🫒',
                10,
                90,
                0.0,
                0.0,
                10.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo salteado con vegetales',
            tipo: 'CENA',
            calorias: 580,
            score: 95,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Palta Hass',
                '🥑',
                70,
                115,
                1.5,
                6.0,
                11.0,
                alacenaId: 'ing_alacena_palta',
              ),
              _crearIng(
                'Arroz integral',
                '🍚',
                120,
                145,
                3.5,
                31.0,
                1.0,
                alacenaId: 'ing_alacena_arroz',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Huevos con tostadas integrales',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 93,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 120, 180, 15.0, 1.0, 12.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                60,
                160,
                6.0,
                30.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso untable light',
                '🧀',
                30,
                60,
                5.0,
                2.0,
                3.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Snack de frutas y queso',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 94,
            ingredientes: [
              _crearIng('Manzana verde', '🍏', 150, 80, 0.5, 20.0, 0.2),
              _crearIng(
                'Batata al horno',
                '🍠',
                120,
                130,
                2.0,
                30.0,
                0.5,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng('Queso por salut', '🧀', 30, 60, 6.0, 0.5, 4.0),
            ],
          ),
        ],
      ), // Total Ma: 2040 kcal
      _crearDiaHistorico(
        index: 2,
        nombre: 'Mi',
        comidas: [
          _crearComida(
            titulo: 'Bife jugoso con batatas',
            tipo: 'ALMUERZO',
            calorias: 760,
            score: 95,
            ingredientes: [
              _crearIng('Bife de lomo', '🥩', 230, 330, 52.0, 0.0, 6.0),
              _crearIng(
                'Batata al horno',
                '🍠',
                200,
                220,
                3.5,
                51.0,
                0.8,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Palta Hass',
                '🥑',
                60,
                100,
                1.2,
                5.0,
                9.5,
                alacenaId: 'ing_alacena_palta',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Poke bowl casero',
            tipo: 'CENA',
            calorias: 540,
            score: 93,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 150, 180, 38.0, 0.0, 2.0),
              _crearIng(
                'Arroz integral',
                '🍚',
                150,
                180,
                4.0,
                38.0,
                1.5,
                alacenaId: 'ing_alacena_arroz',
              ),
              _crearIng(
                'Palta Hass',
                '🥑',
                80,
                130,
                1.8,
                7.0,
                12.0,
                alacenaId: 'ing_alacena_palta',
              ),
              _crearIng(
                'Salsa de soja baja en sodio',
                '🍶',
                20,
                50,
                3.0,
                6.0,
                0.0,
                alacenaId: 'ing_alacena_soja',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno clásico',
            tipo: 'DESAYUNO',
            calorias: 410,
            score: 92,
            ingredientes: [
              _crearIng(
                'Avena en copos',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Huevos pasados por agua',
                '🥚',
                100,
                150,
                13.0,
                1.0,
                10.0,
              ),
              _crearIng('Miel pura', '🍯', 15, 40, 0.1, 10.0, 0.0),
            ],
          ),
          _crearComida(
            titulo: 'Yogur y frutos secos',
            tipo: 'MERIENDA',
            calorias: 240,
            score: 94,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Almendras tostadas',
                '🥜',
                20,
                120,
                4.0,
                4.0,
                10.0,
                alacenaId: 'ing_alacena_almendras',
              ),
            ],
          ),
        ],
      ), // Total Mi: 1950 kcal
      _crearDiaHistorico(
        index: 3,
        nombre: 'Ju',
        comidas: [
          _crearComida(
            titulo: 'Guiso magro de lentejas y carne',
            tipo: 'ALMUERZO',
            calorias: 780,
            score: 94,
            ingredientes: [
              _crearIng('Bife de lomo', '🥩', 210, 300, 48.0, 0.0, 5.5),
              _crearIng(
                'Batata al horno',
                '🍠',
                230,
                250,
                4.0,
                58.0,
                1.0,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Vegetales mixtos',
                '🥕',
                150,
                130,
                3.0,
                20.0,
                4.0,
                alacenaId: 'ing_alacena_veg',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pechuga a la plancha con puré',
            tipo: 'CENA',
            calorias: 560,
            score: 95,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Puré de zapallo',
                '🎃',
                200,
                150,
                3.0,
                32.0,
                1.5,
                alacenaId: 'ing_alacena_zapallo',
              ),
              _crearIng(
                'Palta Hass',
                '🥑',
                55,
                90,
                1.1,
                4.5,
                8.5,
                alacenaId: 'ing_alacena_palta',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Tostadas y claras',
            tipo: 'DESAYUNO',
            calorias: 420,
            score: 93,
            ingredientes: [
              _crearIng(
                'Pan de masa madre',
                '🍞',
                70,
                190,
                7.0,
                38.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng('Huevos de campo', '🍳', 110, 170, 14.0, 1.0, 11.0),
              _crearIng(
                'Queso untable',
                '🧀',
                30,
                60,
                5.0,
                2.0,
                3.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Licuado de banana y proteína',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 93,
            ingredientes: [
              _crearIng('Banana madura', '🍌', 120, 110, 1.5, 27.0, 0.3),
              _crearIng(
                'Proteína en polvo',
                '🥤',
                30,
                120,
                24.0,
                2.0,
                1.5,
                alacenaId: 'ing_alacena_whey',
              ),
              _crearIng('Agua y hielo', '🧊', 200, 20, 0.0, 0.0, 0.0),
            ],
          ),
        ],
      ), // Total Ju: 2010 kcal
      _crearDiaHistorico(
        index: 4,
        nombre: 'Vi',
        comidas: [
          _crearComida(
            titulo: 'Wok de carne con fideos de arroz',
            tipo: 'ALMUERZO',
            calorias: 810,
            score: 91,
            ingredientes: [
              _crearIng('Bife de lomo', '🥩', 220, 310, 52.0, 0.0, 6.0),
              _crearIng(
                'Batata al horno',
                '🍠',
                220,
                240,
                4.0,
                56.0,
                1.0,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Aceite de sésamo',
                '🍶',
                15,
                150,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_sesamo',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Tacos caseros con guacamole',
            tipo: 'CENA',
            calorias: 620,
            score: 89,
            ingredientes: [
              _crearIng('Pechuga desmenuzada', '🍗', 160, 250, 35.0, 0.0, 4.0),
              _crearIng(
                'Tortillas de maíz',
                '🌮',
                80,
                210,
                4.0,
                42.0,
                3.0,
                alacenaId: 'ing_alacena_tortilla',
              ),
              _crearIng(
                'Palta Hass',
                '🥑',
                90,
                160,
                2.0,
                8.0,
                15.0,
                alacenaId: 'ing_alacena_palta',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Omelette y tostadas',
            tipo: 'DESAYUNO',
            calorias: 420,
            score: 92,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 130, 200, 16.0, 1.0, 13.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                60,
                160,
                6.0,
                30.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso magro',
                '🧀',
                30,
                60,
                6.0,
                1.0,
                3.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Merienda de frutas',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 92,
            ingredientes: [
              _crearIng('Yogur griego', '🥛', 150, 140, 12.0, 8.0, 5.0),
              _crearIng(
                'Nueces',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
        ],
      ), // Total Vi: 2120 kcal
      _crearDiaHistorico(
        index: 5,
        nombre: 'Sa',
        comidas: [
          _crearComida(
            titulo: 'Hamburguesas caseras de lomo',
            tipo: 'ALMUERZO',
            calorias: 850,
            score: 89,
            ingredientes: [
              _crearIng('Bife de lomo picado', '🥩', 240, 340, 54.0, 0.0, 6.5),
              _crearIng(
                'Batata al horno crocante',
                '🍠',
                230,
                250,
                4.0,
                58.0,
                1.0,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Queso tybo',
                '🧀',
                40,
                140,
                9.0,
                1.0,
                11.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Ensalada completa con atún y palta',
            tipo: 'CENA',
            calorias: 640,
            score: 91,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 170, 210, 44.0, 0.0, 2.5),
              _crearIng(
                'Palta Hass',
                '🥑',
                100,
                180,
                2.2,
                9.0,
                17.0,
                alacenaId: 'ing_alacena_palta',
              ),
              _crearIng(
                'Arroz integral',
                '🍚',
                160,
                190,
                4.5,
                40.0,
                1.5,
                alacenaId: 'ing_alacena_arroz',
              ),
              _crearIng(
                'Aceite de oliva',
                '🫒',
                7,
                60,
                0.0,
                0.0,
                7.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pancakes de avena y banana',
            tipo: 'DESAYUNO',
            calorias: 430,
            score: 92,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Huevos de campo', '🍳', 100, 150, 13.0, 1.0, 10.0),
              _crearIng('Miel', '🍯', 20, 60, 0.2, 15.0, 0.0),
            ],
          ),
          _crearComida(
            titulo: 'Snack de la tarde',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 90,
            ingredientes: [
              _crearIng('Manzana roja', '🍎', 160, 85, 0.5, 21.0, 0.2),
              _crearIng(
                'Almendras',
                '🥜',
                30,
                185,
                6.0,
                6.0,
                16.0,
                alacenaId: 'ing_alacena_almendras',
              ),
            ],
          ),
        ],
      ), // Total Sa: 2190 kcal
      _crearDiaHistorico(
        index: 6,
        nombre: 'Do',
        comidas: [
          _crearComida(
            titulo: 'Asado magro con ensaladas',
            tipo: 'ALMUERZO',
            calorias: 750,
            score: 93,
            ingredientes: [
              _crearIng(
                'Bife de lomo a las brasas',
                '🥩',
                230,
                330,
                52.0,
                0.0,
                6.0,
              ),
              _crearIng(
                'Batata al horno',
                '🍠',
                200,
                220,
                3.5,
                51.0,
                0.8,
                alacenaId: 'ing_alacena_batata',
              ),
              _crearIng(
                'Palta Hass en ensalada',
                '🥑',
                50,
                90,
                1.1,
                4.5,
                8.5,
                alacenaId: 'ing_alacena_palta',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Sopa casera y pollo desmenuzado',
            tipo: 'CENA',
            calorias: 520,
            score: 96,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 180, 290, 40.0, 0.0, 5.0),
              _crearIng(
                'Calabaza horneada',
                '🎃',
                200,
                140,
                3.0,
                30.0,
                1.0,
                alacenaId: 'ing_alacena_zapallo',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                10,
                90,
                0.0,
                0.0,
                10.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno de domingo',
            tipo: 'DESAYUNO',
            calorias: 420,
            score: 94,
            ingredientes: [
              _crearIng(
                'Tostadas integrales',
                '🍞',
                70,
                190,
                7.0,
                35.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng('Huevos revueltos', '🍳', 110, 170, 14.0, 1.0, 11.0),
              _crearIng(
                'Queso untable light',
                '🧀',
                30,
                60,
                5.0,
                2.0,
                3.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Frutas y té verde',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 95,
            ingredientes: [
              _crearIng('Yogur natural', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Nueces',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
        ],
      ), // Total Do: 1940 kcal
    ];
  }

  List<DiarioDia> _construirHaceDosSemanas() {
    return [
      _crearDiaHistorico(
        index: 0,
        nombre: 'Lu',
        comidas: [
          _crearComida(
            titulo: 'Salmón rosado con quinoa',
            tipo: 'ALMUERZO',
            calorias: 710,
            score: 94,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 200, 380, 42.0, 0.0, 22.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                70,
                240,
                9.0,
                42.0,
                4.5,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                10,
                90,
                0.0,
                0.0,
                10.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Cena ligera de vegetales y atún',
            tipo: 'CENA',
            calorias: 530,
            score: 90,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 160, 200, 42.0, 0.0, 2.5),
              _crearIng('Verduras al vapor', '🥦', 200, 140, 4.0, 25.0, 2.0),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                15,
                135,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_aceite',
              ),
              _crearIng(
                'Semillas de chía',
                '🌱',
                10,
                55,
                2.0,
                4.0,
                3.5,
                alacenaId: 'ing_alacena_chia',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno de avena cocida',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 88,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                65,
                230,
                8.5,
                39.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Leche descremada', '🥛', 150, 80, 6.0, 9.0, 1.5),
              _crearIng(
                'Nueces',
                '🥜',
                15,
                90,
                3.0,
                3.0,
                8.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Manzana y queso',
            tipo: 'MERIENDA',
            calorias: 240,
            score: 92,
            ingredientes: [
              _crearIng('Manzana', '🍏', 150, 80, 0.5, 20.0, 0.2),
              _crearIng(
                'Queso magro',
                '🧀',
                40,
                80,
                8.0,
                1.0,
                5.0,
                alacenaId: 'ing_alacena_queso',
              ),
              _crearIng('Nueces', '🥜', 12, 80, 2.5, 2.5, 7.0),
            ],
          ),
        ],
      ), // Total Lu: 1880 kcal
      _crearDiaHistorico(
        index: 1,
        nombre: 'Ma',
        comidas: [
          _crearComida(
            titulo: 'Filet de salmón a la plancha',
            tipo: 'ALMUERZO',
            calorias: 740,
            score: 93,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 220, 420, 46.0, 0.0, 25.0),
              _crearIng(
                'Arroz integral',
                '🍚',
                150,
                180,
                4.0,
                38.0,
                1.5,
                alacenaId: 'ing_alacena_arroz',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                15,
                140,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pechuga grillé con batatas',
            tipo: 'CENA',
            calorias: 540,
            score: 90,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 180, 290, 40.0, 0.0, 5.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                40,
                150,
                5.0,
                26.0,
                3.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Hojas verdes', '🥗', 150, 100, 2.0, 15.0, 3.0),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno de avena con yogur',
            tipo: 'DESAYUNO',
            calorias: 390,
            score: 89,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Yogur descremado', '🥛', 150, 110, 9.0, 12.0, 2.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                10,
                60,
                2.0,
                2.0,
                5.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Yogur con arándanos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 92,
            ingredientes: [
              _crearIng('Yogur griego', '🥛', 150, 140, 12.0, 8.0, 5.0),
              _crearIng('Arándanos', '🫐', 80, 50, 1.0, 12.0, 0.5),
              _crearIng('Almendras', '🥜', 10, 60, 2.0, 2.0, 5.0),
            ],
          ),
        ],
      ), // Total Ma: 1920 kcal
      _crearDiaHistorico(
        index: 2,
        nombre: 'Mi',
        comidas: [
          _crearComida(
            titulo: 'Salmón con vegetales al wok',
            tipo: 'ALMUERZO',
            calorias: 790,
            score: 95,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 210, 400, 44.0, 0.0, 24.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                70,
                250,
                9.5,
                44.0,
                4.5,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                15,
                140,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pechuga con arroz y palta',
            tipo: 'CENA',
            calorias: 600,
            score: 92,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                150,
                180,
                4.0,
                38.0,
                1.5,
                alacenaId: 'ing_alacena_arroz',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                10,
                100,
                0.0,
                0.0,
                10.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Omelette y tostadas',
            tipo: 'DESAYUNO',
            calorias: 410,
            score: 91,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 120, 180, 15.0, 1.0, 12.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                60,
                160,
                6.0,
                30.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso untable',
                '🧀',
                35,
                70,
                5.0,
                2.0,
                4.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Snack de frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 92,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Nueces',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
        ],
      ), // Total Mi: 2050 kcal
      _crearDiaHistorico(
        index: 3,
        nombre: 'Ju',
        comidas: [
          _crearComida(
            titulo: 'Pollo grille con arroz y verduras',
            tipo: 'ALMUERZO',
            calorias: 690,
            score: 90,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                16,
                150,
                0.0,
                0.0,
                16.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Salmón fresco con ensalada',
            tipo: 'CENA',
            calorias: 520,
            score: 89,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 190, 360, 40.0, 0.0, 21.0),
              _crearIng('Ensalada verde mixta', '🥗', 150, 90, 2.0, 12.0, 3.0),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                8,
                70,
                0.0,
                0.0,
                8.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Tazón de avena tibia',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 88,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                70,
                250,
                9.0,
                44.0,
                4.5,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Leche descremada', '🥛', 150, 80, 6.0, 9.0, 1.5),
              _crearIng('Nueces picadas', '🥜', 12, 70, 2.5, 2.5, 6.0),
            ],
          ),
          _crearComida(
            titulo: 'Merienda frutal',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 91,
            ingredientes: [
              _crearIng('Banana', '🍌', 120, 110, 1.5, 27.0, 0.3),
              _crearIng('Yogur descremado', '🥛', 150, 140, 11.0, 12.0, 3.0),
            ],
          ),
        ],
      ), // Total Ju: 1860 kcal
      _crearDiaHistorico(
        index: 4,
        nombre: 'Vi',
        comidas: [
          _crearComida(
            titulo: 'Salmón con papas y cena social',
            tipo: 'ALMUERZO',
            calorias: 880,
            score: 84,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 230, 440, 48.0, 0.0, 26.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                80,
                290,
                11.0,
                50.0,
                5.5,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                16,
                150,
                0.0,
                0.0,
                16.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pizza casera de masa madre',
            tipo: 'CENA',
            calorias: 720,
            score: 80,
            ingredientes: [
              _crearIng(
                'Masa madre con muzzarella',
                '🍕',
                220,
                540,
                22.0,
                62.0,
                22.0,
              ),
              _crearIng('Aceitunas verdes', '🫒', 30, 60, 0.5, 1.0, 6.0),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                12,
                120,
                0.0,
                0.0,
                12.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno calórico',
            tipo: 'DESAYUNO',
            calorias: 420,
            score: 86,
            ingredientes: [
              _crearIng('Tostadas con dulce', '🍞', 80, 220, 5.0, 45.0, 2.0),
              _crearIng('Huevos de campo', '🍳', 100, 150, 13.0, 1.0, 10.0),
              _crearIng('Queso crema', '🧀', 25, 50, 4.0, 1.5, 3.0),
            ],
          ),
          _crearComida(
            titulo: 'Merienda de la tarde',
            tipo: 'MERIENDA',
            calorias: 260,
            score: 88,
            ingredientes: [
              _crearIng('Yogur y granola', '🥣', 180, 180, 8.0, 26.0, 4.0),
              _crearIng('Nueces', '🥜', 12, 80, 2.5, 2.5, 7.0),
            ],
          ),
        ],
      ), // Total Vi: 2280 kcal (exceso que cortó la racha)
      _crearDiaHistorico(
        index: 5,
        nombre: 'Sa',
        comidas: [
          _crearComida(
            titulo: 'Salmón rosado con batata asada',
            tipo: 'ALMUERZO',
            calorias: 780,
            score: 93,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 220, 420, 46.0, 0.0, 25.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                15,
                140,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo y verduras al horno',
            tipo: 'CENA',
            calorias: 600,
            score: 91,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng('Vegetales variados', '🥦', 180, 140, 4.0, 24.0, 2.0),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                15,
                140,
                0.0,
                0.0,
                15.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno de sábado',
            tipo: 'DESAYUNO',
            calorias: 440,
            score: 91,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                70,
                250,
                9.0,
                44.0,
                4.5,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Huevos revueltos', '🍳', 100, 140, 12.0, 1.0, 9.5),
              _crearIng('Queso untable', '🧀', 25, 50, 4.0, 1.5, 3.0),
            ],
          ),
          _crearComida(
            titulo: 'Snack saludable',
            tipo: 'MERIENDA',
            calorias: 280,
            score: 92,
            ingredientes: [
              _crearIng('Yogur griego', '🥛', 150, 140, 12.0, 8.0, 5.0),
              _crearIng('Almendras y pasas', '🥜', 25, 140, 4.0, 12.0, 9.0),
            ],
          ),
        ],
      ), // Total Sa: 2100 kcal (en rango!)
      _crearDiaHistorico(
        index: 6,
        nombre: 'Do',
        comidas: [
          _crearComida(
            titulo: 'Pescado fresco con puré mixto',
            tipo: 'ALMUERZO',
            calorias: 740,
            score: 93,
            ingredientes: [
              _crearIng('Salmón rosado', '🐟', 210, 400, 44.0, 0.0, 24.0),
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                13,
                120,
                0.0,
                0.0,
                13.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Cena ligera de pollo',
            tipo: 'CENA',
            calorias: 540,
            score: 92,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 190, 300, 42.0, 0.0, 5.5),
              _crearIng('Calabaza horneada', '🎃', 200, 140, 3.0, 30.0, 1.0),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                11,
                100,
                0.0,
                0.0,
                11.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Tostadas y huevos',
            tipo: 'DESAYUNO',
            calorias: 430,
            score: 90,
            ingredientes: [
              _crearIng(
                'Tostadas integrales',
                '🍞',
                70,
                190,
                7.0,
                36.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng('Huevos de campo', '🍳', 110, 170, 14.0, 1.0, 11.0),
              _crearIng(
                'Queso untable',
                '🧀',
                35,
                70,
                5.5,
                2.0,
                3.5,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Merienda de domingo',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 91,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Nueces',
                '🥜',
                22,
                150,
                4.5,
                4.0,
                13.0,
                alacenaId: 'ing_alacena_nueces',
              ),
            ],
          ),
        ],
      ), // Total Do: 1980 kcal (en rango!)
    ];
  }

  List<DiarioDia> _construirHaceTresSemanas() {
    return [
      _crearDiaHistorico(
        index: 0,
        nombre: 'Lu',
        comidas: [
          _crearComida(
            titulo: 'Bowl de atún y arroz yamaní',
            tipo: 'ALMUERZO',
            calorias: 740,
            score: 93,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 220, 270, 52.0, 0.0, 3.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                200,
                260,
                5.5,
                54.0,
                2.0,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                210,
                6.0,
                6.0,
                18.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Cena de pollo y vegetales',
            tipo: 'CENA',
            calorias: 560,
            score: 92,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 180, 290, 40.0, 0.0, 5.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                120,
                160,
                3.5,
                33.0,
                1.2,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Aceite de oliva',
                '🫒',
                12,
                110,
                0.0,
                0.0,
                12.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno de avena con frutas',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 91,
            ingredientes: [
              _crearIng(
                'Avena en copos',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Huevos de campo', '🍳', 80, 120, 10.0, 1.0, 8.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                10,
                60,
                2.0,
                2.0,
                5.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Snack proteico',
            tipo: 'MERIENDA',
            calorias: 240,
            score: 92,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                18,
                120,
                3.5,
                3.5,
                10.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Lu: 1940 kcal
      _crearDiaHistorico(
        index: 1,
        nombre: 'Ma',
        comidas: [
          _crearComida(
            titulo: 'Atún con arroz y verduras salteadas',
            tipo: 'ALMUERZO',
            calorias: 760,
            score: 94,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 210, 260, 50.0, 0.0, 3.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                220,
                290,
                6.0,
                60.0,
                2.2,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                210,
                6.0,
                6.0,
                18.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo al horno con ensalada',
            tipo: 'CENA',
            calorias: 580,
            score: 92,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                110,
                145,
                3.0,
                30.0,
                1.0,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                12,
                115,
                0.0,
                0.0,
                12.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Huevos con tostadas integrales',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 91,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 110, 170, 14.0, 1.0, 11.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                60,
                160,
                6.0,
                30.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso untable',
                '🧀',
                35,
                70,
                5.0,
                2.0,
                4.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Yogur con frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 93,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Ma: 1990 kcal
      _crearDiaHistorico(
        index: 2,
        nombre: 'Mi',
        comidas: [
          _crearComida(
            titulo: 'Ensalada tibia de atún yamaní',
            tipo: 'ALMUERZO',
            calorias: 770,
            score: 95,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 230, 280, 54.0, 0.0, 3.5),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                210,
                275,
                5.8,
                57.0,
                2.1,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                215,
                6.0,
                6.0,
                18.5,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pechuga a la plancha con puré',
            tipo: 'CENA',
            calorias: 590,
            score: 93,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng(
                'Puré de zapallo',
                '🎃',
                200,
                150,
                3.0,
                32.0,
                1.5,
                alacenaId: 'ing_alacena_zapallo',
              ),
              _crearIng(
                'Aceite de oliva',
                '🫒',
                13,
                120,
                0.0,
                0.0,
                13.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Tostadas y revuelto',
            tipo: 'DESAYUNO',
            calorias: 410,
            score: 92,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 110, 170, 14.0, 1.0, 11.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                65,
                170,
                6.5,
                32.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso untable light',
                '🧀',
                35,
                70,
                5.0,
                2.0,
                4.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Snack de frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 93,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Mi: 2020 kcal
      _crearDiaHistorico(
        index: 3,
        nombre: 'Ju',
        comidas: [
          _crearComida(
            titulo: 'Atún sellado con arroz yamaní',
            tipo: 'ALMUERZO',
            calorias: 760,
            score: 93,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 210, 260, 50.0, 0.0, 3.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                220,
                290,
                6.0,
                60.0,
                2.2,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                210,
                6.0,
                6.0,
                18.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo grille con arroz y verduras',
            tipo: 'CENA',
            calorias: 570,
            score: 91,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 190, 305, 42.0, 0.0, 5.5),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                120,
                160,
                3.5,
                33.0,
                1.2,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                11,
                105,
                0.0,
                0.0,
                11.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno nutritivo',
            tipo: 'DESAYUNO',
            calorias: 400,
            score: 90,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Huevos de campo', '🍳', 90, 130, 11.0, 1.0, 8.5),
              _crearIng(
                'Frutos secos',
                '🥜',
                8,
                50,
                1.5,
                1.5,
                4.5,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Yogur y frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 92,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Ju: 1980 kcal
      _crearDiaHistorico(
        index: 4,
        nombre: 'Vi',
        comidas: [
          _crearComida(
            titulo: 'Wok de atún, arroz yamaní y vegetales',
            tipo: 'ALMUERZO',
            calorias: 820,
            score: 90,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 230, 280, 54.0, 0.0, 3.5),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                240,
                320,
                6.5,
                66.0,
                2.5,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                32,
                220,
                6.5,
                6.5,
                19.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo y ensalada fresca',
            tipo: 'CENA',
            calorias: 630,
            score: 89,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 210, 340, 46.0, 0.0, 6.5),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                130,
                170,
                3.8,
                35.0,
                1.3,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                13,
                120,
                0.0,
                0.0,
                13.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Omelette y tostadas',
            tipo: 'DESAYUNO',
            calorias: 430,
            score: 90,
            ingredientes: [
              _crearIng('Huevos de campo', '🍳', 120, 180, 15.0, 1.0, 12.0),
              _crearIng(
                'Tostadas integrales',
                '🍞',
                65,
                170,
                6.5,
                32.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng(
                'Queso magro',
                '🧀',
                40,
                80,
                8.0,
                1.0,
                5.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Merienda de yogur',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 91,
            ingredientes: [
              _crearIng('Yogur griego', '🥛', 150, 140, 12.0, 8.0, 5.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Vi: 2150 kcal
      _crearDiaHistorico(
        index: 5,
        nombre: 'Sa',
        comidas: [
          _crearComida(
            titulo: 'Pastel de pescado casero con arroz',
            tipo: 'ALMUERZO',
            calorias: 790,
            score: 92,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 220, 270, 52.0, 0.0, 3.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                230,
                305,
                6.2,
                63.0,
                2.3,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                215,
                6.0,
                6.0,
                18.5,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pechuga a la plancha con vegetales',
            tipo: 'CENA',
            calorias: 600,
            score: 90,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 200, 320, 44.0, 0.0, 6.0),
              _crearIng('Calabaza horneada', '🎃', 220, 160, 3.5, 35.0, 1.2),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                13,
                120,
                0.0,
                0.0,
                13.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pancakes proteicos',
            tipo: 'DESAYUNO',
            calorias: 420,
            score: 91,
            ingredientes: [
              _crearIng(
                'Avena tradicional',
                '🌾',
                60,
                220,
                8.0,
                36.0,
                4.0,
                alacenaId: 'ing_alacena_avena',
              ),
              _crearIng('Huevos de campo', '🍳', 100, 150, 13.0, 1.0, 10.0),
              _crearIng('Miel pura', '🍯', 15, 50, 0.2, 12.0, 0.0),
            ],
          ),
          _crearComida(
            titulo: 'Frutas secas y yogur',
            tipo: 'MERIENDA',
            calorias: 270,
            score: 91,
            ingredientes: [
              _crearIng('Yogur descremado', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                22,
                150,
                4.5,
                4.0,
                13.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Sa: 2080 kcal
      _crearDiaHistorico(
        index: 6,
        nombre: 'Do',
        comidas: [
          _crearComida(
            titulo: 'Guiso magro con atún y legumbres',
            tipo: 'ALMUERZO',
            calorias: 740,
            score: 94,
            ingredientes: [
              _crearIng('Atún al natural', '🐟', 220, 270, 52.0, 0.0, 3.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                200,
                260,
                5.5,
                54.0,
                2.0,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Frutos secos',
                '🥜',
                30,
                210,
                6.0,
                6.0,
                18.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Pollo grillé con ensalada verde',
            tipo: 'CENA',
            calorias: 550,
            score: 93,
            ingredientes: [
              _crearIng('Pechuga de pollo', '🍗', 180, 290, 40.0, 0.0, 5.0),
              _crearIng(
                'Arroz yamaní',
                '🍚',
                110,
                145,
                3.0,
                30.0,
                1.0,
                alacenaId: 'ing_alacena_yamani',
              ),
              _crearIng(
                'Aceite de oliva virgen',
                '🫒',
                12,
                115,
                0.0,
                0.0,
                12.0,
                alacenaId: 'ing_alacena_aceite',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Desayuno dominical',
            tipo: 'DESAYUNO',
            calorias: 410,
            score: 92,
            ingredientes: [
              _crearIng(
                'Tostadas integrales',
                '🍞',
                70,
                190,
                7.0,
                36.0,
                2.0,
                alacenaId: 'ing_alacena_pan',
              ),
              _crearIng('Huevos de campo', '🍳', 100, 150, 13.0, 1.0, 10.0),
              _crearIng(
                'Queso untable light',
                '🧀',
                35,
                70,
                5.0,
                2.0,
                4.0,
                alacenaId: 'ing_alacena_queso',
              ),
            ],
          ),
          _crearComida(
            titulo: 'Yogur y frutos secos',
            tipo: 'MERIENDA',
            calorias: 250,
            score: 93,
            ingredientes: [
              _crearIng('Yogur natural', '🥛', 150, 120, 10.0, 12.0, 3.0),
              _crearIng(
                'Frutos secos',
                '🥜',
                20,
                130,
                4.0,
                4.0,
                11.0,
                alacenaId: 'ing_alacena_frutos',
              ),
            ],
          ),
        ],
      ), // Total Do: 1950 kcal
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers constructores de Entidades
  // ---------------------------------------------------------------------------
  static DiarioDia _crearDiaHistorico({
    required int index,
    required String nombre,
    required List<ComidaItem> comidas,
  }) {
    return DiarioDia(
      diaIndex: index,
      diaNombre: nombre,
      metaCalorias: 2000,
      comidas: comidas,
    );
  }

  static ComidaItem _crearComida({
    required String titulo,
    required String tipo,
    required int calorias,
    required int score,
    required List<ComidaIngrediente> ingredientes,
  }) {
    return ComidaItem(
      id: 'hist_${titulo.toLowerCase().replaceAll(' ', '_')}',
      titulo: titulo,
      tipoComida: tipo,
      descripcion: ingredientes.map((i) => i.nombre).take(3).join(', '),
      healthScore: score,
      hora: tipo == 'DESAYUNO'
          ? '08:30'
          : tipo == 'ALMUERZO'
          ? '13:00'
          : tipo == 'MERIENDA'
          ? '17:30'
          : '21:00',
      ingredientes: ingredientes,
    );
  }

  static ComidaIngrediente _crearIng(
    String nombre,
    String emoji,
    double gramos,
    int calorias,
    double p,
    double c,
    double g, {
    String? alacenaId,
  }) {
    final factor = gramos > 0 ? (100.0 / gramos) : 1.0;
    return ComidaIngrediente(
      id: 'ing_${nombre.toLowerCase().replaceAll(' ', '_')}',
      ingredienteAlacenaId: alacenaId,
      nombre: nombre,
      emoji: emoji,
      gramos: gramos,
      calorias: calorias,
      proteinas: p,
      carbohidratos: c,
      grasas: g,
      caloriasPor100g: calorias * factor,
      proteinasPor100g: p * factor,
      carbosPor100g: c * factor,
      grasasPor100g: g * factor,
    );
  }

  // ---------------------------------------------------------------------------
  // Cálculo de Alimentos Top por Macronutriente
  // ---------------------------------------------------------------------------
  TopIngredienteMacro? _calcularTopMacro(
    List<ComidaIngrediente> ingredientes, {
    required String tipoMacro,
    required double Function(ComidaIngrediente) valorExtractor,
  }) {
    final Map<String, _AcumuladorMacro> mapa = {};

    for (final ing in ingredientes) {
      final key = ing.nombre.toLowerCase().trim();
      final aporte = valorExtractor(ing);
      if (!mapa.containsKey(key)) {
        mapa[key] = _AcumuladorMacro(
          nombre: ing.nombre,
          emoji: ing.emoji,
          tipoMacro: tipoMacro,
        );
      }
      mapa[key]!.aporteTotal += aporte;
      mapa[key]!.gramosAlimentoTotal += ing.gramos;
      mapa[key]!.vecesConsumido += 1;
    }

    if (mapa.isEmpty) return null;

    final lista = mapa.values.toList()
      ..sort((a, b) => b.aporteTotal.compareTo(a.aporteTotal));

    final ganador = lista.first;
    if (ganador.aporteTotal <= 0) return null;

    return TopIngredienteMacro(
      nombre: ganador.nombre,
      emoji: ganador.emoji,
      aporteMacroGramos: double.parse(ganador.aporteTotal.toStringAsFixed(1)),
      gramosAlimentoTotales: ganador.gramosAlimentoTotal,
      vecesConsumido: ganador.vecesConsumido,
      tipoMacro: tipoMacro,
    );
  }
}

class _AcumuladorMacro {
  final String nombre;
  final String emoji;
  final String tipoMacro;
  double aporteTotal = 0.0;
  double gramosAlimentoTotal = 0.0;
  int vecesConsumido = 0;

  _AcumuladorMacro({
    required this.nombre,
    required this.emoji,
    required this.tipoMacro,
  });
}
