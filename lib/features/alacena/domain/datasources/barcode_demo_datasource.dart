import '../entities/barcode_demo_chip.dart';

/// Contrato abstracto para proveer chips de demostración de códigos de barras.
abstract class BarcodeDemoDatasource {
  List<BarcodeDemoChip> obtenerChipsDemostracion();
}
