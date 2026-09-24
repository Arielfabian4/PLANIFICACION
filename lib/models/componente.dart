class Componente {
  int? idComponente;
  int idCalculo;
  String nombre;
  double? reseta;
  double? valorReal;
  String? unidad; // ✅ NUEVO CAMPO
  DateTime? createdAt;

  Componente({
    this.idComponente,
    required this.idCalculo,
    required this.nombre,
    this.reseta,
    this.valorReal,
    this.unidad, // ✅ NUEVO
    this.createdAt,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_componente': idComponente,
      'id_calculo': idCalculo,
      'nombre': nombre,
      'reseta': reseta,
      'valor_real': valorReal,
      'unidad': unidad, // ✅ NUEVO
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Crear desde Map (de SQLite)
  factory Componente.fromMap(Map<String, dynamic> map) {
    return Componente(
      idComponente: map['id_componente'] as int?,
      idCalculo: map['id_calculo'] as int,
      nombre: map['nombre'] as String,
      reseta: (map['reseta'] as num?)?.toDouble(),
      valorReal: (map['valor_real'] as num?)?.toDouble(),
      unidad: map['unidad'] as String?, // ✅ NUEVO
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  // Copy con cambios
  Componente copyWith({
    int? idComponente,
    int? idCalculo,
    String? nombre,
    double? reseta,
    double? valorReal,
    String? unidad, // ✅ NUEVO
    DateTime? createdAt,
  }) {
    return Componente(
      idComponente: idComponente ?? this.idComponente,
      idCalculo: idCalculo ?? this.idCalculo,
      nombre: nombre ?? this.nombre,
      reseta: reseta ?? this.reseta,
      valorReal: valorReal ?? this.valorReal,
      unidad: unidad ?? this.unidad, // ✅ NUEVO
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Componente{idComponente: $idComponente, idCalculo: $idCalculo, '
        'nombre: $nombre, reseta: $reseta, valorReal: $valorReal, '
        'unidad: $unidad, createdAt: $createdAt}';
  }
}
