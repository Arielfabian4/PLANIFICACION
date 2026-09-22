import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehiculo.dart';
import '../models/calculo.dart';
import '../models/componente.dart';
import '../data/datos_modelos.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vehiculos_app.db');
    debugPrint('📁 BD: $path');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('✅ BD abierta');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔄 Creando tablas...');

    await db.execute('''
      CREATE TABLE vehiculo (
        id_vehiculo INTEGER PRIMARY KEY AUTOINCREMENT,
        modelo TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE calculo (
        id_calculo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_vehiculo INTEGER NOT NULL,
        diferencia TEXT NOT NULL,
        valor_real TEXT,
        medicion TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE componente (
        id_componente INTEGER PRIMARY KEY AUTOINCREMENT,
        id_calculo INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        reseta REAL,
        valor_real REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_calculo) REFERENCES calculo(id_calculo) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        stock_actual REAL DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_componente_calculo ON componente(id_calculo)');
    await db
        .execute('CREATE INDEX idx_calculo_vehiculo ON calculo(id_vehiculo)');
    await db
        .execute('CREATE INDEX idx_inventario_nombre ON inventario(nombre)');

    debugPrint('✅ Tablas creadas');

    await _insertExampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE inventario (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          stock_actual REAL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 3) {
      await _insertExampleData(db);
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE componente ADD COLUMN valor_real REAL');
      debugPrint('✅ Columna valor_real agregada a componente');
    }
  }

  Future<void> _insertExampleData(Database db) async {
    debugPrint('📝 Preparando datos iniciales...');

    final nombresUnicos = await compute(
      _extraerNombresUnicos,
      DatosModelos.datosPorModelo,
    );

    debugPrint('📝 ${nombresUnicos.length} productos únicos');

    final batch = db.batch();
    for (final nombre in nombresUnicos) {
      batch.insert(
        'inventario',
        {'nombre': nombre, 'stock_actual': 10},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);

    debugPrint('✅ Inventario inicial insertado (batch)');

    final existentes = await db.query('vehiculo', limit: 1);
    if (existentes.isNotEmpty) {
      debugPrint('ℹ️ Ya hay vehículos, se omite ejemplo');
      return;
    }

    final vehiculoId =
        await db.insert('vehiculo', {'modelo': 'Toyota Corolla'});

    final calculoId = await db.insert('calculo', {
      'id_vehiculo': vehiculoId,
      'diferencia': '0.5',
      'valor_real': '98.5',
      'medicion': 'Presión (bar)',
    });

    final batchComp = db.batch();
    final comps = [
      {'nombre': 'Motor', 'reseta': 98.5, 'valor_real': 98.5},
      {'nombre': 'Frenos Delanteros', 'reseta': 3.2, 'valor_real': 3.2},
      {'nombre': 'Neumáticos', 'reseta': 32.0, 'valor_real': 32.0},
      {'nombre': 'Batería', 'reseta': 12.6, 'valor_real': 12.6},
    ];
    for (final c in comps) {
      batchComp.insert('componente', {
        'id_calculo': calculoId,
        'nombre': c['nombre'],
        'reseta': c['reseta'],
        'valor_real': c['valor_real'],
      });
    }
    await batchComp.commit(noResult: true);

    debugPrint('✅ Datos de ejemplo insertados');
  }

  // ========== VEHICULO ==========

  Future<int> insertVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.insert('vehiculo', vehiculo.toMap());
  }

  Future<void> insertVehiculosPorLotes(List<String> modelos) async {
    if (modelos.isEmpty) return;

    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final modelo in modelos) {
        batch.insert('vehiculo', {'modelo': modelo});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Vehiculo>> getAllVehiculos() async {
    final db = await database;
    final maps = await db.query('vehiculo', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Vehiculo.fromMap(maps[i]));
  }

  Future<Vehiculo?> getVehiculoById(int id) async {
    final db = await database;
    final maps = await db.query(
      'vehiculo',
      where: 'id_vehiculo = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Vehiculo.fromMap(maps.first);
  }

  Future<int> updateVehiculo(Vehiculo vehiculo) async {
    final db = await database;
    return await db.update(
      'vehiculo',
      vehiculo.toMap(),
      where: 'id_vehiculo = ?',
      whereArgs: [vehiculo.idVehiculo],
    );
  }

  Future<int> deleteVehiculo(int id) async {
    final db = await database;
    return await db.delete(
      'vehiculo',
      where: 'id_vehiculo = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> obtenerConteoPorModelo() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        modelo,
        COUNT(*) AS unidades,
        MAX(created_at) AS ultimo_registro
      FROM vehiculo
      GROUP BY modelo
      ORDER BY unidades DESC, modelo ASC
    ''');
  }

  // ========== CALCULO ==========

  Future<int> insertCalculo(Calculo calculo) async {
    final db = await database;
    return await db.insert('calculo', calculo.toMap());
  }

  Future<int> insertCalculoConComponentes(
    Calculo calculo,
    List<Componente> componentes,
  ) async {
    final db = await database;
    int calculoId = 0;

    await db.transaction((txn) async {
      calculoId = await txn.insert('calculo', calculo.toMap());

      final batch = txn.batch();
      for (var componente in componentes) {
        batch.insert('componente', {
          'id_calculo': calculoId,
          'nombre': componente.nombre,
          'reseta': componente.reseta,
          'valor_real': componente.valorReal,
        });
      }
      await batch.commit(noResult: true);
    });

    return calculoId;
  }

  Future<int> guardarCalculoCompleto(
    Calculo calculo,
    List<Map<String, dynamic>> componentes,
  ) async {
    final db = await database;
    int calculoId = 0;

    await db.transaction((txn) async {
      calculoId = await txn.insert('calculo', calculo.toMap());

      for (var comp in componentes) {
        final nombre = comp['nombre'] as String;
        final reseta = (comp['reseta'] as num?)?.toDouble() ?? 0.0;
        final valorReal = (comp['valor_real'] as num?)?.toDouble();

        await txn.insert('componente', {
          'id_calculo': calculoId,
          'nombre': nombre,
          'reseta': reseta,
          'valor_real': valorReal,
        });

        final cantidadARestar =
            (valorReal != null && valorReal > 0) ? valorReal : reseta;

        await txn.rawUpdate(
          'UPDATE inventario SET stock_actual = MAX(0, stock_actual - ?) WHERE nombre = ?',
          [cantidadARestar, nombre],
        );
      }
    });

    return calculoId;
  }

  Future<List<Calculo>> getCalculosByVehiculo(int idVehiculo) async {
    final db = await database;
    final maps = await db.query(
      'calculo',
      where: 'id_vehiculo = ?',
      whereArgs: [idVehiculo],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Calculo.fromMap(maps[i]));
  }

  Future<Calculo?> getCalculoById(int id) async {
    final db = await database;
    final maps = await db.query(
      'calculo',
      where: 'id_calculo = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Calculo.fromMap(maps.first);
  }

  Future<int> updateCalculo(Calculo calculo) async {
    final db = await database;
    return await db.update(
      'calculo',
      calculo.toMap(),
      where: 'id_calculo = ?',
      whereArgs: [calculo.idCalculo],
    );
  }

  Future<int> deleteCalculo(int id) async {
    final db = await database;
    return await db.delete(
      'calculo',
      where: 'id_calculo = ?',
      whereArgs: [id],
    );
  }

  // ========== COMPONENTE ==========

  Future<int> insertComponente(Componente componente) async {
    final db = await database;
    return await db.insert('componente', componente.toMap());
  }

  Future<List<Componente>> getComponentesByCalculo(int idCalculo) async {
    final db = await database;
    final maps = await db.query(
      'componente',
      where: 'id_calculo = ?',
      whereArgs: [idCalculo],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Componente.fromMap(maps[i]));
  }

  Future<int> updateComponente(Componente componente) async {
    final db = await database;
    return await db.update(
      'componente',
      componente.toMap(),
      where: 'id_componente = ?',
      whereArgs: [componente.idComponente],
    );
  }

  Future<int> deleteComponente(int id) async {
    final db = await database;
    return await db.delete(
      'componente',
      where: 'id_componente = ?',
      whereArgs: [id],
    );
  }

  // ========== CONSULTAS COMBINADAS ==========

  Future<Map<String, dynamic>?> getResumenVehiculo(int idVehiculo) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        v.modelo,
        COUNT(DISTINCT c.id_calculo) as total_calculos,
        COUNT(comp.id_componente) as total_componentes,
        AVG(comp.reseta) as promedio_reseta_general
      FROM vehiculo v
      LEFT JOIN calculo c ON v.id_vehiculo = c.id_vehiculo
      LEFT JOIN componente comp ON c.id_calculo = comp.id_calculo
      WHERE v.id_vehiculo = ?
      GROUP BY v.id_vehiculo
    ''', [idVehiculo]);

    if (result.isEmpty) return null;
    return result.first;
  }

  // ========== INVENTARIO ==========

  Future<List<Map<String, dynamic>>> getInventario() async {
    final db = await database;
    return await db.query('inventario', orderBy: 'nombre ASC');
  }

  Future<void> updateStock(int id, double nuevoStock) async {
    final db = await database;
    await db.update(
      'inventario',
      {'stock_actual': nuevoStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertProductoStock(String nombre, double stockInicial) async {
    final db = await database;
    await db.insert(
      'inventario',
      {
        'nombre': nombre,
        'stock_actual': stockInicial,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, dynamic>?> getStockByNombre(String nombre) async {
    final db = await database;
    final result = await db.query('inventario',
        where: 'nombre = ?', whereArgs: [nombre], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<void> restarStock(String nombre, double cantidad) async {
    final db = await database;

    final rowsAffected = await db.rawUpdate(
      '''
      UPDATE inventario 
      SET stock_actual = MAX(0, stock_actual - ?) 
      WHERE nombre = ?
      ''',
      [cantidad, nombre],
    );

    if (rowsAffected == 0) {
      await db.insert(
        'inventario',
        {'nombre': nombre, 'stock_actual': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ========== CONSUMO ==========

  Future<List<Map<String, dynamic>>> obtenerCalculosConVehiculo() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.id_calculo,
        c.id_vehiculo,
        c.diferencia,
        c.valor_real,
        c.created_at,
        v.modelo AS nombreVehiculo
      FROM calculo c
      INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
      ORDER BY c.created_at DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> obtenerComponentesPorCalculo(
      int idCalculo) async {
    final db = await database;
    return await db.query(
      'componente',
      where: 'id_calculo = ?',
      whereArgs: [idCalculo],
      orderBy: 'nombre ASC',
    );
  }

  Future<List<Map<String, dynamic>>> obtenerConsumoDetalladoPorCalculo(
      int idCalculo) async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT 
        comp.id_componente,
        comp.nombre,
        comp.reseta,
        comp.valor_real,
        inv.stock_actual
      FROM componente comp
      LEFT JOIN inventario inv ON inv.nombre = comp.nombre
      WHERE comp.id_calculo = ?
      ORDER BY comp.nombre ASC
    ''', [idCalculo]);

    if (rows.isEmpty) return [];

    final List<Map<String, dynamic>> resultado = [];

    for (final r in rows) {
      final nombre = r['nombre']?.toString() ?? '';
      final reseta = (r['reseta'] as num?)?.toDouble() ?? 0.0;
      final valorReal = (r['valor_real'] as num?)?.toDouble() ?? 0.0;
      final stock = (r['stock_actual'] as num?)?.toDouble() ?? 0.0;

      final stockRestanteReal = stock - valorReal;
      final stockRestanteTeorico = stock - reseta;

      resultado.add({
        'id_componente': r['id_componente'],
        'nombre': nombre,
        'reseta': reseta,
        'valor_real': valorReal,
        'stock_actual': stock,
        'stock_restante_real': stockRestanteReal < 0 ? 0.0 : stockRestanteReal,
        'stock_restante_teorico':
            stockRestanteTeorico < 0 ? 0.0 : stockRestanteTeorico,
      });
    }

    return resultado;
  }

  // ========== RESUMEN GENERAL ==========

  Future<Map<String, dynamic>> obtenerResumenGeneralConsumo() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS total_componentes,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        COUNT(DISTINCT c.id_vehiculo) AS total_vehiculos
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0
    ''');

    if (result.isEmpty) {
      return {
        'total_real': 0.0,
        'total_teorico': 0.0,
        'total_componentes': 0,
        'total_calculos': 0,
        'total_vehiculos': 0,
      };
    }

    final row = result.first;
    return {
      'total_real': (row['total_real'] as num?)?.toDouble() ?? 0.0,
      'total_teorico': (row['total_teorico'] as num?)?.toDouble() ?? 0.0,
      'total_componentes': (row['total_componentes'] as int?) ?? 0,
      'total_calculos': (row['total_calculos'] as int?) ?? 0,
      'total_vehiculos': (row['total_vehiculos'] as int?) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorComponente() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        comp.nombre,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS veces_usado,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0
      GROUP BY comp.nombre
      ORDER BY total_real DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorVehiculo() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        v.modelo AS nombreVehiculo,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM vehiculo v
      INNER JOIN calculo c ON c.id_vehiculo = v.id_vehiculo
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0
      GROUP BY v.id_vehiculo
      ORDER BY total_real DESC
    ''');
  }

  // ========== FILTRADO POR FECHA ==========

  Future<List<Map<String, dynamic>>> obtenerCalculosConVehiculoPorFecha({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = '';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      final desdeStr = desde.toIso8601String().substring(0, 10);
      final hastaStr = hasta.toIso8601String().substring(0, 10);
      where = "WHERE date(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [desdeStr, hastaStr];
    } else if (desde != null) {
      final desdeStr = desde.toIso8601String().substring(0, 10);
      where = "WHERE date(c.created_at, 'localtime') >= ?";
      args = [desdeStr];
    } else if (hasta != null) {
      final hastaStr = hasta.toIso8601String().substring(0, 10);
      where = "WHERE date(c.created_at, 'localtime') <= ?";
      args = [hastaStr];
    }

    return await db.rawQuery('''
      SELECT 
        c.id_calculo,
        c.id_vehiculo,
        c.diferencia,
        c.valor_real,
        c.created_at,
        v.modelo AS nombreVehiculo
      FROM calculo c
      INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
      $where
      ORDER BY c.created_at DESC
    ''', args);
  }

  Future<Map<String, dynamic>> obtenerResumenGeneralConsumoPorFecha({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND date(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 10),
        hasta.toIso8601String().substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 10)];
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS total_componentes,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        COUNT(DISTINCT c.id_vehiculo) AS total_vehiculos
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      $where
    ''', args);

    if (result.isEmpty) {
      return {
        'total_real': 0.0,
        'total_teorico': 0.0,
        'total_componentes': 0,
        'total_calculos': 0,
        'total_vehiculos': 0,
      };
    }

    final row = result.first;
    return {
      'total_real': (row['total_real'] as num?)?.toDouble() ?? 0.0,
      'total_teorico': (row['total_teorico'] as num?)?.toDouble() ?? 0.0,
      'total_componentes': (row['total_componentes'] as int?) ?? 0,
      'total_calculos': (row['total_calculos'] as int?) ?? 0,
      'total_vehiculos': (row['total_vehiculos'] as int?) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorComponentePorFecha({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND date(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 10),
        hasta.toIso8601String().substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 10)];
    }

    return await db.rawQuery('''
      SELECT 
        comp.nombre,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS veces_usado,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      $where
      GROUP BY comp.nombre
      ORDER BY total_real DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorVehiculoPorFecha({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND date(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 10),
        hasta.toIso8601String().substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 10)];
    }

    return await db.rawQuery('''
      SELECT 
        v.modelo AS nombreVehiculo,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM vehiculo v
      INNER JOIN calculo c ON c.id_vehiculo = v.id_vehiculo
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
      GROUP BY v.id_vehiculo
      ORDER BY total_real DESC
    ''', args);
  }

  // ========== FILTRADO POR FECHA Y HORA ==========

  Future<List<Map<String, dynamic>>> obtenerCalculosConVehiculoPorFechaHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = '';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where = "WHERE datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where = "WHERE datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where = "WHERE datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        c.id_calculo,
        c.id_vehiculo,
        c.diferencia,
        c.valor_real,
        c.created_at,
        v.modelo AS nombreVehiculo
      FROM calculo c
      INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
      $where
      ORDER BY c.created_at DESC
    ''', args);
  }

  Future<Map<String, dynamic>> obtenerResumenGeneralConsumoPorFechaHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS total_componentes,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        COUNT(DISTINCT c.id_vehiculo) AS total_vehiculos
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      $where
    ''', args);

    if (result.isEmpty) {
      return {
        'total_real': 0.0,
        'total_teorico': 0.0,
        'total_componentes': 0,
        'total_calculos': 0,
        'total_vehiculos': 0,
      };
    }

    final row = result.first;
    return {
      'total_real': (row['total_real'] as num?)?.toDouble() ?? 0.0,
      'total_teorico': (row['total_teorico'] as num?)?.toDouble() ?? 0.0,
      'total_componentes': (row['total_componentes'] as int?) ?? 0,
      'total_calculos': (row['total_calculos'] as int?) ?? 0,
      'total_vehiculos': (row['total_vehiculos'] as int?) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorComponentePorFechaHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        comp.nombre,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS veces_usado,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      $where
      GROUP BY comp.nombre
      ORDER BY total_real DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorVehiculoPorFechaHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        v.modelo AS nombreVehiculo,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
      FROM vehiculo v
      INNER JOIN calculo c ON c.id_vehiculo = v.id_vehiculo
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
      GROUP BY v.id_vehiculo
      ORDER BY total_real DESC
    ''', args);
  }

  // ============================================================
  // UNIDADES POR HORA
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerResumenPorHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime')) AS hora,
        COUNT(DISTINCT c.id_calculo) AS calculos,
        COUNT(comp.id_componente) AS total_unidades,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        SUM(CASE WHEN comp.valor_real < comp.reseta THEN 1 ELSE 0 END) AS entradas,
        SUM(CASE WHEN comp.valor_real > comp.reseta THEN 1 ELSE 0 END) AS salidas,
        SUM(CASE WHEN comp.valor_real = comp.reseta THEN 1 ELSE 0 END) AS exactos
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
      GROUP BY strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime'))
      ORDER BY hora DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> obtenerResumenPorHoraConDetalle({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    final resumen = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime')) AS hora,
        COUNT(DISTINCT c.id_calculo) AS calculos,
        COUNT(comp.id_componente) AS total_unidades,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        SUM(CASE WHEN comp.valor_real < comp.reseta THEN 1 ELSE 0 END) AS entradas,
        SUM(CASE WHEN comp.valor_real > comp.reseta THEN 1 ELSE 0 END) AS salidas,
        SUM(CASE WHEN comp.valor_real = comp.reseta THEN 1 ELSE 0 END) AS exactos
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
      GROUP BY strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime'))
      ORDER BY hora DESC
    ''', args);

    final List<Map<String, dynamic>> resultado = [];

    for (final bloque in resumen) {
      final horaRaw = bloque['hora']?.toString() ?? '';
      DateTime? horaInicio;
      try {
        horaInicio = DateTime.parse(horaRaw);
      } catch (_) {
        resultado.add({...bloque, 'vehiculos': []});
        continue;
      }
      final horaFin = horaInicio.add(const Duration(hours: 1));

      final horaInicioStr = horaInicio.toIso8601String().substring(0, 19);
      final horaFinStr = horaFin.toIso8601String().substring(0, 19);

      final detalle = await db.rawQuery('''
        SELECT 
          v.id_vehiculo,
          v.modelo,
          COUNT(DISTINCT c.id_calculo) AS calculos,
          COUNT(comp.id_componente) AS unidades,
          SUM(CASE WHEN comp.valor_real < comp.reseta THEN 1 ELSE 0 END) AS entradas,
          SUM(CASE WHEN comp.valor_real > comp.reseta THEN 1 ELSE 0 END) AS salidas,
          COALESCE(SUM(comp.valor_real), 0) AS total_real,
          COALESCE(SUM(comp.reseta), 0) AS total_teorico
        FROM calculo c
        INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
        INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
        WHERE comp.valor_real IS NOT NULL 
          AND comp.valor_real > 0
          AND datetime(c.created_at, 'localtime') >= ?
          AND datetime(c.created_at, 'localtime') < ?
        GROUP BY v.id_vehiculo, v.modelo
        ORDER BY unidades DESC
      ''', [horaInicioStr, horaFinStr]);

      final List<Map<String, dynamic>> vehiculosConComponentes = [];

      for (final v in detalle) {
        final idVehiculo = v['id_vehiculo'];

        final componentes = await db.rawQuery('''
          SELECT 
            comp.nombre,
            COUNT(comp.id_componente) AS veces_usado,
            COALESCE(SUM(comp.valor_real), 0) AS cantidad_real,
            COALESCE(SUM(comp.reseta), 0) AS cantidad_teorico,
            (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
          FROM calculo c
          INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
          WHERE c.id_vehiculo = ?
            AND comp.valor_real IS NOT NULL 
            AND comp.valor_real > 0
            AND datetime(c.created_at, 'localtime') >= ?
            AND datetime(c.created_at, 'localtime') < ?
          GROUP BY comp.nombre
          ORDER BY cantidad_real DESC
        ''', [idVehiculo, horaInicioStr, horaFinStr]);

        vehiculosConComponentes.add({
          ...v,
          'componentes': componentes,
        });
      }

      resultado.add({
        ...bloque,
        'vehiculos': vehiculosConComponentes,
      });
    }

    return resultado;
  }

  /// ✅ NUEVO: Detalle de componentes usados por hora (sin agrupar por vehículo).
  Future<List<Map<String, dynamic>>> obtenerDetalleComponentesPorHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    // 1) Horas únicas
    final horas = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y-%m-%d %H:00:00',
          datetime(c.created_at, 'localtime')) AS hora
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
      ORDER BY hora DESC
    ''', args);

    final List<Map<String, dynamic>> resultado = [];

    for (final h in horas) {
      final horaRaw = h['hora']?.toString() ?? '';
      DateTime? horaInicio;
      try {
        horaInicio = DateTime.parse(horaRaw);
      } catch (_) {
        continue;
      }
      final horaFin = horaInicio.add(const Duration(hours: 1));

      final horaInicioStr = horaInicio.toIso8601String().substring(0, 19);
      final horaFinStr = horaFin.toIso8601String().substring(0, 19);

      // 2) Componentes usados en esa hora
      final componentes = await db.rawQuery('''
        SELECT 
          comp.nombre,
          COUNT(comp.id_componente) AS veces,
          COALESCE(SUM(comp.valor_real), 0) AS total_real,
          COALESCE(SUM(comp.reseta), 0) AS total_teorico,
          (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia,
          SUM(CASE WHEN comp.valor_real < comp.reseta THEN 1 ELSE 0 END) AS entradas,
          SUM(CASE WHEN comp.valor_real > comp.reseta THEN 1 ELSE 0 END) AS salidas,
          SUM(CASE WHEN comp.valor_real = comp.reseta THEN 1 ELSE 0 END) AS exactos
        FROM calculo c
        INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
        WHERE comp.valor_real IS NOT NULL 
          AND comp.valor_real > 0
          AND datetime(c.created_at, 'localtime') >= ?
          AND datetime(c.created_at, 'localtime') < ?
        GROUP BY comp.nombre
        ORDER BY total_real DESC
      ''', [horaInicioStr, horaFinStr]);

      // 3) Vehículos de esa hora
      final vehiculos = await db.rawQuery('''
        SELECT DISTINCT v.modelo
        FROM calculo c
        INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
        INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
        WHERE comp.valor_real IS NOT NULL 
          AND comp.valor_real > 0
          AND datetime(c.created_at, 'localtime') >= ?
          AND datetime(c.created_at, 'localtime') < ?
        ORDER BY v.modelo
      ''', [horaInicioStr, horaFinStr]);

      resultado.add({
        'hora': horaRaw,
        'vehiculos': vehiculos.map((e) => e['modelo'].toString()).toList(),
        'componentes': componentes,
      });
    }

    return resultado;
  }

  Future<List<Map<String, dynamic>>> obtenerEntradasPorHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime')) AS hora,
        COUNT(comp.id_componente) AS unidades_entrada,
        COUNT(DISTINCT c.id_calculo) AS calculos,
        COALESCE(SUM(comp.reseta - comp.valor_real), 0) AS total_entrada
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
        AND comp.reseta > comp.valor_real
      GROUP BY strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime'))
      ORDER BY hora DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> obtenerSalidasPorHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime')) AS hora,
        COUNT(comp.id_componente) AS unidades_salida,
        COUNT(DISTINCT c.id_calculo) AS calculos,
        COALESCE(SUM(comp.valor_real - comp.reseta), 0) AS total_salida
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
        AND comp.reseta < comp.valor_real
      GROUP BY strftime('%Y-%m-%d %H:00:00', datetime(c.created_at, 'localtime'))
      ORDER BY hora DESC
    ''', args);
  }

  Future<Map<String, dynamic>> obtenerResumenDelDia({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        desde.toIso8601String().substring(0, 19),
        hasta.toIso8601String().substring(0, 19),
      ];
    } else if (desde != null) {
      where += " AND datetime(c.created_at, 'localtime') >= ?";
      args = [desde.toIso8601String().substring(0, 19)];
    } else if (hasta != null) {
      where += " AND datetime(c.created_at, 'localtime') <= ?";
      args = [hasta.toIso8601String().substring(0, 19)];
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT c.id_calculo) AS total_calculos,
        COUNT(comp.id_componente) AS total_unidades,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        SUM(CASE WHEN comp.valor_real < comp.reseta THEN 1 ELSE 0 END) AS total_entradas,
        SUM(CASE WHEN comp.valor_real > comp.reseta THEN 1 ELSE 0 END) AS total_salidas,
        SUM(CASE WHEN comp.valor_real = comp.reseta THEN 1 ELSE 0 END) AS total_exactos
      FROM calculo c
      INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
      $where
    ''', args);

    if (result.isEmpty) {
      return {
        'total_calculos': 0,
        'total_unidades': 0,
        'total_real': 0.0,
        'total_teorico': 0.0,
        'total_entradas': 0,
        'total_salidas': 0,
        'total_exactos': 0,
      };
    }

    final row = result.first;
    return {
      'total_calculos': (row['total_calculos'] as int?) ?? 0,
      'total_unidades': (row['total_unidades'] as int?) ?? 0,
      'total_real': (row['total_real'] as num?)?.toDouble() ?? 0.0,
      'total_teorico': (row['total_teorico'] as num?)?.toDouble() ?? 0.0,
      'total_entradas': (row['total_entradas'] as int?) ?? 0,
      'total_salidas': (row['total_salidas'] as int?) ?? 0,
      'total_exactos': (row['total_exactos'] as int?) ?? 0,
    };
  }

  // ============================================================
  // DEBUG
  // ============================================================

  Future<void> debugUltimosComponentes() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT comp.*, c.created_at 
      FROM componente comp
      INNER JOIN calculo c ON c.id_calculo = comp.id_calculo
      ORDER BY comp.id_componente DESC
      LIMIT 10
    ''');

    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔍 ÚLTIMOS 10 COMPONENTES GUARDADOS:');
    for (final row in rows) {
      debugPrint('   ${row['nombre']}:');
      debugPrint(
          '      reseta: ${row['reseta']} (${row['reseta'].runtimeType})');
      debugPrint(
          '      valor_real: ${row['valor_real']} (${row['valor_real'].runtimeType})');
      debugPrint('      created_at: ${row['created_at']}');
    }
    debugPrint('═══════════════════════════════════════════');
  }
}

/// Corre en Isolate separado: extrae nombres únicos sin bloquear UI.
List<String> _extraerNombresUnicos(
  Map<String, List<Map<String, dynamic>>> datos,
) {
  final set = <String>{};
  for (final modelo in datos.values) {
    for (final componente in modelo) {
      final nombre = componente['nombre'];
      if (nombre is String) set.add(nombre);
    }
  }
  return set.toList();
}
