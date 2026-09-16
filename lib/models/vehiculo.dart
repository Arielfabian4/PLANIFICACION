import 'package:vehiculos_app/models/calculo.dart';

class Vehiculo {
  int? idVehiculo;
  String modelo;
  DateTime? createdAt;
  List<Calculo>? calculos;

  Vehiculo({
    this.idVehiculo,
    required this.modelo,
    this.createdAt,
    this.calculos,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_vehiculo': idVehiculo,
      'modelo': modelo,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Crear desde Map (de SQLite)
  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      idVehiculo: map['id_vehiculo'] as int?,
      modelo: map['modelo'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      calculos: [],
    );
  }

  // Copy con cambios
  Vehiculo copyWith({
    int? idVehiculo,
    String? modelo,
    DateTime? createdAt,
    List<Calculo>? calculos,
  }) {
    return Vehiculo(
      idVehiculo: idVehiculo ?? this.idVehiculo,
      modelo: modelo ?? this.modelo,
      createdAt: createdAt ?? this.createdAt,
      calculos: calculos ?? this.calculos,
    );
  }

  @override
  String toString() {
    return 'Vehiculo{idVehiculo: $idVehiculo, modelo: $modelo, createdAt: $createdAt}';
  }
}
