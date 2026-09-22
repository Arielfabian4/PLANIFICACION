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
      // Guardamos en UTC ISO8601 para que SQLite lo interprete bien
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }

  // Crear desde Map (de SQLite)
  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    DateTime? fecha;

    final raw = map['created_at'];
    if (raw != null) {
      try {
        // SQLite guarda "2026-09-21 19:30:00" en UTC (sin Z).
        // Le añadimos la 'Z' para que Dart sepa que es UTC,
        // y luego lo convertimos a hora local.
        final texto = raw.toString().replaceFirst(' ', 'T');
        fecha = DateTime.parse(
          texto.endsWith('Z') ? texto : '${texto}Z',
        ).toLocal();
      } catch (_) {
        // Si falla el parseo, lo intentamos directo
        try {
          fecha = DateTime.parse(raw.toString());
        } catch (_) {
          fecha = null;
        }
      }
    }

    return Vehiculo(
      idVehiculo: map['id_vehiculo'] as int?,
      modelo: map['modelo'] as String,
      createdAt: fecha,
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
