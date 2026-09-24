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
      version: 10, // ⬆️ v10: planta de ensamble (áreas + cámaras)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('✅ BD abierta');
      },
    );
  }

  /// ✅ Formatea una fecha al estilo SQLite: "YYYY-MM-DD HH:MM:SS"
  /// en hora LOCAL (para mostrar en pantalla, para debug, etc.)
  String _fechaSql(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$mi:$s';
  }

  /// ✅ Convierte una fecha LOCAL a UTC y la formatea como
  /// "YYYY-MM-DD HH:MM:SS" para comparar con `created_at` (que está en UTC).
  String _fechaSqlUtc(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$mi:$s';
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔄 Creando tablas...');

    await db.execute('''
      CREATE TABLE vehiculo (
        id_vehiculo INTEGER PRIMARY KEY AUTOINCREMENT,
        modelo TEXT NOT NULL,
        codigo TEXT,
        lote TEXT,
        area_actual TEXT,
        camara_actual INTEGER,
        fecha_ingreso_area TEXT,
        estado TEXT DEFAULT 'EN_PROCESO',
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
        unidad TEXT DEFAULT 'LT',
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

    // ✅ NUEVA TABLA: histórico de movimientos entre cámaras
    await db.execute('''
      CREATE TABLE movimiento_camara (
        id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
        id_vehiculo INTEGER NOT NULL,
        area TEXT NOT NULL,
        camara INTEGER NOT NULL,
        estado TEXT DEFAULT 'EN_PROCESO',
        notas TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_componente_calculo ON componente(id_calculo)');
    await db
        .execute('CREATE INDEX idx_calculo_vehiculo ON calculo(id_vehiculo)');
    await db
        .execute('CREATE INDEX idx_inventario_nombre ON inventario(nombre)');
    await db.execute('CREATE INDEX idx_vehiculo_codigo ON vehiculo(codigo)');
    await db.execute('CREATE INDEX idx_vehiculo_lote ON vehiculo(lote)');
    await db.execute('CREATE INDEX idx_calculo_created ON calculo(created_at)');
    await db.execute(
        'CREATE INDEX idx_mov_vehiculo ON movimiento_camara(id_vehiculo)');
    await db.execute(
        'CREATE INDEX idx_mov_area_camara ON movimiento_camara(area, camara)');
    await db
        .execute('CREATE INDEX idx_mov_fecha ON movimiento_camara(created_at)');
    await db.execute(
        'CREATE INDEX idx_vehiculo_ubicacion ON vehiculo(area_actual, camara_actual)');

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

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE vehiculo ADD COLUMN codigo TEXT');
        await db
            .execute('CREATE INDEX idx_vehiculo_codigo ON vehiculo(codigo)');
        debugPrint('✅ Columna codigo agregada a vehiculo');
      } catch (e) {
        debugPrint('⚠️ codigo ya existía o error: $e');
      }

      await _backfillCodigos(db);
    }

    if (oldVersion < 6) {
      try {
        await db.execute(
          "ALTER TABLE componente ADD COLUMN unidad TEXT DEFAULT 'LT'",
        );
        debugPrint('✅ Columna unidad agregada a componente');
      } catch (e) {
        debugPrint('⚠️ unidad ya existía o error: $e');
      }

      await _backfillUnidades(db);
    }

    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE vehiculo ADD COLUMN lote TEXT');
        await db.execute('CREATE INDEX idx_vehiculo_lote ON vehiculo(lote)');
        debugPrint('✅ Columna lote agregada a vehiculo');
      } catch (e) {
        debugPrint('⚠️ lote ya existía o error: $e');
      }
    }

    // v8: Normalizar fechas (quitar "T" y milisegundos)
    if (oldVersion < 8) {
      debugPrint('🔄 Normalizando fechas (v8)...');

      try {
        final c1 = await db.rawUpdate('''
          UPDATE calculo
          SET created_at = REPLACE(SUBSTR(created_at, 1, 19), 'T', ' ')
          WHERE created_at LIKE '%T%'
        ''');
        debugPrint('   ✅ calculo: $c1 filas');

        final c2 = await db.rawUpdate('''
          UPDATE componente
          SET created_at = REPLACE(SUBSTR(created_at, 1, 19), 'T', ' ')
          WHERE created_at LIKE '%T%'
        ''');
        debugPrint('   ✅ componente: $c2 filas');

        final c3 = await db.rawUpdate('''
          UPDATE vehiculo
          SET created_at = REPLACE(SUBSTR(created_at, 1, 19), 'T', ' ')
          WHERE created_at LIKE '%T%'
        ''');
        debugPrint('   ✅ vehiculo: $c3 filas');

        try {
          await db.execute(
              'CREATE INDEX idx_calculo_created ON calculo(created_at)');
          debugPrint('   ✅ Índice idx_calculo_created creado');
        } catch (e) {
          debugPrint('   ℹ️ Índice ya existía');
        }

        debugPrint('✅ v8: Fechas normalizadas');
      } catch (e) {
        debugPrint('⚠️ Error normalizando fechas: $e');
      }
    }

    // ✅ v9: Convertir fechas existentes de hora local → UTC
    if (oldVersion < 9) {
      debugPrint('🔄 v9: Convirtiendo fechas a UTC...');

      final offset = DateTime.now().timeZoneOffset;
      final minutos = -offset.inMinutes;
      final modificador =
          minutos >= 0 ? "+$minutos minutes" : "-${minutos.abs()} minutes";

      debugPrint('   Offset dispositivo: $offset');
      debugPrint('   Modificador SQL:    $modificador');

      try {
        final c1 = await db.rawUpdate('''
          UPDATE calculo
          SET created_at = datetime(created_at, ?)
          WHERE created_at IS NOT NULL AND LENGTH(created_at) >= 19
        ''', [modificador]);
        debugPrint('   ✅ calculo: $c1 filas');

        final c2 = await db.rawUpdate('''
          UPDATE componente
          SET created_at = datetime(created_at, ?)
          WHERE created_at IS NOT NULL AND LENGTH(created_at) >= 19
        ''', [modificador]);
        debugPrint('   ✅ componente: $c2 filas');

        final c3 = await db.rawUpdate('''
          UPDATE vehiculo
          SET created_at = datetime(created_at, ?)
          WHERE created_at IS NOT NULL AND LENGTH(created_at) >= 19
        ''', [modificador]);
        debugPrint('   ✅ vehiculo: $c3 filas');

        debugPrint('✅ v9: Fechas convertidas a UTC');
      } catch (e) {
        debugPrint('⚠️ Error convirtiendo fechas: $e');
      }
    }

    // ✅ v10: Planta de ensamble — áreas y cámaras
    if (oldVersion < 10) {
      debugPrint('🔄 v10: Planta de ensamble...');

      try {
        await db.execute('ALTER TABLE vehiculo ADD COLUMN area_actual TEXT');
        debugPrint('   ✅ area_actual');
      } catch (e) {
        debugPrint('   ⚠️ area_actual: $e');
      }

      try {
        await db
            .execute('ALTER TABLE vehiculo ADD COLUMN camara_actual INTEGER');
        debugPrint('   ✅ camara_actual');
      } catch (e) {
        debugPrint('   ⚠️ camara_actual: $e');
      }

      try {
        await db
            .execute('ALTER TABLE vehiculo ADD COLUMN fecha_ingreso_area TEXT');
        debugPrint('   ✅ fecha_ingreso_area');
      } catch (e) {
        debugPrint('   ⚠️ fecha_ingreso_area: $e');
      }

      try {
        await db.execute(
            "ALTER TABLE vehiculo ADD COLUMN estado TEXT DEFAULT 'EN_PROCESO'");
        debugPrint('   ✅ estado');
      } catch (e) {
        debugPrint('   ⚠️ estado: $e');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS movimiento_camara (
          id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
          id_vehiculo INTEGER NOT NULL,
          area TEXT NOT NULL,
          camara INTEGER NOT NULL,
          estado TEXT DEFAULT 'EN_PROCESO',
          notas TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo) ON DELETE CASCADE
        )
      ''');

      try {
        await db.execute(
            'CREATE INDEX idx_mov_vehiculo ON movimiento_camara(id_vehiculo)');
        await db.execute(
            'CREATE INDEX idx_mov_area_camara ON movimiento_camara(area, camara)');
        await db.execute(
            'CREATE INDEX idx_mov_fecha ON movimiento_camara(created_at)');
        await db.execute(
            'CREATE INDEX idx_vehiculo_ubicacion ON vehiculo(area_actual, camara_actual)');
      } catch (_) {}

      debugPrint('✅ v10: Planta de ensamble lista');
    }
  }

  Future<void> _backfillCodigos(Database db) async {
    final rows = await db.query(
      'vehiculo',
      columns: ['id_vehiculo', 'modelo', 'codigo'],
      where: 'codigo IS NULL OR codigo = ?',
      whereArgs: [''],
      orderBy: 'id_vehiculo ASC',
    );

    if (rows.isEmpty) return;

    final Map<String, int> contador = {};
    final batch = db.batch();

    for (final r in rows) {
      final id = r['id_vehiculo'] as int;
      final modelo = (r['modelo'] ?? '').toString();
      final prefijo = _prefijoModelo(modelo);
      final n = (contador[prefijo] ?? 0) + 1;
      contador[prefijo] = n;
      final codigo = '$prefijo-${n.toString().padLeft(3, '0')}';
      batch.update(
        'vehiculo',
        {'codigo': codigo},
        where: 'id_vehiculo = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
    debugPrint('✅ Backfill de códigos completado (${rows.length})');
  }

  Future<void> _backfillUnidades(Database db) async {
    final Map<String, String> unidadPorNombre = {};
    for (final modelo in DatosModelos.datosPorModelo.values) {
      for (final comp in modelo) {
        final nombre = comp['nombre'] as String?;
        final unidad = comp['unidad']?.toString() ?? comp['medida']?.toString();
        if (nombre != null && unidad != null) {
          unidadPorNombre[nombre] = _normalizarUnidad(unidad);
        }
      }
    }

    if (unidadPorNombre.isEmpty) return;

    final rows = await db.query(
      'componente',
      columns: ['id_componente', 'nombre', 'unidad'],
      where: 'unidad IS NULL OR unidad = ?',
      whereArgs: [''],
    );

    if (rows.isEmpty) return;

    final batch = db.batch();
    for (final r in rows) {
      final id = r['id_componente'] as int;
      final nombre = (r['nombre'] ?? '').toString();
      final unidad = unidadPorNombre[nombre] ?? 'LT';
      batch.update(
        'componente',
        {'unidad': unidad},
        where: 'id_componente = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
    debugPrint('✅ Backfill de unidades completado (${rows.length})');
  }

  String _normalizarUnidad(String? unidad) {
    if (unidad == null || unidad.trim().isEmpty) return 'LT';
    final u = unidad.trim().toUpperCase();
    switch (u) {
      case 'LY':
      case 'LT':
      case 'L':
      case 'LTS':
      case 'LITRO':
      case 'LITROS':
        return 'LT';
      case 'ML':
      case 'MLS':
        return 'ML';
      case 'GL':
      case 'GAL':
      case 'GALON':
      case 'GALONES':
        return 'GL';
      case 'GR':
      case 'GRS':
      case 'GRAMO':
      case 'GRAMOS':
        return 'GR';
      case 'KG':
      case 'KGS':
      case 'KILO':
      case 'KILOS':
        return 'KG';
      case 'MT':
      case 'M':
      case 'MTS':
      case 'METRO':
      case 'METROS':
        return 'MT';
      case 'UND':
      case 'UN':
      case 'U':
      case 'UNIDAD':
      case 'UNIDADES':
        return 'UND';
      case 'QT':
      case 'QTS':
        return 'QT';
      case 'OZ':
        return 'OZ';
      default:
        return u.isEmpty ? 'LT' : u;
    }
  }

  String _prefijoModelo(String modelo) {
    final limpio = modelo.trim().toUpperCase();
    if (limpio.isEmpty) return 'VEH';

    final partes = limpio.split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      final seg = partes[1].replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (seg.isNotEmpty) {
        return seg.substring(0, seg.length.clamp(0, 4));
      }
    }
    final soloAlfa = limpio.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (soloAlfa.isEmpty) return 'VEH';
    return soloAlfa.substring(0, soloAlfa.length.clamp(0, 4));
  }

  /// ✅ Convierte el nombre de un lote a un prefijo seguro para el código.
  /// Ej: "Lote Enero 2026" → "LOTEENERO2026" (máx. 12 chars)
  String _prefijoLote(String? lote) {
    if (lote == null || lote.trim().isEmpty) return '';
    final limpio =
        lote.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (limpio.isEmpty) return '';
    return limpio.length > 12 ? limpio.substring(0, 12) : limpio;
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

    final vehiculoId = await db.insert('vehiculo', {
      'modelo': 'Toyota Corolla',
      'codigo': 'CORO-001',
      'lote': 'Lote Demo',
    });

    final calculoId = await db.insert('calculo', {
      'id_vehiculo': vehiculoId,
      'diferencia': '0.5',
      'valor_real': '98.5',
      'medicion': 'Presión (bar)',
    });

    final batchComp = db.batch();
    final comps = [
      {'nombre': 'Motor', 'reseta': 98.5, 'valor_real': 98.5, 'unidad': 'LT'},
      {
        'nombre': 'Frenos Delanteros',
        'reseta': 3.2,
        'valor_real': 3.2,
        'unidad': 'LT'
      },
      {
        'nombre': 'Neumáticos',
        'reseta': 32.0,
        'valor_real': 32.0,
        'unidad': 'UND'
      },
      {
        'nombre': 'Batería',
        'reseta': 12.6,
        'valor_real': 12.6,
        'unidad': 'UND'
      },
    ];
    for (final c in comps) {
      batchComp.insert('componente', {
        'id_calculo': calculoId,
        'nombre': c['nombre'],
        'reseta': c['reseta'],
        'valor_real': c['valor_real'],
        'unidad': c['unidad'],
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
      final Map<String, int> contador = {};

      final existentes = await txn.query('vehiculo', columns: ['codigo']);
      final regex = RegExp(r'^([A-Z0-9]+)-(\d+)$');
      for (final e in existentes) {
        final cod = (e['codigo'] ?? '').toString();
        final m = regex.firstMatch(cod);
        if (m != null) {
          final prefijo = m.group(1)!;
          final n = int.tryParse(m.group(2)!) ?? 0;
          if ((contador[prefijo] ?? 0) < n) contador[prefijo] = n;
        }
      }

      final batch = txn.batch();
      for (final modelo in modelos) {
        final prefijo = _prefijoModelo(modelo);
        final n = (contador[prefijo] ?? 0) + 1;
        contador[prefijo] = n;
        final codigo = '$prefijo-${n.toString().padLeft(3, '0')}';

        batch.insert('vehiculo', {
          'modelo': modelo,
          'codigo': codigo,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertVehiculosConCodigo(List<Map<String, String>> items) async {
    if (items.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert('vehiculo', {
          'modelo': item['modelo'],
          'codigo': item['codigo'],
          'lote': item['lote'],
        });
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

  // ============================================================
  // 🔢 GENERACIÓN DE CÓDIGOS (por modelo + lote)
  // ============================================================

  /// Genera el siguiente código para un modelo.
  /// Si se pasa [lote], el código se prefija con el nombre del lote
  /// y solo considera vehículos del mismo lote.
  ///
  /// Ejemplos:
  ///   generarSiguienteCodigo('SWM G01')                 → "G01-005"
  ///   generarSiguienteCodigo('SWM G01', lote: 'Lote 60') → "LOTE60-031"
  Future<String> generarSiguienteCodigo(String modelo, {String? lote}) async {
    final db = await database;

    final loteLimpio = (lote ?? '').trim();
    final tieneLote = loteLimpio.isNotEmpty;
    final prefijoLote = _prefijoLote(loteLimpio);

    // Prefijo del código final
    final prefijo = tieneLote ? prefijoLote : _prefijoModelo(modelo);
    if (prefijo.isEmpty) {
      // Fallback al prefijo de modelo si el lote es ilegible
      return '${_prefijoModelo(modelo)}-001';
    }

    // Filtro por lote (o ausencia de lote)
    final where = tieneLote
        ? 'codigo LIKE ? AND lote = ?'
        : 'codigo LIKE ? AND (lote IS NULL OR lote = "")';
    final args = tieneLote ? ['$prefijo-%', loteLimpio] : ['$prefijo-%'];

    final rows = await db.query(
      'vehiculo',
      columns: ['codigo'],
      where: where,
      whereArgs: args,
    );

    final regex = RegExp('^${RegExp.escape(prefijo)}-(\\d+)\$');
    int max = 0;
    for (final r in rows) {
      final m = regex.firstMatch((r['codigo'] ?? '').toString());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return '$prefijo-${(max + 1).toString().padLeft(3, '0')}';
  }

  /// Genera [cantidad] códigos consecutivos para un modelo.
  /// Si se pasa [lote], los códigos se prefijan con el nombre del lote
  /// y solo consideran vehículos del mismo lote.
  Future<List<String>> generarCodigosLote(
    String modelo,
    int cantidad, {
    String? lote,
  }) async {
    final db = await database;

    final loteLimpio = (lote ?? '').trim();
    final tieneLote = loteLimpio.isNotEmpty;
    final prefijoLote = _prefijoLote(loteLimpio);

    final prefijo = tieneLote ? prefijoLote : _prefijoModelo(modelo);
    if (prefijo.isEmpty) {
      final fallback = _prefijoModelo(modelo);
      return List.generate(cantidad, (i) {
        return '$fallback-${(i + 1).toString().padLeft(3, '0')}';
      });
    }

    final where = tieneLote
        ? 'codigo LIKE ? AND lote = ?'
        : 'codigo LIKE ? AND (lote IS NULL OR lote = "")';
    final args = tieneLote ? ['$prefijo-%', loteLimpio] : ['$prefijo-%'];

    final rows = await db.query(
      'vehiculo',
      columns: ['codigo'],
      where: where,
      whereArgs: args,
    );

    final regex = RegExp('^${RegExp.escape(prefijo)}-(\\d+)\$');
    int max = 0;
    for (final r in rows) {
      final m = regex.firstMatch((r['codigo'] ?? '').toString());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }

    return List.generate(cantidad, (i) {
      final n = max + 1 + i;
      return '$prefijo-${n.toString().padLeft(3, '0')}';
    });
  }

  // ========== LOTES ==========

  Future<List<Map<String, dynamic>>> obtenerLotes() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        lote,
        COUNT(*) AS total_vehiculos,
        MIN(created_at) AS fecha_inicio,
        MAX(created_at) AS fecha_fin
      FROM vehiculo
      WHERE lote IS NOT NULL AND lote != ''
      GROUP BY lote
      ORDER BY fecha_inicio DESC
    ''');
  }

  Future<List<Vehiculo>> obtenerVehiculosPorLote(String lote) async {
    final db = await database;
    final maps = await db.query(
      'vehiculo',
      where: 'lote = ?',
      whereArgs: [lote],
      orderBy: 'codigo ASC',
    );
    return maps.map((m) => Vehiculo.fromMap(m)).toList();
  }

  // ========== PLANTA DE ENSAMBLE (áreas + cámaras) ==========

  /// ✅ Mover un vehículo a una nueva área + cámara (y registrar en histórico)
  Future<void> moverVehiculoACamara(
    int idVehiculo, {
    required String area,
    required int camara,
    String? notas,
    bool entregado = false,
  }) async {
    final db = await database;
    final ahora = DateTime.now();

    await db.transaction((txn) async {
      await txn.update(
        'vehiculo',
        {
          'area_actual': area,
          'camara_actual': camara,
          'fecha_ingreso_area': _fechaSqlUtc(ahora),
          'estado': entregado ? 'ENTREGADO' : 'EN_PROCESO',
        },
        where: 'id_vehiculo = ?',
        whereArgs: [idVehiculo],
      );

      await txn.insert('movimiento_camara', {
        'id_vehiculo': idVehiculo,
        'area': area,
        'camara': camara,
        'estado': entregado ? 'ENTREGADO' : 'EN_PROCESO',
        'notas': notas,
        'created_at': _fechaSqlUtc(ahora),
      });
    });
  }

  /// ✅ Historial de recorrido de un vehículo
  Future<List<Map<String, dynamic>>> obtenerRecorridoVehiculo(
      int idVehiculo) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT id_movimiento, area, camara, estado, notas, created_at
      FROM movimiento_camara
      WHERE id_vehiculo = ?
      ORDER BY created_at ASC, id_movimiento ASC
    ''', [idVehiculo]);
  }

  /// ✅ WIP actual: cuántos vehículos hay por área + cámara
  Future<List<Map<String, dynamic>>> obtenerWipPorCamara() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT area_actual AS area,
             camara_actual AS camara,
             COUNT(*) AS total_vehiculos
      FROM vehiculo
      WHERE area_actual IS NOT NULL
        AND camara_actual IS NOT NULL
        AND (estado IS NULL OR estado != 'ENTREGADO')
      GROUP BY area_actual, camara_actual
      ORDER BY area_actual ASC, camara_actual ASC
    ''');
  }

  /// ✅ Vehículos en una cámara específica
  Future<List<Vehiculo>> obtenerVehiculosEnCamara(
    String area,
    int camara,
  ) async {
    final db = await database;
    final maps = await db.query(
      'vehiculo',
      where:
          'area_actual = ? AND camara_actual = ? AND (estado IS NULL OR estado != ?)',
      whereArgs: [area, camara, 'ENTREGADO'],
      orderBy: 'codigo ASC',
    );
    return maps.map((m) => Vehiculo.fromMap(m)).toList();
  }

  /// ✅ Total WIP por área
  Future<int> obtenerWipPorArea(String area) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM vehiculo
      WHERE area_actual = ? AND (estado IS NULL OR estado != 'ENTREGADO')
    ''', [area]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// ✅ Vehículos entregados
  Future<List<Vehiculo>> obtenerVehiculosEntregados() async {
    final db = await database;
    final maps = await db.query(
      'vehiculo',
      where: 'estado = ?',
      whereArgs: ['ENTREGADO'],
      orderBy: 'fecha_ingreso_area DESC',
    );
    return maps.map((m) => Vehiculo.fromMap(m)).toList();
  }

  /// ✅ Resumen general de la planta (en proceso / entregados / sin ubicar)
  Future<Map<String, dynamic>> obtenerResumenPlanta() async {
    final db = await database;

    final wip = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM vehiculo
      WHERE area_actual IS NOT NULL
        AND (estado IS NULL OR estado != 'ENTREGADO')
    ''');

    final entregados = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM vehiculo
      WHERE estado = 'ENTREGADO'
    ''');

    final sinUbicar = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM vehiculo
      WHERE area_actual IS NULL
    ''');

    return {
      'en_proceso': (wip.first['total'] as num?)?.toInt() ?? 0,
      'entregados': (entregados.first['total'] as num?)?.toInt() ?? 0,
      'sin_ubicar': (sinUbicar.first['total'] as num?)?.toInt() ?? 0,
    };
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
          'unidad': componente.unidad ?? 'LT',
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
        final unidad = comp['unidad']?.toString() ?? 'LT';

        await txn.insert('componente', {
          'id_calculo': calculoId,
          'nombre': nombre,
          'reseta': reseta,
          'valor_real': valorReal,
          'unidad': unidad,
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

  Future<Map<String, dynamic>?> obtenerUltimoCalculoConComponentes(
      int idVehiculo) async {
    final db = await database;

    final calculos = await db.query(
      'calculo',
      where: 'id_vehiculo = ?',
      whereArgs: [idVehiculo],
      orderBy: 'created_at DESC, id_calculo DESC',
      limit: 1,
    );

    if (calculos.isEmpty) return null;

    final calculo = calculos.first;
    final idCalculo = calculo['id_calculo'] as int;

    final componentes = await db.query(
      'componente',
      where: 'id_calculo = ?',
      whereArgs: [idCalculo],
      orderBy: 'id_componente ASC',
    );

    return {
      'calculo': calculo,
      'componentes': componentes,
    };
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

  Future<int> eliminarProducto(int id) async {
    final db = await database;
    return await db.delete(
      'inventario',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarProductoPorNombre(String nombre) async {
    final db = await database;
    return await db.delete(
      'inventario',
      where: 'nombre = ?',
      whereArgs: [nombre],
    );
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
        v.modelo AS nombreVehiculo,
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo
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
        comp.unidad,
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
      final unidad = r['unidad']?.toString() ?? 'LT';
      final stock = (r['stock_actual'] as num?)?.toDouble() ?? 0.0;

      final stockRestanteReal = stock - valorReal;
      final stockRestanteTeorico = stock - reseta;

      resultado.add({
        'id_componente': r['id_componente'],
        'nombre': nombre,
        'reseta': reseta,
        'valor_real': valorReal,
        'unidad': unidad,
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
        MAX(comp.unidad) AS unidad,
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
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo,
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
      where = "WHERE date(c.created_at, 'localtime') BETWEEN ? AND ?";
      args = [
        _fechaSqlUtc(desde).substring(0, 10),
        _fechaSqlUtc(hasta).substring(0, 10),
      ];
    } else if (desde != null) {
      where = "WHERE date(c.created_at, 'localtime') >= ?";
      args = [_fechaSqlUtc(desde).substring(0, 10)];
    } else if (hasta != null) {
      where = "WHERE date(c.created_at, 'localtime') <= ?";
      args = [_fechaSqlUtc(hasta).substring(0, 10)];
    }

    return await db.rawQuery('''
      SELECT 
        c.id_calculo,
        c.id_vehiculo,
        c.diferencia,
        c.valor_real,
        c.created_at,
        v.modelo AS nombreVehiculo,
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo
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
        _fechaSqlUtc(desde).substring(0, 10),
        _fechaSqlUtc(hasta).substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [_fechaSqlUtc(desde).substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [_fechaSqlUtc(hasta).substring(0, 10)];
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
        _fechaSqlUtc(desde).substring(0, 10),
        _fechaSqlUtc(hasta).substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [_fechaSqlUtc(desde).substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [_fechaSqlUtc(hasta).substring(0, 10)];
    }

    return await db.rawQuery('''
      SELECT 
        comp.nombre,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS veces_usado,
        MAX(comp.unidad) AS unidad,
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
        _fechaSqlUtc(desde).substring(0, 10),
        _fechaSqlUtc(hasta).substring(0, 10),
      ];
    } else if (desde != null) {
      where += " AND date(c.created_at, 'localtime') >= ?";
      args = [_fechaSqlUtc(desde).substring(0, 10)];
    } else if (hasta != null) {
      where += " AND date(c.created_at, 'localtime') <= ?";
      args = [_fechaSqlUtc(hasta).substring(0, 10)];
    }

    return await db.rawQuery('''
      SELECT 
        v.modelo AS nombreVehiculo,
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo,
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
      where = "WHERE c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where = "WHERE c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where = "WHERE c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
    }

    return await db.rawQuery('''
      SELECT 
        c.id_calculo,
        c.id_vehiculo,
        c.diferencia,
        c.valor_real,
        c.created_at,
        v.modelo AS nombreVehiculo,
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
    }

    return await db.rawQuery('''
      SELECT 
        comp.nombre,
        COALESCE(SUM(comp.valor_real), 0) AS total_real,
        COALESCE(SUM(comp.reseta), 0) AS total_teorico,
        COUNT(comp.id_componente) AS veces_usado,
        MAX(comp.unidad) AS unidad,
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
    }

    return await db.rawQuery('''
      SELECT 
        v.modelo AS nombreVehiculo,
        v.codigo AS codigoVehiculo,
        v.lote AS loteVehiculo,
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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

      final horaInicioStr = _fechaSqlUtc(horaInicio);
      final horaFinStr = _fechaSqlUtc(horaFin);

      final detalle = await db.rawQuery('''
        SELECT 
          v.id_vehiculo,
          v.modelo,
          v.codigo,
          v.lote,
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
          AND c.created_at >= ?
          AND c.created_at < ?
        GROUP BY v.id_vehiculo, v.modelo, v.codigo, v.lote
        ORDER BY unidades DESC
      ''', [horaInicioStr, horaFinStr]);

      final List<Map<String, dynamic>> vehiculosConComponentes = [];

      for (final v in detalle) {
        final idVehiculo = v['id_vehiculo'];

        final componentes = await db.rawQuery('''
          SELECT 
            comp.nombre,
            MAX(comp.unidad) AS unidad,
            COUNT(comp.id_componente) AS veces_usado,
            COALESCE(SUM(comp.valor_real), 0) AS cantidad_real,
            COALESCE(SUM(comp.reseta), 0) AS cantidad_teorico,
            (COALESCE(SUM(comp.valor_real), 0) - COALESCE(SUM(comp.reseta), 0)) AS diferencia
          FROM calculo c
          INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
          WHERE c.id_vehiculo = ?
            AND comp.valor_real IS NOT NULL 
            AND comp.valor_real > 0
            AND c.created_at >= ?
            AND c.created_at < ?
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

  Future<List<Map<String, dynamic>>> obtenerDetalleComponentesPorHora({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    String where = 'WHERE comp.valor_real IS NOT NULL AND comp.valor_real > 0';
    List<dynamic> args = [];

    if (desde != null && hasta != null) {
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
    }

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

      final horaInicioStr = _fechaSqlUtc(horaInicio);
      final horaFinStr = _fechaSqlUtc(horaFin);

      final componentes = await db.rawQuery('''
        SELECT 
          comp.nombre,
          MAX(comp.unidad) AS unidad,
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
          AND c.created_at >= ?
          AND c.created_at < ?
        GROUP BY comp.nombre
        ORDER BY total_real DESC
      ''', [horaInicioStr, horaFinStr]);

      final vehiculos = await db.rawQuery('''
        SELECT DISTINCT v.modelo, v.codigo
        FROM calculo c
        INNER JOIN vehiculo v ON v.id_vehiculo = c.id_vehiculo
        INNER JOIN componente comp ON comp.id_calculo = c.id_calculo
        WHERE comp.valor_real IS NOT NULL 
          AND comp.valor_real > 0
          AND c.created_at >= ?
          AND c.created_at < ?
        ORDER BY v.modelo
      ''', [horaInicioStr, horaFinStr]);

      resultado.add({
        'hora': horaRaw,
        'vehiculos': vehiculos
            .map((e) => '${e['codigo'] ?? ''} · ${e['modelo']}')
            .toList(),
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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
      where += " AND c.created_at BETWEEN ? AND ?";
      args = [_fechaSqlUtc(desde), _fechaSqlUtc(hasta)];
    } else if (desde != null) {
      where += " AND c.created_at >= ?";
      args = [_fechaSqlUtc(desde)];
    } else if (hasta != null) {
      where += " AND c.created_at <= ?";
      args = [_fechaSqlUtc(hasta)];
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
      debugPrint('      unidad: ${row['unidad']}');
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
