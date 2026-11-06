import '../../../diario/domain/entities/comida_ingrediente.dart';

/// DTO para serializar y deserializar ingredientes provenientes de la respuesta de la IA.
class ComidaIngredienteModel {
  final String nombre;
  final double gramos;
  final int calorias;
  final double proteinas;
  final double carbos;
  final double grasas;
  final String emoji;

  const ComidaIngredienteModel({
    required this.nombre,
    required this.gramos,
    required this.calorias,
    required this.proteinas,
    required this.carbos,
    required this.grasas,
    required this.emoji,
  });

  factory ComidaIngredienteModel.fromJson(Map<String, dynamic> json) {
    return ComidaIngredienteModel(
      nombre: (json['nombre'] as String?)?.trim() ?? 'Alimento detectado',
      gramos: ((json['gramos'] as num?) ?? 100.0).toDouble().clamp(5.0, 2000.0),
      calorias: ((json['calorias'] as num?) ?? 0).toInt().clamp(0, 5000),
      proteinas: ((json['proteinas'] as num?) ?? 0.0).toDouble().clamp(
        0.0,
        500.0,
      ),
      carbos: ((json['carbos'] as num?) ?? 0.0).toDouble().clamp(0.0, 1000.0),
      grasas: ((json['grasas'] as num?) ?? 0.0).toDouble().clamp(0.0, 500.0),
      emoji: (json['emoji'] as String?)?.trim().isNotEmpty == true
          ? json['emoji'] as String
          : '🥗',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'gramos': gramos,
    'calorias': calorias,
    'proteinas': proteinas,
    'carbos': carbos,
    'grasas': grasas,
    'emoji': emoji,
  };

  ComidaIngrediente toEntity({required String id}) {
    return ComidaIngrediente.manual(
      id: id,
      nombre: nombre,
      emoji: emoji,
      gramos: gramos,
      calorias: calorias,
      proteinas: proteinas,
      carbohidratos: carbos,
      grasas: grasas,
    );
  }
}
