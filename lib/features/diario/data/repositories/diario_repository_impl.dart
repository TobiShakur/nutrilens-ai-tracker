// REPOSITORIO DE DIARIO CON GENERACIÓN DINÁMICA DE FECHAS Y PERSISTENCIA LOCAL OFFLINE
// Proporciona el dataset generado con cálculos de DateTime y planes de comida realistas
// simulando la base de datos de un usuario nutricional activo.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/comida_ingrediente.dart';
import '../../domain/entities/comida_item.dart';
import '../../domain/entities/diario_dia.dart';
import '../../domain/repositories/diario_repository.dart';

/// Implementación del repositorio de diario con fechas dinámicas y persistencia offline.
class DiarioRepositoryImpl implements DiarioRepository {
  final LocalStorageService? storageService;
  final DateTime? fechaReferencia;

  static const List<String> _abrevDias = [
    'Do',
    'Lu',
    'Ma',
    'Mi',
    'Ju',
    'Vi',
    'Sa',
  ];

  static const int _diasAtras = 30; // 1 mes (30 días) de historial hacia atrás
  static const int _diasAdelante =
      4; // 4 días hacia adelante desde el día actual

  int _secuencia = 0;

  DiarioRepositoryImpl({this.storageService, this.fechaReferencia});

  DateTime get _fechaHoy {
    final now = fechaReferencia ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatearFechaIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Map<int, DiarioDia> getDiasIniciales() {
    final hoy = _fechaHoy;
    final hoyIso = _formatearFechaIso(hoy);
    const totalDias = _diasAtras + 1 + _diasAdelante;
    final iniciales = _generarSemillaDinamica(hoy);

    final guardado = storageService?.obtenerDias();
    if (guardado != null && guardado.isNotEmpty) {
      if (guardado.length == totalDias &&
          guardado[_diasAtras]?.fechaIso == hoyIso) {
        return guardado;
      }

      final porFecha = <String, DiarioDia>{};
      for (final dia in guardado.values) {
        if (dia.fechaIso != null) {
          porFecha[dia.fechaIso!] = dia;
        }
      }

      if (porFecha.isNotEmpty) {
        final sincronizado = <int, DiarioDia>{};
        for (final entry in iniciales.entries) {
          final base = entry.value;
          final previo = base.fechaIso != null
              ? porFecha[base.fechaIso!]
              : null;
          if (previo != null) {
            final usarComidasPrevias =
                previo.comidas.isNotEmpty || entry.key != _diasAtras;
            sincronizado[entry.key] = base.copyWith(
              metaCalorias: previo.metaCalorias,
              metaProteinas: previo.metaProteinas,
              metaGrasas: previo.metaGrasas,
              metaCarbos: previo.metaCarbos,
              comidas: usarComidasPrevias ? previo.comidas : base.comidas,
            );
          } else {
            sincronizado[entry.key] = base;
          }
        }
        storageService?.guardarDias(sincronizado);
        return sincronizado;
      }
    }

    storageService?.guardarDias(iniciales);
    return iniciales;
  }

  @override
  Future<void> guardarDias(Map<int, DiarioDia> dias) async {
    await storageService?.guardarDias(dias);
  }

  /// Genera dinámicamente la ventana de 1 mes atrás, día actual y 4 días adelante.
  Map<int, DiarioDia> _generarSemillaDinamica(DateTime hoy) {
    final map = <int, DiarioDia>{};
    const totalDias = _diasAtras + 1 + _diasAdelante;

    for (int i = 0; i < totalDias; i++) {
      final offset = i - _diasAtras;
      final date = hoy.add(Duration(days: offset));
      final fechaIso = _formatearFechaIso(date);
      final abrev = _abrevDias[date.weekday % 7];
      final isHoy = offset == 0;
      final diaNombre = isHoy ? 'Hoy' : abrev;
      final titulo = isHoy ? 'Hoy' : '$abrev ${date.day}';

      if (isHoy) {
        // Día activo en curso (~1255 kcal registradas)
        map[i] = DiarioDia(
          diaIndex: i,
          diaNombre: diaNombre,
          titulo: titulo,
          fechaIso: fechaIso,
          metaCalorias: 2135,
          metaProteinas: 190.0,
          metaGrasas: 130.0,
          metaCarbos: 64.0,
          comidas: _comidasHoy,
        );
      } else if (offset > 0) {
        // Días futuros limpios para registro
        map[i] = DiarioDia(
          diaIndex: i,
          diaNombre: diaNombre,
          titulo: titulo,
          fechaIso: fechaIso,
          metaCalorias: 2135,
          metaProteinas: 190.0,
          metaGrasas: 130.0,
          metaCarbos: 64.0,
          comidas: const [],
        );
      } else {
        // Días pasados generados a partir de los planes simulados del usuario
        map[i] = _generarDiaPasado(
          index: i,
          diaNombre: diaNombre,
          titulo: titulo,
          fechaIso: fechaIso,
          offset: offset,
        );
      }
    }

    return map;
  }

  DiarioDia _generarDiaPasado({
    required int index,
    required String diaNombre,
    required String titulo,
    required String fechaIso,
    required int offset,
  }) {
    if (offset == -11) {
      // Día de baja ingesta/descanso para calibrar la racha en 11 días
      return DiarioDia(
        diaIndex: index,
        diaNombre: diaNombre,
        titulo: titulo,
        fechaIso: fechaIso,
        metaCalorias: 2135,
        metaProteinas: 190.0,
        metaGrasas: 130.0,
        metaCarbos: 64.0,
        comidas: _planDescanso,
      );
    }

    final plan = _planesRotativos[index.abs() % _planesRotativos.length];
    return DiarioDia(
      diaIndex: index,
      diaNombre: diaNombre,
      titulo: titulo,
      fechaIso: fechaIso,
      metaCalorias: 2135,
      metaProteinas: 190.0,
      metaGrasas: 130.0,
      metaCarbos: 64.0,
      comidas: plan,
    );
  }

  @override
  ComidaItem generarComidaAleatoria(int numeroComida) {
    final random = Random();
    final muestra = _recetasMuestra[random.nextInt(_recetasMuestra.length)];
    final id =
        'comida_${DateTime.now().microsecondsSinceEpoch}_${_secuencia++}';

    return ComidaItem(
      id: id,
      titulo: muestra['titulo'] as String,
      tipoComida: muestra['tipo'] as String?,
      descripcion: muestra['descripcion'] as String?,
      calorias: muestra['calorias'] as int,
      metaCalorias: muestra['meta'] as int?,
      proteinas: (muestra['proteinas'] as num).toDouble(),
      grasas: (muestra['grasas'] as num).toDouble(),
      carbohidratos: (muestra['carbos'] as num).toDouble(),
      healthScore: muestra['score'] as int,
      hora:
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      icono: muestra['icono'] as IconData,
    );
  }

  // ===========================================================================
  // BASE DE DATOS SIMULADA DEL USUARIO (COMIDAS E INGREDIENTES REALES)
  // ===========================================================================

  static final List<ComidaItem> _comidasHoy = [
    const ComidaItem(
      id: 'comida_hoy_1',
      titulo: 'Huevos revueltos, pan integral y café',
      tipoComida: 'DESAYUNO',
      descripcion: 'Huevos de campo, tostadas Fargo con queso Finlandia',
      metaCalorias: 400,
      healthScore: 94,
      hora: '08:45',
      icono: Icons.coffee_outlined,
      ingredientes: [
        ComidaIngrediente(
          id: 'ci_h_1',
          ingredienteAlacenaId: 'ing_1',
          nombre: 'Huevos de campo',
          emoji: '🥩',
          gramos: 120.0,
          calorias: 172,
          proteinas: 15.6,
          carbohidratos: 1.2,
          grasas: 12.0,
          caloriasPor100g: 143.0,
          proteinasPor100g: 13.0,
          carbosPor100g: 1.0,
          grasasPor100g: 10.0,
        ),
        ComidaIngrediente(
          id: 'ci_h_2',
          ingredienteAlacenaId: 'ing_4',
          nombre: 'Pan integral 100%',
          marca: 'Fargo',
          emoji: '🍞',
          gramos: 50.0,
          calorias: 120,
          proteinas: 4.5,
          carbohidratos: 22.0,
          grasas: 1.5,
          caloriasPor100g: 240.0,
          proteinasPor100g: 9.0,
          carbosPor100g: 44.0,
          grasasPor100g: 3.0,
        ),
        ComidaIngrediente(
          id: 'ci_h_3',
          ingredienteAlacenaId: 'ing_7',
          nombre: 'Queso untable light',
          marca: 'Finlandia',
          emoji: '🧀',
          gramos: 30.0,
          calorias: 29,
          proteinas: 2.6,
          carbohidratos: 1.2,
          grasas: 1.5,
          caloriasPor100g: 97.0,
          proteinasPor100g: 8.7,
          carbosPor100g: 4.0,
          grasasPor100g: 5.0,
        ),
        ComidaIngrediente(
          id: 'ci_h_4',
          nombre: 'Café espresso',
          emoji: '☕',
          gramos: 120.0,
          calorias: 10,
          proteinas: 0.5,
          carbohidratos: 1.5,
          grasas: 0.2,
          caloriasPor100g: 8.0,
          proteinasPor100g: 0.4,
          carbosPor100g: 1.2,
          grasasPor100g: 0.1,
        ),
      ],
    ),
    const ComidaItem(
      id: 'comida_hoy_2',
      titulo: 'Bowl de pollo, arroz y palta',
      tipoComida: 'ALMUERZO',
      descripcion: 'Pechuga grillada, arroz integral Gallo y palta Hass',
      metaCalorias: 700,
      healthScore: 96,
      hora: '13:20',
      icono: Icons.restaurant_outlined,
      ingredientes: [
        ComidaIngrediente(
          id: 'ci_h_5',
          ingredienteAlacenaId: 'ing_3',
          nombre: 'Pechuga de pollo',
          emoji: '🍗',
          gramos: 150.0,
          calorias: 248,
          proteinas: 46.5,
          carbohidratos: 0.0,
          grasas: 5.4,
          caloriasPor100g: 165.0,
          proteinasPor100g: 31.0,
          carbosPor100g: 0.0,
          grasasPor100g: 3.6,
        ),
        ComidaIngrediente(
          id: 'ci_h_6',
          ingredienteAlacenaId: 'ing_6',
          nombre: 'Arroz integral',
          marca: 'Gallo',
          emoji: '🍚',
          gramos: 100.0,
          calorias: 350,
          proteinas: 7.5,
          carbohidratos: 73.0,
          grasas: 2.8,
          caloriasPor100g: 350.0,
          proteinasPor100g: 7.5,
          carbosPor100g: 73.0,
          grasasPor100g: 2.8,
        ),
        ComidaIngrediente(
          id: 'ci_h_7',
          ingredienteAlacenaId: 'ing_5',
          nombre: 'Palta Hass',
          emoji: '🥑',
          gramos: 50.0,
          calorias: 80,
          proteinas: 1.0,
          carbohidratos: 4.2,
          grasas: 7.5,
          caloriasPor100g: 160.0,
          proteinasPor100g: 2.0,
          carbosPor100g: 8.5,
          grasasPor100g: 15.0,
        ),
      ],
    ),
    const ComidaItem(
      id: 'comida_hoy_3',
      titulo: 'Yogur con avena y frutos rojos',
      tipoComida: 'MERIENDA',
      descripcion: 'Avena Quáker con yogur natural y arándanos',
      metaCalorias: 300,
      healthScore: 97,
      hora: '17:15',
      icono: Icons.bakery_dining_outlined,
      ingredientes: [
        ComidaIngrediente(
          id: 'ci_h_8',
          ingredienteAlacenaId: 'ing_2',
          nombre: 'Avena tradicional',
          marca: 'Quáker',
          emoji: '🌾',
          gramos: 40.0,
          calorias: 148,
          proteinas: 5.6,
          carbohidratos: 24.0,
          grasas: 2.8,
          caloriasPor100g: 370.0,
          proteinasPor100g: 14.0,
          carbosPor100g: 60.0,
          grasasPor100g: 7.0,
        ),
        ComidaIngrediente(
          id: 'ci_h_9',
          nombre: 'Yogur natural con arándanos',
          emoji: '🫐',
          gramos: 150.0,
          calorias: 98,
          proteinas: 8.0,
          carbohidratos: 12.0,
          grasas: 1.5,
          caloriasPor100g: 65.0,
          proteinasPor100g: 5.3,
          carbosPor100g: 8.0,
          grasasPor100g: 1.0,
        ),
      ],
    ),
  ];

  static final List<List<ComidaItem>> _planesRotativos = [
    // Plan 1 (~1980 kcal, 137P, 68G, 181C)
    const [
      ComidaItem(
        id: 'p1_1',
        titulo: 'Bowl de avena y chía',
        tipoComida: 'DESAYUNO',
        descripcion: 'Avena cocida con leche descremada y semillas de chía',
        calorias: 400,
        metaCalorias: 400,
        proteinas: 16.0,
        grasas: 10.0,
        carbohidratos: 58.0,
        healthScore: 97,
        hora: '08:15',
        icono: Icons.bakery_dining_outlined,
      ),
      ComidaItem(
        id: 'p1_2',
        titulo: 'Pechuga grillada y arroz integral',
        tipoComida: 'ALMUERZO',
        descripcion: 'Pechuga con arroz Gallo y brócoli al vapor',
        calorias: 710,
        metaCalorias: 700,
        proteinas: 60.0,
        grasas: 18.0,
        carbohidratos: 70.0,
        healthScore: 96,
        hora: '13:00',
        icono: Icons.dinner_dining_outlined,
      ),
      ComidaItem(
        id: 'p1_3',
        titulo: 'Tostón integral con Finlandia',
        tipoComida: 'MERIENDA',
        descripcion: 'Pan tostado Fargo con queso untable light y café',
        calorias: 290,
        metaCalorias: 300,
        proteinas: 15.0,
        grasas: 8.0,
        carbohidratos: 35.0,
        healthScore: 94,
        hora: '17:00',
        icono: Icons.coffee_outlined,
      ),
      ComidaItem(
        id: 'p1_4',
        titulo: 'Omelette de espinaca y ensalada',
        tipoComida: 'CENA',
        descripcion: '3 huevos de campo, espinaca baby y tomates cherry',
        calorias: 580,
        metaCalorias: 600,
        proteinas: 46.0,
        grasas: 32.0,
        carbohidratos: 18.0,
        healthScore: 95,
        hora: '21:00',
        icono: Icons.egg_outlined,
      ),
    ],

    // Plan 2 (~2020 kcal, 149P, 68G, 174C)
    const [
      ComidaItem(
        id: 'p2_1',
        titulo: 'Huevos revueltos y tostadas integrales',
        tipoComida: 'DESAYUNO',
        descripcion: 'Huevos de campo revueltos y pan tostado Fargo',
        calorias: 410,
        metaCalorias: 400,
        proteinas: 25.0,
        grasas: 20.0,
        carbohidratos: 30.0,
        healthScore: 94,
        hora: '08:30',
        icono: Icons.egg_outlined,
      ),
      ComidaItem(
        id: 'p2_2',
        titulo: 'Bife de lomo con puré de batata',
        tipoComida: 'ALMUERZO',
        descripcion: 'Corte magro a la plancha con puré de batata rústico',
        calorias: 720,
        metaCalorias: 700,
        proteinas: 60.0,
        grasas: 22.0,
        carbohidratos: 64.0,
        healthScore: 95,
        hora: '13:15',
        icono: Icons.restaurant_outlined,
      ),
      ComidaItem(
        id: 'p2_3',
        titulo: 'Yogur natural con frutos secos',
        tipoComida: 'MERIENDA',
        descripcion: 'Yogur descremado con nueces y arándanos frescos',
        calorias: 300,
        metaCalorias: 300,
        proteinas: 16.0,
        grasas: 10.0,
        carbohidratos: 32.0,
        healthScore: 96,
        hora: '17:15',
        icono: Icons.local_cafe_outlined,
      ),
      ComidaItem(
        id: 'p2_4',
        titulo: 'Filet de merluza con vegetales al vapor',
        tipoComida: 'CENA',
        descripcion: 'Pescado blanco con calabaza y zanahoria al vapor',
        calorias: 590,
        metaCalorias: 600,
        proteinas: 48.0,
        grasas: 16.0,
        carbohidratos: 48.0,
        healthScore: 94,
        hora: '21:15',
        icono: Icons.set_meal_outlined,
      ),
    ],

    // Plan 3 (~2040 kcal, 135P, 88G, 164C)
    const [
      ComidaItem(
        id: 'p3_1',
        titulo: 'Tostadas con palta y huevos pochados',
        tipoComida: 'DESAYUNO',
        descripcion: 'Pan integral tostado, palta Hass madura y 2 huevos',
        calorias: 420,
        metaCalorias: 450,
        proteinas: 22.0,
        grasas: 22.0,
        carbohidratos: 32.0,
        healthScore: 95,
        hora: '08:45',
        icono: Icons.egg_outlined,
      ),
      ComidaItem(
        id: 'p3_2',
        titulo: 'Wrap de pollo y palta Hass',
        tipoComida: 'ALMUERZO',
        descripcion: 'Pechuga desmenuzada, masa integral y vegetales frescos',
        calorias: 700,
        metaCalorias: 700,
        proteinas: 54.0,
        grasas: 24.0,
        carbohidratos: 58.0,
        healthScore: 93,
        hora: '13:20',
        icono: Icons.lunch_dining_outlined,
      ),
      ComidaItem(
        id: 'p3_3',
        titulo: 'Manzana con mantequilla de maní',
        tipoComida: 'MERIENDA',
        descripcion: 'Manzana fresca con pasta de maní 100% natural',
        calorias: 300,
        metaCalorias: 300,
        proteinas: 9.0,
        grasas: 16.0,
        carbohidratos: 32.0,
        healthScore: 96,
        hora: '17:20',
        icono: Icons.apple_outlined,
      ),
      ComidaItem(
        id: 'p3_4',
        titulo: 'Salmón rosado con calabaza asada',
        tipoComida: 'CENA',
        descripcion: 'Salmón a la plancha con rodajas de calabaza horneada',
        calorias: 620,
        metaCalorias: 650,
        proteinas: 50.0,
        grasas: 26.0,
        carbohidratos: 42.0,
        healthScore: 97,
        hora: '21:30',
        icono: Icons.dinner_dining_outlined,
      ),
    ],

    // Plan 4 (~2000 kcal, 148P, 68G, 170C)
    const [
      ComidaItem(
        id: 'p4_1',
        titulo: 'Bowl de yogur con granola y chía',
        tipoComida: 'DESAYUNO',
        descripcion: 'Yogur natural con granola artesanal y semillas',
        calorias: 390,
        metaCalorias: 400,
        proteinas: 20.0,
        grasas: 12.0,
        carbohidratos: 44.0,
        healthScore: 96,
        hora: '08:30',
        icono: Icons.bakery_dining_outlined,
      ),
      ComidaItem(
        id: 'p4_2',
        titulo: 'Asado magro con ensalada mixta',
        tipoComida: 'ALMUERZO',
        descripcion: 'Corte magro a las brasas con tomate, rúcula y papas',
        calorias: 730,
        metaCalorias: 750,
        proteinas: 64.0,
        grasas: 34.0,
        carbohidratos: 38.0,
        healthScore: 92,
        hora: '13:30',
        icono: Icons.outdoor_grill_outlined,
      ),
      ComidaItem(
        id: 'p4_3',
        titulo: 'Tostada integral con queso Finlandia',
        tipoComida: 'MERIENDA',
        descripcion: 'Pan Fargo tostado con queso untable light y café',
        calorias: 280,
        metaCalorias: 300,
        proteinas: 14.0,
        grasas: 8.0,
        carbohidratos: 36.0,
        healthScore: 94,
        hora: '17:15',
        icono: Icons.coffee_outlined,
      ),
      ComidaItem(
        id: 'p4_4',
        titulo: 'Salteado de pollo, quinoa y vegetales',
        tipoComida: 'CENA',
        descripcion: 'Cubos de pechuga con quinoa cocida y pimientos',
        calorias: 600,
        metaCalorias: 600,
        proteinas: 50.0,
        grasas: 14.0,
        carbohidratos: 52.0,
        healthScore: 96,
        hora: '21:15',
        icono: Icons.lunch_dining_outlined,
      ),
    ],
  ];

  static const List<ComidaItem> _planDescanso = [
    ComidaItem(
      id: 'p_desc_1',
      titulo: 'Café cortado con tostada',
      tipoComida: 'DESAYUNO',
      descripcion: 'Café con leche descremada y tostada integral',
      calorias: 210,
      metaCalorias: 350,
      proteinas: 9.0,
      grasas: 4.0,
      carbohidratos: 28.0,
      healthScore: 90,
      hora: '09:00',
      icono: Icons.coffee_outlined,
    ),
    ComidaItem(
      id: 'p_desc_2',
      titulo: 'Ensalada rápida de atún',
      tipoComida: 'ALMUERZO',
      descripcion: 'Atún al natural, hojas verdes y tomate',
      calorias: 450,
      metaCalorias: 700,
      proteinas: 42.0,
      grasas: 12.0,
      carbohidratos: 36.0,
      healthScore: 92,
      hora: '13:30',
      icono: Icons.dinner_dining_outlined,
    ),
    ComidaItem(
      id: 'p_desc_3',
      titulo: 'Manzana verde',
      tipoComida: 'MERIENDA',
      descripcion: 'Fruta fresca de estación',
      calorias: 90,
      metaCalorias: 250,
      proteinas: 1.0,
      grasas: 0.5,
      carbohidratos: 22.0,
      healthScore: 96,
      hora: '17:30',
      icono: Icons.apple_outlined,
    ),
    ComidaItem(
      id: 'p_desc_4',
      titulo: 'Sopa crema de calabaza',
      tipoComida: 'CENA',
      descripcion: 'Calabaza procesada con un toque de queso blanco',
      calorias: 360,
      metaCalorias: 600,
      proteinas: 14.0,
      grasas: 8.0,
      carbohidratos: 52.0,
      healthScore: 93,
      hora: '21:15',
      icono: Icons.soup_kitchen_outlined,
    ),
  ];

  static const List<Map<String, dynamic>> _recetasMuestra = [
    {
      'titulo': 'Poke Bowl con Salmón',
      'tipo': 'ALMUERZO',
      'descripcion': 'Salmón fresco, palta, arroz sushi, edamame',
      'calorias': 410,
      'meta': 550,
      'proteinas': 32.0,
      'grasas': 14.0,
      'carbos': 38.0,
      'score': 95,
      'icono': Icons.rice_bowl_outlined,
    },
    {
      'titulo': 'Huevos Revueltos con Tostadas',
      'tipo': 'DESAYUNO',
      'descripcion': 'Scramble de huevos de campo, pan integral',
      'calorias': 280,
      'meta': 350,
      'proteinas': 18.0,
      'grasas': 12.0,
      'carbos': 22.0,
      'score': 92,
      'icono': Icons.egg_outlined,
    },
    {
      'titulo': 'Bowl de Avena y Frutos Rojos',
      'tipo': 'DESAYUNO',
      'descripcion': 'Avena cocida, semillas de chía, arándanos',
      'calorias': 245,
      'meta': 300,
      'proteinas': 11.0,
      'grasas': 5.0,
      'carbos': 39.0,
      'score': 97,
      'icono': Icons.bakery_dining_outlined,
    },
    {
      'titulo': 'Wrap de Pollo Grillado',
      'tipo': 'CENA',
      'descripcion': 'Pechuga grillada, espinaca baby y hummus',
      'calorias': 350,
      'meta': 450,
      'proteinas': 34.0,
      'grasas': 8.0,
      'carbos': 35.0,
      'score': 89,
      'icono': Icons.lunch_dining_outlined,
    },
  ];
}
