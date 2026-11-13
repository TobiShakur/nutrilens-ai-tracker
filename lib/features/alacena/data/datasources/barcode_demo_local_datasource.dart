import '../../domain/datasources/barcode_demo_datasource.dart';
import '../../domain/entities/barcode_demo_chip.dart';

/// Semilla local aislada con chips de demostración con códigos GS1 válidos.
class BarcodeDemoLocalDatasource implements BarcodeDemoDatasource {
  const BarcodeDemoLocalDatasource();

  @override
  List<BarcodeDemoChip> obtenerChipsDemostracion() => const [
    BarcodeDemoChip(label: 'Nutella', codigo: '3017620422003'),
    BarcodeDemoChip(label: 'Coca-Cola', codigo: '5449000000996'),
    BarcodeDemoChip(label: 'Yogur EAN', codigo: '7791293022611'),
  ];
}
