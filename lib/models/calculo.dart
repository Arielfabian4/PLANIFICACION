import 'package:vehiculos_app/models/componente.dart';

class Calculo {
  int? idCalculo;
  int idVehiculo;
  String diferencia;
  String? valorReal;
  String? medicion;
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

  /// ✅ Formatea a "YYYY-MM-DD HH:MM:SS" en UTC
  static String _fechaSqlUtc(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$mi:$s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id_calculo': idCalculo,
      'id_vehiculo': idVehiculo,
      'diferencia': diferencia,
      'valor_real': valorReal,
      'medicion': medicion,
      'created_at': createdAt != null ? _fechaSqlUtc(createdAt!) : null,
    };
  }

  factory Calculo.fromMap(Map<String, dynamic> map) {
    DateTime? fecha;
    final raw = map['created_at'];
    if (raw != null) {
      try {
        final texto = raw.toString().replaceFirst(' ', 'T');
        // ✅ El guardado está en UTC → convertir a local para mostrar
        fecha = DateTime.parse('${texto}Z').toLocal();
      } catch (_) {
        try {
          fecha = DateTime.parse(raw.toString());
        } catch (_) {
          fecha = null;
        }
      }
    }

    return Calculo(
      idCalculo: map['id_calculo'] as int?,
      idVehiculo: map['id_vehiculo'] as int,
      diferencia: map['diferencia'] as String,
      valorReal: map['valor_real'] as String?,
      medicion: map['medicion'] as String?,
      createdAt: fecha,
      componentes: [],
    );
  }

  Calculo copyWith({
    int? idCalculo,
    int? idVehiculo,
    String? diferencia,
    String? valorReal,
    String? medicion,
    DateTime? createdAt,
    List<Componente>? componentes,
  }) {
    return Calculo(
      idCalculo: idCalculo ?? this.idCalculo,
      idVehiculo: idVehiculo ?? this.idVehiculo,
      diferencia: diferencia ?? this.diferencia,
      valorReal: valorReal ?? this.valorReal,
      medicion: medicion ?? this.medicion,
      createdAt: createdAt ?? this.createdAt,
      componentes: componentes ?? this.componentes,
    );
  }

  @override
  String toString() {
    return 'Calculo(idCalculo: $idCalculo, idVehiculo: $idVehiculo, '
        'diferencia: $diferencia, valorReal: $valorReal, '
        'medicion: $medicion, createdAt: $createdAt)';
  }
}
