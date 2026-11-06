import '../../../alacena/domain/entities/ingrediente_alacena.dart';
import '../../../diario/domain/entities/comida_ingrediente.dart';
import '../../domain/entities/alimento_conflicto_marca.dart';
import '../../domain/entities/plato_detectado.dart';

abstract class ScannerDataSource {
  Future<PlatoDetectado> simularEscaneo({
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  });
}

class ScannerDataSourceImpl implements ScannerDataSource {
  int _contador = 0;

  final List<Map<String, dynamic>> _platosMuestra = [
    {
      'nombre': 'Huevos Revueltos con Tostadas',
      'score': 92,
      'items': [
        {
          'nombre': 'Huevos de campo',
          'claves': ['huevo', 'huevos'],
          'gramos': 100.0,
          'emoji': '🥩',
          'calorias': 143,
          'proteinas': 13.0,
          'carbos': 1.0,
          'grasas': 10.0,
        },
        {
          'nombre': 'Pan integral',
          'claves': ['pan', 'tostada'],
          'gramos': 50.0,
          'emoji': '🍞',
          'calorias': 120,
          'proteinas': 4.5,
          'carbos': 22.0,
          'grasas': 1.5,
        },
        {
          'nombre': 'Palta Hass',
          'claves': ['palta', 'aguacate'],
          'gramos': 40.0,
          'emoji': '🥑',
          'calorias': 64,
          'proteinas': 0.8,
          'carbos': 3.4,
          'grasas': 6.0,
        },
      ],
    },
    {
      'nombre': 'Poke Bowl de Salmón y Palta',
      'score': 95,
      'items': [
        {
          'nombre': 'Arroz integral',
          'claves': ['arroz'],
          'gramos': 80.0,
          'emoji': '🍚',
          'calorias': 280,
          'proteinas': 6.0,
          'carbos': 58.0,
          'grasas': 2.2,
        },
        {
          'nombre': 'Palta Hass',
          'claves': ['palta', 'aguacate'],
          'gramos': 50.0,
          'emoji': '🥑',
          'calorias': 80,
          'proteinas': 1.0,
          'carbos': 4.2,
          'grasas': 7.5,
        },
        {
          'nombre': 'Salmón fresco en cubos',
          'claves': ['salmón', 'salmon', 'pescado'],
          'gramos': 100.0,
          'emoji': '🐟',
          'calorias': 208,
          'proteinas': 20.0,
          'carbos': 0.0,
          'grasas': 13.0,
        },
      ],
    },
    {
      'nombre': 'Bowl de Avena con Yogur',
      'score': 96,
      'items': [
        {
          'nombre': 'Avena tradicional',
          'claves': ['avena'],
          'gramos': 60.0,
          'emoji': '🌾',
          'calorias': 222,
          'proteinas': 8.4,
          'carbos': 36.0,
          'grasas': 4.2,
        },
        {
          'nombre': 'Queso untable light',
          'claves': ['queso', 'yogur', 'lacteo'],
          'gramos': 40.0,
          'emoji': '🧀',
          'calorias': 38,
          'proteinas': 3.4,
          'carbos': 1.6,
          'grasas': 2.0,
        },
        {
          'nombre': 'Frutos rojos y arándanos',
          'claves': ['arándano', 'frutos', 'fruta'],
          'gramos': 50.0,
          'emoji': '🫐',
          'calorias': 28,
          'proteinas': 0.5,
          'carbos': 6.0,
          'grasas': 0.2,
        },
      ],
    },
  ];

  @override
  Future<PlatoDetectado> simularEscaneo({
    required bool preferirAlacena,
    required List<IngredienteAlacena> alacenaUsuario,
  }) async {
    // Simulación de latencia de red y procesamiento de visión
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final receta = _platosMuestra[_contador % _platosMuestra.length];
    _contador++;

    final itemsRaw = receta['items'] as List<Map<String, dynamic>>;
    final List<ComidaIngrediente> ingredientesFinales = [];
    final List<AlimentoConflictoMarca> conflictos = [];

    for (final raw in itemsRaw) {
      final nombre = raw['nombre'] as String;
      final claves = (raw['claves'] as List<String>);
      final gramos = (raw['gramos'] as num).toDouble();
      final emoji = raw['emoji'] as String;
      final caloriasGen = raw['calorias'] as int;
      final proteinasGen = (raw['proteinas'] as num).toDouble();
      final carbosGen = (raw['carbos'] as num).toDouble();
      final grasasGen = (raw['grasas'] as num).toDouble();

      if (preferirAlacena) {
        // Buscamos coincidencias en la alacena del usuario
        final coincidencias = alacenaUsuario.where((al) {
          final n = al.nombre.toLowerCase();
          return claves.any((k) => n.contains(k.toLowerCase()));
        }).toList();

        if (coincidencias.length == 1) {
          // Coincidencia exacta con 1 solo producto de la alacena: usamos sus macros exactos de paquete
          final al = coincidencias.first;
          ingredientesFinales.add(
            ComidaIngrediente.desdeAlacena(alacena: al, gramos: gramos),
          );
          continue;
        } else if (coincidencias.length > 1) {
          // Conflicto de marcas: el usuario tiene más de un producto que matchea (ej: Pan Fargo y Pan Lactal)
          conflictos.add(
            AlimentoConflictoMarca(
              nombreGenerico: nombre,
              gramosDetectados: gramos,
              opcionesAlacena: coincidencias,
            ),
          );
          // Agregamos provisoriamente la primera opción; el usuario la podrá cambiar en el diálogo
          ingredientesFinales.add(
            ComidaIngrediente.desdeAlacena(
              alacena: coincidencias.first,
              gramos: gramos,
            ),
          );
          continue;
        }
      }

      // Fallback genérico de la IA cuando no está en la alacena
      ingredientesFinales.add(
        ComidaIngrediente.manual(
          id: 'ci_scan_${DateTime.now().microsecondsSinceEpoch}_${ingredientesFinales.length}',
          nombre: nombre,
          emoji: emoji,
          gramos: gramos,
          calorias: caloriasGen,
          proteinas: proteinasGen,
          carbohidratos: carbosGen,
          grasas: grasasGen,
        ),
      );
    }

    return PlatoDetectado(
      id: 'plato_${DateTime.now().microsecondsSinceEpoch}',
      nombreSugerido: receta['nombre'] as String,
      ingredientes: ingredientesFinales,
      healthScore: receta['score'] as int,
      explicacionHealthScore:
          (receta['explicacion'] as String?) ??
          'Excelente densidad nutricional, alto en proteínas y grasas saludables.',
      conflictosMarcas: conflictos,
    );
  }
}
