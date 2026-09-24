import 'package:vehiculos_app/models/calculo.dart';

class Vehiculo {
  int? idVehiculo;
  String modelo;
  String? codigo; // 🆔 Identificador único (ej: "G01-001")
  String? lote; // 📦 Nombre del lote al que pertenece

  // ✅ PLANTA DE ENSAMBLE — Ubicación actual
  String? areaActual; // "CHASIS" | "COMPACTOS"
  int? camaraActual; // 1 a 10
  DateTime? fechaIngresoArea; // cuándo entró a la cámara actual
  String? estado; // "EN_PROCESO" | "ENTREGADO"

  DateTime? createdAt;
  List<Calculo>? calculos;

  Vehiculo({
    this.idVehiculo,
    required this.modelo,
    this.codigo,
    this.lote,
    this.areaActual,
    this.camaraActual,
    this.fechaIngresoArea,
    this.estado,
    this.createdAt,
    this.calculos,
  });

  // ✅ Constantes globales de la planta
  static const List<String> areasDisponibles = ['CHASIS', 'COMPACTOS'];
  static const int totalCamaras = 10;
  static const String estadoEnProceso = 'EN_PROCESO';
  static const String estadoEntregado = 'ENTREGADO';

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

  /// ✅ Parsea fecha de SQLite (UTC sin Z) a DateTime local
  static DateTime? _parseFecha(dynamic raw) {
    if (raw == null) return null;
    try {
      final texto = raw.toString().replaceFirst(' ', 'T');
      return DateTime.parse(
        texto.endsWith('Z') ? texto : '${texto}Z',
      ).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return null;
      }
    }
  }

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_vehiculo': idVehiculo,
      'modelo': modelo,
      'codigo': codigo,
      'lote': lote,
      'area_actual': areaActual,
      'camara_actual': camaraActual,
      'fecha_ingreso_area':
          fechaIngresoArea != null ? _fechaSqlUtc(fechaIngresoArea!) : null,
      'estado': estado,
      'created_at': createdAt != null ? _fechaSqlUtc(createdAt!) : null,
    };
  }

  // Crear desde Map (de SQLite)
  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      idVehiculo: map['id_vehiculo'] as int?,
      modelo: map['modelo'] as String,
      codigo: map['codigo'] as String?,
      lote: map['lote'] as String?,
      areaActual: map['area_actual'] as String?,
      camaraActual: map['camara_actual'] as int?,
      fechaIngresoArea: _parseFecha(map['fecha_ingreso_area']),
      estado: (map['estado'] as String?) ?? estadoEnProceso,
      createdAt: _parseFecha(map['created_at']),
      calculos: [],
    );
  }

  // Copy con cambios
  Vehiculo copyWith({
    int? idVehiculo,
    String? modelo,
    String? codigo,
    String? lote,
    String? areaActual,
    int? camaraActual,
    DateTime? fechaIngresoArea,
    String? estado,
    DateTime? createdAt,
    List<Calculo>? calculos,
  }) {
    return Vehiculo(
      idVehiculo: idVehiculo ?? this.idVehiculo,
      modelo: modelo ?? this.modelo,
      codigo: codigo ?? this.codigo,
      lote: lote ?? this.lote,
      areaActual: areaActual ?? this.areaActual,
      camaraActual: camaraActual ?? this.camaraActual,
      fechaIngresoArea: fechaIngresoArea ?? this.fechaIngresoArea,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      calculos: calculos ?? this.calculos,
    );
  }

  /// Código corto para mostrar en UI (ej: "G01-003").
  String get codigoCorto {
    if (codigo == null || codigo!.isEmpty) return 'SIN-COD';
    final partes = codigo!.split('-');
    return partes.length >= 2
        ? partes.sublist(partes.length - 2).join('-')
        : codigo!;
  }

  /// Etiqueta combinada para listados (ej: "G01-003 · SWM G01").
  String get etiqueta {
    final c = codigo;
    if (c == null || c.isEmpty) return modelo;
    return '$c · $modelo';
  }

  /// ✅ Etiqueta legible de la ubicación actual
  /// Ej: "CHASIS · C3" | "ENTREGADO" | "SIN UBICACIÓN"
  String get etiquetaUbicacion {
    if (estado == estadoEntregado) return 'ENTREGADO';
    if (areaActual == null && camaraActual == null) return 'SIN UBICACIÓN';
    final a = areaActual ?? 'SIN ÁREA';
    final c = camaraActual != null ? 'C$camaraActual' : 'SIN CÁMARA';
    return '$a · $c';
  }

  /// ✅ Tiempo que lleva en la cámara actual (ej: "2h 15m", "3d 4h")
  String get tiempoEnCamara {
    if (fechaIngresoArea == null) return '—';
    final diff = DateTime.now().difference(fechaIngresoArea!);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  /// ✅ ¿Está ya entregado?
  bool get estaEntregado => estado == estadoEntregado;

  /// ✅ ¿Tiene ubicación asignada?
  bool get tieneUbicacion => areaActual != null && camaraActual != null;

  @override
  String toString() {
    return 'Vehiculo{idVehiculo: $idVehiculo, modelo: $modelo, '
        'codigo: $codigo, lote: $lote, '
        'areaActual: $areaActual, camaraActual: $camaraActual, '
        'estado: $estado, createdAt: $createdAt}';
  }
}
