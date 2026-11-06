import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/diario/data/repositories/diario_repository_impl.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_ingrediente.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/comida_item.dart';
import 'package:nutrilens_provider/features/diario/domain/entities/nivel_score.dart';
import 'package:nutrilens_provider/features/diario/presentation/viewmodels/diario_viewmodel.dart';

ComidaItem _comida(String id, int kcal, {int score = 90}) {
  return ComidaItem(
    id: id,
    titulo: 'Comida $id',
    calorias: kcal,
    proteinas: 10,
    grasas: 5,
    carbohidratos: 20,
    healthScore: score,
    hora: '12:00',
  );
}

void main() {
  late DiarioViewModel vm;
  late int notificaciones;

  setUp(() {
    vm = DiarioViewModel(repository: DiarioRepositoryImpl());
    notificaciones = 0;
    vm.addListener(() => notificaciones++);
  });

  group('Estado inicial', () {
    test('Hoy arranca con 3 comidas realistas y los números de la semilla', () {
      final hoy = vm.diaActual;

      expect(vm.diaSeleccionadoIndex, 30);
      expect(hoy.diaNombre, 'Hoy');
      expect(hoy.cantidadComidas, 3);
      expect(hoy.caloriasActuales, 1255);
      expect(hoy.caloriasRestantes, 880);
      expect(hoy.caloriasExtras, 0);
      expect(hoy.ratioVerde, closeTo(1255 / 2135, 0.001));
      expect(hoy.ratioNaranja, 0.0);
      expect(hoy.ratioRojo, 0.0);
      expect(hoy.promedioHealthScore, 96);
      expect(hoy.nivelScore, NivelScore.excelente);
    });
  });

  group('Navegación entre días', () {
    test(
      'diaTieneRacha y rachaDias identifican días cumplidos y racha acumulada',
      () {
        expect(vm.nombresDias.length, 34);
        expect(vm.rachaDias, 11);
        expect(
          vm.diaTieneRacha(29),
          isTrue,
        ); // Ayer (Ma 3, ~2020 kcal cumplido)
        expect(
          vm.diaTieneRacha(28),
          isTrue,
        ); // Anteayer (Lu 2, ~1980 kcal cumplido)
        expect(
          vm.diaTieneRacha(30),
          isFalse,
        ); // Hoy (1255 kcal, en curso aún no alcanzó meta)
        expect(vm.diaTieneRacha(31), isFalse); // Ju (0 kcal)
        expect(vm.diaTieneRacha(32), isFalse); // Vi (0 kcal)
        expect(vm.diaTieneRacha(33), isFalse); // Sa (0 kcal)
      },
    );

    test('seleccionarDia cambia de día y notifica una vez', () {
      vm.seleccionarDia(29);

      expect(vm.diaActual.diaNombre, 'Ma');
      expect(vm.diaActual.caloriasActuales, greaterThan(1900));
      expect(notificaciones, 1);
    });

    test('seleccionar el mismo día o un índice inválido no notifica', () {
      vm.seleccionarDia(30);
      vm.seleccionarDia(-1);
      vm.seleccionarDia(100);

      expect(notificaciones, 0);
      expect(vm.diaSeleccionadoIndex, 30);
    });
  });

  group('Comandos', () {
    test(
      'agregarComidaAleatoria suma al día seleccionado y devuelve la comida',
      () {
        vm.seleccionarDia(31); // Jueves futuro arranca limpio en 0
        expect(vm.diaActual.cantidadComidas, 0);
        notificaciones = 0;

        final comida = vm.agregarComidaAleatoria();

        expect(vm.diaActual.comidas.last.id, comida.id);
        expect(vm.diaActual.caloriasActuales, comida.calorias);
        expect(notificaciones, 1);
      },
    );

    test('lo que se suma a un día no afecta a los demás', () {
      vm.seleccionarDia(31);
      vm.agregarComidaAleatoria();

      vm.seleccionarDia(30);
      expect(vm.diaActual.caloriasActuales, 1255);

      vm.seleccionarDia(31);
      expect(vm.diaActual.cantidadComidas, 1);
    });

    test('agregar comidas seguidas genera ids únicos', () {
      for (var i = 0; i < 20; i++) {
        vm.agregarComidaAleatoria();
      }
      final ids = vm.diaActual.comidas.map((c) => c.id).toSet();

      expect(ids.length, vm.diaActual.cantidadComidas);
    });

    test(
      'eliminarComida descuenta y devuelve true; id inexistente devuelve false',
      () {
        final id = vm.diaActual.comidas.first.id;

        expect(vm.eliminarComida(id), isTrue);
        expect(vm.diaActual.caloriasActuales, 924);
        expect(vm.diaActual.caloriasRestantes, 1211);

        notificaciones = 0;
        expect(vm.eliminarComida('no_existe'), isFalse);
        expect(notificaciones, 0);
      },
    );

    test(
      'actualizarComida modifica la comida y recalcula los totales del día',
      () {
        final comidaOriginal = vm.diaActual.comidas.first;
        notificaciones = 0;

        final ingredienteExtra = ComidaIngrediente.manual(
          id: 'ci_nuevo',
          nombre: 'Queso rallado',
          gramos: 20.0,
          calorias: 80,
          proteinas: 6.0,
          carbohidratos: 0.5,
          grasas: 6.0,
        );

        final comidaActualizada = comidaOriginal.conIngredienteAgregado(
          ingredienteExtra,
        );
        final resultado = vm.actualizarComida(comidaActualizada);

        expect(resultado, isTrue);
        expect(notificaciones, 1);
        // El total del día subió por 80 kcal
        expect(vm.diaActual.caloriasActuales, 1255 + 80);
        expect(
          vm.diaActual.comidas.first.ingredientes.contains(ingredienteExtra),
          isTrue,
        );

        // Error con id inexistente
        expect(vm.actualizarComida(_comida('inexistente', 100)), isFalse);
      },
    );

    test('ComidaIngrediente conGramos recalcula proporcionalmente', () {
      final ing = ComidaIngrediente.manual(
        id: 'ci_test',
        nombre: 'Avena',
        gramos: 100.0,
        calorias: 370,
        proteinas: 14.0,
        carbohidratos: 60.0,
        grasas: 7.0,
      );

      // Duplicar porción a 200g
      final ing200 = ing.conGramos(200.0);
      expect(ing200.calorias, 740);
      expect(ing200.proteinas, 28.0);
      expect(ing200.carbohidratos, 120.0);
      expect(ing200.grasas, 14.0);

      // Reducir porción a 50g
      final ing50 = ing.conGramos(50.0);
      expect(ing50.calorias, 185);
      expect(ing50.proteinas, 7.0);
      expect(ing50.carbohidratos, 30.0);
      expect(ing50.grasas, 3.5);
    });
  });

  group('Anillo multicapa', () {
    final base = DiarioViewModel(repository: DiarioRepositoryImpl()).diaActual;

    test('exceso simple activa naranja y deja el rojo en cero', () {
      final dia = base.copyWith(comidas: [_comida('a', 2500)]);

      expect(dia.estaExcedido, isTrue);
      expect(dia.caloriasExtras, 365);
      expect(dia.caloriasRestantes, 0);
      expect(dia.ratioVerde, 1.0);
      expect(dia.ratioNaranja, closeTo(365 / 2135, 0.001));
      expect(dia.ratioRojo, 0.0);
    });

    test('exceso doble activa rojo y completa naranja', () {
      final dia = base.copyWith(comidas: [_comida('a', 4800)]);

      expect(dia.estaExcedidoCritico, isTrue);
      expect(dia.ratioNaranja, 1.0);
      expect(dia.ratioRojo, closeTo((4800 - 4270) / 2135, 0.001));
    });

    test('meta exacta llena el verde sin activar naranja', () {
      final dia = base.copyWith(comidas: [_comida('a', 2135)]);

      expect(dia.ratioVerde, 1.0);
      expect(dia.ratioNaranja, 0.0);
      expect(dia.estaExcedido, isFalse);
    });
  });

  group('Health score', () {
    final base = DiarioViewModel(repository: DiarioRepositoryImpl()).diaActual;

    test('día vacío no inventa un score', () {
      final dia = base.copyWith(comidas: []);

      expect(dia.promedioHealthScore, 0);
      expect(dia.nivelScore, NivelScore.sinRegistros);
    });

    test('los niveles respetan los umbrales', () {
      NivelScore nivel(int score) =>
          base.copyWith(comidas: [_comida('a', 100, score: score)]).nivelScore;

      expect(nivel(85), NivelScore.excelente);
      expect(nivel(84), NivelScore.bueno);
      expect(nivel(70), NivelScore.bueno);
      expect(nivel(69), NivelScore.moderado);
      expect(nivel(50), NivelScore.moderado);
      expect(nivel(49), NivelScore.bajo);
    });
  });
}
