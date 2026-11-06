import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens_provider/features/alacena/data/repositories/alacena_repository_impl.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/categoria_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/entities/ingrediente_alacena.dart';
import 'package:nutrilens_provider/features/alacena/domain/results/alacena_result.dart';
import 'package:nutrilens_provider/features/alacena/presentation/viewmodels/alacena_viewmodel.dart';

void main() {
  group('AlacenaViewModel & Entidades', () {
    late AlacenaRepositoryImpl repository;
    late AlacenaViewModel vm;

    setUp(() async {
      repository = AlacenaRepositoryImpl();
      vm = AlacenaViewModel(repository: repository);
      await Future<void>.delayed(Duration.zero);
    });

    test('Estado inicial carga los 7 ingredientes de la semilla', () {
      expect(vm.totalIngredientes, 7);
      expect(vm.ingredientesFiltrados.length, 7);
      expect(vm.categoriaSeleccionada, CategoriaAlacena.todos);
      expect(vm.busquedaQuery, isEmpty);
      expect(vm.cargando, isFalse);
    });

    test('Filtro por categoría acota la lista y notifica', () {
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      vm.seleccionarCategoria(CategoriaAlacena.proteinas);

      expect(vm.categoriaSeleccionada, CategoriaAlacena.proteinas);
      expect(notificaciones, 1);
      // Huevos y Pollo
      expect(vm.ingredientesFiltrados.length, 2);
      expect(
        vm.ingredientesFiltrados.every(
          (i) => i.categoria == CategoriaAlacena.proteinas,
        ),
        isTrue,
      );

      // Si selecciono la misma, no re-notifica
      vm.seleccionarCategoria(CategoriaAlacena.proteinas);
      expect(notificaciones, 1);
    });

    test('Búsqueda por nombre o marca filtra en tiempo real', () {
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      // Buscar por marca
      vm.actualizarBusqueda('fargo');
      expect(notificaciones, 1);
      expect(vm.ingredientesFiltrados.length, 1);
      expect(vm.ingredientesFiltrados.first.nombre, 'Pan integral 100%');

      // Buscar por nombre
      vm.actualizarBusqueda('palta');
      expect(vm.ingredientesFiltrados.length, 1);
      expect(vm.ingredientesFiltrados.first.nombre, 'Palta Hass');

      // Limpiar búsqueda
      vm.actualizarBusqueda('');
      expect(vm.ingredientesFiltrados.length, 7);
    });

    test(
      'crearIngrediente agrega alimento válido con porción variable y devuelve AlacenaExito',
      () async {
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        final resultado = await vm.crearIngrediente(
          nombre: 'Yogur Griego',
          marca: 'La Serenísima',
          categoria: CategoriaAlacena.lacteos,
          gramosPorcion: 150.0,
          calorias: 120,
          proteinas: 12.0,
          carbohidratos: 6.0,
          grasas: 4.0,
        );

        expect(resultado, isA<AlacenaExito<IngredienteAlacena>>());
        final item = (resultado as AlacenaExito<IngredienteAlacena>).datos;
        expect(item.nombreConMarca, 'Yogur Griego (La Serenísima)');
        expect(item.porcionLabel, '150g');
        expect(vm.totalIngredientes, 8);
        expect(vm.ingredientesFiltrados.first.nombre, 'Yogur Griego');
        expect(notificaciones, 1);
      },
    );

    test('editarIngrediente modifica datos existentes y notifica', () async {
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      // Tomamos el primer ingrediente ('ing_1', Huevos de campo)
      final idAEditar = vm.ingredientesFiltrados.first.id;
      final resultado = await vm.editarIngrediente(
        id: idAEditar,
        nombre: 'Huevos pastoriles',
        marca: 'Coeco',
        categoria: CategoriaAlacena.proteinas,
        gramosPorcion: 120.0,
        calorias: 180,
        proteinas: 16.0,
        carbohidratos: 1.5,
        grasas: 12.0,
      );

      expect(resultado, isA<AlacenaExito<IngredienteAlacena>>());
      final actualizado = (resultado as AlacenaExito<IngredienteAlacena>).datos;
      expect(actualizado.nombre, 'Huevos pastoriles');
      expect(actualizado.marca, 'Coeco');
      expect(actualizado.gramosPorcion, 120.0);
      expect(actualizado.calorias, 180);
      expect(notificaciones, 1);

      // Verificamos que se actualizó en la lista del ViewModel
      final encontrado = vm.ingredientesFiltrados.firstWhere(
        (i) => i.id == idAEditar,
      );
      expect(encontrado.nombre, 'Huevos pastoriles');
      expect(encontrado.marca, 'Coeco');

      // Error al editar un id inexistente
      final resInexistente = await vm.editarIngrediente(
        id: 'no_existe_id',
        nombre: 'Alimento Fake',
        categoria: CategoriaAlacena.otros,
        calorias: 100,
        proteinas: 10,
        carbohidratos: 10,
        grasas: 5,
      );
      expect(resInexistente, isA<AlacenaFallo<IngredienteAlacena>>());

      // Error con nombre vacío o porción inválida
      final resInvalido = await vm.editarIngrediente(
        id: idAEditar,
        nombre: '   ',
        categoria: CategoriaAlacena.proteinas,
        gramosPorcion: -10,
        calorias: 100,
        proteinas: 10,
        carbohidratos: 10,
        grasas: 5,
      );
      expect(resInvalido, isA<AlacenaFallo<IngredienteAlacena>>());
    });

    test('agregarCategoria suma categoría personalizada y la selecciona', () {
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final cat = vm.agregarCategoria('Suplementos', '💊');
      expect(cat.label, 'Suplementos');
      expect(cat.emoji, '💊');
      expect(vm.categorias.contains(cat), isTrue);
      expect(vm.categoriaSeleccionada, cat);
      expect(notificaciones, 1);
    });

    test(
      'editarCategoria actualiza nombre, emoji e ingredientes asociados',
      () {
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        final editado = vm.editarCategoria(
          'proteinas',
          nuevoNombre: 'Proteínas Puras',
          nuevoEmoji: '🍗',
        );

        expect(editado, isTrue);
        final catActualizada = vm.categorias.firstWhere(
          (c) => c.id == 'proteinas',
        );
        expect(catActualizada.label, 'Proteínas Puras');
        expect(catActualizada.emoji, '🍗');
        // Los ingredientes con proteinas ahora tienen la categoría actualizada
        expect(
          vm.ingredientesFiltrados
              .where((i) => i.id == 'ing_1')
              .first
              .categoria
              .label,
          'Proteínas Puras',
        );
        expect(notificaciones, 1);

        // Editar categoría "todos" o inexistente no se permite
        expect(
          vm.editarCategoria('todos', nuevoNombre: 'X', nuevoEmoji: 'Y'),
          isFalse,
        );
        expect(
          vm.editarCategoria('no_existe', nuevoNombre: 'X', nuevoEmoji: 'Y'),
          isFalse,
        );
      },
    );

    test(
      'eliminarCategoria quita la categoría y reasigna ingredientes a Otros',
      () {
        var notificaciones = 0;
        vm.addListener(() => notificaciones++);

        // Agregamos una categoría y creamos un ingrediente en ella
        final cat = vm.agregarCategoria('Snacks', '🍿');
        expect(vm.categorias.contains(cat), isTrue);

        final eliminada = vm.eliminarCategoria(cat.id);
        expect(eliminada, isTrue);
        expect(vm.categorias.contains(cat), isFalse);
        expect(vm.categoriaSeleccionada, CategoriaAlacena.todos);

        // Eliminar categoría protegida "todos" falla
        expect(vm.eliminarCategoria('todos'), isFalse);
      },
    );

    test(
      'crearIngrediente rechaza campos inválidos con AlacenaFallo',
      () async {
        // Nombre vacío
        final resVacio = await vm.crearIngrediente(
          nombre: '   ',
          categoria: CategoriaAlacena.proteinas,
          calorias: 100,
          proteinas: 10,
          carbohidratos: 0,
          grasas: 2,
        );
        expect(resVacio, isA<AlacenaFallo<IngredienteAlacena>>());

        // Categoría "todos" no es válida para un alimento individual
        final resTodos = await vm.crearIngrediente(
          nombre: 'Test',
          categoria: CategoriaAlacena.todos,
          calorias: 100,
          proteinas: 10,
          carbohidratos: 0,
          grasas: 2,
        );
        expect(resTodos, isA<AlacenaFallo<IngredienteAlacena>>());

        // Porción menor o igual a cero
        final resPorcion = await vm.crearIngrediente(
          nombre: 'Test',
          categoria: CategoriaAlacena.proteinas,
          gramosPorcion: 0,
          calorias: 100,
          proteinas: 10,
          carbohidratos: 0,
          grasas: 2,
        );
        expect(resPorcion, isA<AlacenaFallo<IngredienteAlacena>>());

        // Calorías negativas
        final resCalNeg = await vm.crearIngrediente(
          nombre: 'Test',
          categoria: CategoriaAlacena.proteinas,
          calorias: -50,
          proteinas: 10,
          carbohidratos: 0,
          grasas: 2,
        );
        expect(resCalNeg, isA<AlacenaFallo<IngredienteAlacena>>());
      },
    );

    test('borrarIngrediente elimina de memoria y notifica', () async {
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final idABorrar = vm.ingredientesFiltrados.first.id;
      final resultado = await vm.borrarIngrediente(idABorrar);

      expect(resultado, isA<AlacenaExito<void>>());
      expect(vm.totalIngredientes, 6);
      expect(vm.ingredientesFiltrados.any((i) => i.id == idABorrar), isFalse);
      expect(notificaciones, 1);

      // Borrar id inexistente devuelve fallo
      final resInexistente = await vm.borrarIngrediente('no_existe');
      expect(resInexistente, isA<AlacenaFallo<void>>());
    });

    test(
      'Cálculos de proporciones de IngredienteAlacena con porción variable',
      () {
        final ing = IngredienteAlacena(
          id: 'test',
          nombre: 'Galletitas de avena',
          marca: 'Quáker',
          categoria: CategoriaAlacena.carbohidratos,
          gramosPorcion: 30.0, // 3 galletitas
          calorias: 130,
          proteinas: 2.0,
          carbohidratos: 20.0,
          grasas: 5.0,
          creadoEn: DateTime.now(),
        );

        // Para los 30 gramos (la porción del paquete)
        expect(ing.calcularCalorias(30), 130);
        expect(ing.calcularProteinas(30), 2.0);

        // Para el doble (60 gramos)
        expect(ing.calcularCalorias(60), 260);
        expect(ing.calcularProteinas(60), 4.0);
        expect(ing.calcularCarbos(60), 40.0);

        // Normalizado a 100g
        expect(ing.caloriasPor100g, 433);

        // 0 o negativo
        expect(ing.calcularCalorias(0), 0);
        expect(ing.calcularCalorias(-20), 0);
        expect(ing.calcularProteinas(-5), 0.0);
      },
    );
  });
}
