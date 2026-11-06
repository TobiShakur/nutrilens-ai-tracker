import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/diario_dia.dart';
import 'package:nutrilens_provider/features/perfil/data/repositories/perfil_repository_impl.dart';
import 'package:nutrilens_provider/features/perfil/domain/entities/configuracion_nutricional.dart';
import 'package:nutrilens_provider/features/perfil/presentation/viewmodels/perfil_viewmodel.dart';

void main() {
  group('ConfiguracionNutricional & Tolerancias Independientes', () {
    test('Valores por defecto calculan ventana de 1800 a 2200 kcal', () {
      const config = ConfiguracionNutricional(
        metaCalorias: 2000,
        toleranciaInferior: 0.10,
        toleranciaSuperior: 0.10,
      );

      expect(config.limiteMinimoCalorias, 1800);
      expect(config.limiteMaximoCalorias, 2200);
      expect(config.esCaloriaEnRango(1800), isTrue);
      expect(config.esCaloriaEnRango(2200), isTrue);
      expect(config.esCaloriaEnRango(2000), isTrue);
      expect(config.esCaloriaEnRango(1799), isFalse);
      expect(config.esCaloriaEnRango(2201), isFalse);
    });

    test(
      'Límites inferior (-) y superior (+) se modifican independientemente',
      () {
        const config = ConfiguracionNutricional(
          metaCalorias: 2000,
          toleranciaInferior: 0.15, // -15%
          toleranciaSuperior: 0.05, // +5%
        );

        expect(config.limiteMinimoCalorias, 1700);
        expect(config.limiteMaximoCalorias, 2100);
        expect(config.toleranciaInferiorLabel, '-15%');
        expect(config.toleranciaSuperiorLabel, '+5%');
        expect(config.esCaloriaEnRango(1750), isTrue);
        expect(config.esCaloriaEnRango(2150), isFalse);
      },
    );
  });

  group('PerfilViewModel & Análisis Semanal', () {
    late PerfilRepositoryImpl repo;
    late PerfilViewModel vm;
    late List<DiarioDia> diasMock;

    setUp(() {
      repo = PerfilRepositoryImpl();
      vm = PerfilViewModel(repository: repo);

      // Creamos días con comidas e ingredientes para probar agregación analítica
      final comida1 = ComidaItem(
        id: 'c1',
        titulo: 'Almuerzo Proteico',
        tipoComida: 'ALMUERZO',
        descripcion: 'Huevos y Palta',
        healthScore: 95,
        hora: '13:00',
        ingredientes: [
          ComidaIngrediente.manual(
            id: 'i1',
            nombre: 'Huevos de campo',
            emoji: '🥩',
            gramos: 150,
            calorias: 215,
            proteinas: 19.5,
            carbohidratos: 1.5,
            grasas: 15.0,
          ),
          ComidaIngrediente.manual(
            id: 'i2',
            nombre: 'Palta Hass',
            emoji: '🥑',
            gramos: 80,
            calorias: 128,
            proteinas: 1.6,
            carbohidratos: 6.8,
            grasas: 12.0,
          ),
        ],
      );

      final comida2 = ComidaItem(
        id: 'c2',
        titulo: 'Desayuno Energético',
        tipoComida: 'DESAYUNO',
        descripcion: 'Avena tradicional',
        healthScore: 92,
        hora: '09:00',
        ingredientes: [
          ComidaIngrediente.manual(
            id: 'i3',
            nombre: 'Avena tradicional',
            emoji: '🌾',
            gramos: 80,
            calorias: 296,
            proteinas: 11.2,
            carbohidratos: 48.0,
            grasas: 5.6,
          ),
        ],
      );

      diasMock = [
        DiarioDia(
          diaIndex: 0,
          diaNombre: 'Lu',
          metaCalorias: 2000,
          comidas: [comida1],
        ),
        DiarioDia(
          diaIndex: 1,
          diaNombre: 'Ma',
          metaCalorias: 2000,
          comidas: [comida1, comida2],
        ),
      ];
    });

    test(
      'inicializar carga configuración y calcula métricas semanales',
      () async {
        await vm.inicializar(diasMock);

        expect(vm.cargando, isFalse);
        expect(vm.config.metaCalorias, 2000);
        expect(vm.metricas, isNotNull);
        expect(vm.metricas!.semanaTitulo, contains('Semana actual'));
        expect(vm.metricas!.topProteina?.nombre, 'Huevos de campo');
        expect(vm.metricas!.topCarbos?.nombre, 'Avena tradicional');
        expect(vm.metricas!.topGrasas?.nombre, 'Huevos de campo');
      },
    );

    test(
      'actualizarMetas actualiza Kcal y macros y recalcula métricas',
      () async {
        await vm.inicializar(diasMock);

        await vm.actualizarMetas(
          metaCalorias: 2400,
          metaProteinas: 170.0,
          metaCarbos: 260.0,
          metaGrasas: 75.0,
          historial: diasMock,
        );

        expect(vm.config.metaCalorias, 2400);
        expect(vm.config.metaProteinas, 170.0);
        expect(vm.config.metaCarbos, 260.0);
        expect(vm.config.metaGrasas, 75.0);
      },
    );

    test('ajustarToleranciaInferior y Superior ajustan con clamp', () async {
      await vm.inicializar(diasMock);

      await vm.ajustarToleranciaInferior(0.04, diasMock);
      expect(vm.config.toleranciaInferior, 0.14);

      await vm.ajustarToleranciaSuperior(-0.04, diasMock);
      expect(vm.config.toleranciaSuperior, 0.06);

      // Clamp mínimo
      await vm.ajustarToleranciaSuperior(-0.20, diasMock);
      expect(vm.config.toleranciaSuperior, 0.02);
    });

    test(
      'cambiarSemana modifica el offset y actualiza métricas diferenciadas por semana',
      () async {
        await vm.inicializar(diasMock);
        expect(vm.semanaOffset, 0);
        final metricasActual = vm.metricas!;
        expect(metricasActual.semanaTitulo, contains('Semana actual'));

        // Navegar a Semana Pasada
        await vm.cambiarSemana(-1, diasMock);
        expect(vm.semanaOffset, -1);
        final metricasPasada = vm.metricas!;
        expect(metricasPasada.semanaTitulo, contains('Semana pasada'));
        expect(metricasPasada.topProteina?.nombre, 'Bife de lomo');
        expect(metricasPasada.topCarbos?.nombre, 'Batata al horno');
        expect(metricasPasada.topGrasas?.nombre, 'Palta Hass');
        expect(metricasPasada.rachaActualDias, 9);
        expect(metricasPasada.healthScorePromedio, greaterThanOrEqualTo(90));

        // Navegar a Hace 2 Semanas
        await vm.cambiarSemana(-2, diasMock);
        expect(vm.semanaOffset, -2);
        final metricasHaceDos = vm.metricas!;
        expect(metricasHaceDos.semanaTitulo, contains('Hace 2 semanas'));
        expect(metricasHaceDos.topProteina?.nombre, 'Salmón rosado');
        expect(metricasHaceDos.topCarbos?.nombre, 'Avena tradicional');
        expect(metricasHaceDos.topGrasas?.nombre, 'Aceite de oliva virgen');
        expect(metricasHaceDos.rachaActualDias, 2);

        // Los datos son efectivamente dinámicos y distintos entre semanas
        expect(
          metricasPasada.topProteina?.nombre,
          isNot(metricasHaceDos.topProteina?.nombre),
        );

        // Navegar a una semana antigua sin registros (-4)
        await vm.cambiarSemana(-4, diasMock);
        expect(vm.semanaOffset, -4);
        final metricasVacia = vm.metricas!;
        expect(metricasVacia.rachaActualDias, 0);
        expect(metricasVacia.diasCumplidos, 0);
        expect(metricasVacia.totalDiasRegistrados, 0);
        expect(metricasVacia.porcentajeCumplimiento, 0.0);
        expect(metricasVacia.healthScorePromedio, 0);
        expect(metricasVacia.ratioAprovechamientoAlacena, 0.0);
        expect(metricasVacia.topProteina, isNull);
        expect(metricasVacia.topCarbos, isNull);
        expect(metricasVacia.topGrasas, isNull);
      },
    );
  });
}
