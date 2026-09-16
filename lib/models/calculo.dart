import 'package:vehiculos_app/models/componente.dart';

class Calculo {
  int? idCalculo;
  int idVehiculo;
  String diferencia;
  String? valorReal; // ✅ Corregido: valor_real
  String? medicion; // ✅ Corregido: medicion
  DateTime? createdAt;
  List<Componente>? componentes;

  Calculo({
    this.idCalculo,
    required this.idVehiculo,
    required this.diferencia,
    this.valorReal,
    this.medicion,
    this.createdAt,
    this.componentes,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_calculo': idCalculo,
      'id_vehiculo': idVehiculo,
      'diferencia': diferencia,
      'valor_real': valorReal, // ✅ Corregido
      'medicion': medicion, // ✅ Corregido
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Crear desde Map (de SQLite)
  factory Calculo.fromMap(Map<String, dynamic> map) {
    return Calculo(
      idCalculo: map['id_calculo'] as int?,
      idVehiculo: map['id_vehiculo'] as int,
      diferencia: map['diferencia'] as String,
      valorReal: map['valor_real'] as String?, // ✅ Corregido
      medicion: map['medicion'] as String?, // ✅ Corregido
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      componentes: [],
    );
  }

  // Copy con cambios
  Calculo copyWith({
    int? idCalculo,
    int? idVehiculo,
    String? diferencia,
    String? valorReal, // ✅ Corregido
    String? medicion, // ✅ Corregido
    DateTime? createdAt,
    List<Componente>? componentes,
  }) {
    return Calculo(
      idCalculo: idCalculo ?? this.idCalculo,
      idVehiculo: idVehiculo ?? this.idVehiculo,
      diferencia: diferencia ?? this.diferencia,
      valorReal: valorReal ?? this.valorReal, // ✅ Corregido
      medicion: medicion ?? this.medicion, // ✅ Corregido
      createdAt: createdAt ?? this.createdAt,
      componentes: componentes ?? this.componentes,
    );
  }

  @override
  String toString() {
    return 'Calculo(idCalculo: $idCalculo, idVehiculo: $idVehiculo, diferencia: $diferencia, valorReal: $valorReal, medicion: $medicion, createdAt: $createdAt)';
  }
}
