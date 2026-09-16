class Inventario {
  int? id;
  String nombre;
  double stockActual;

  Inventario({
    this.id,
    required this.nombre,
    required this.stockActual,
  });

  // Convertir a Map para SQLite (si algún día quieres editar directamente)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'stock_actual': stockActual,
    };
  }

  // Crear desde Map (de SQLite)
  factory Inventario.fromMap(Map<String, dynamic> map) {
    return Inventario(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      // Usamos (num).toDouble() porque SQLite a veces devuelve int o double
      stockActual: (map['stock_actual'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Copia con cambios (útil para actualizar estado)
  Inventario copyWith({
    int? id,
    String? nombre,
    double? stockActual,
  }) {
    return Inventario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      stockActual: stockActual ?? this.stockActual,
    );
  }

  @override
  String toString() {
    return 'Inventario(id: $id, nombre: $nombre, stockActual: $stockActual)';
  }
}
