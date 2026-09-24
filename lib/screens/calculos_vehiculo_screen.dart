import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vehiculos_app/data/datos_modelos.dart';
import 'package:vehiculos_app/screens/escaner_qr_screen.dart';
import 'package:vehiculos_app/models/vehiculo.dart';
import '../database/database_helper.dart';
import '../models/calculo.dart';

class NuevoCalculoScreen extends StatefulWidget {
  final int idVehiculo;
  final String nombreVehiculo;
  final String? codigoVehiculo;

  const NuevoCalculoScreen({
    super.key,
    required this.idVehiculo,
    required this.nombreVehiculo,
    this.codigoVehiculo,
  });

  @override
  State<NuevoCalculoScreen> createState() => _NuevoCalculoScreenState();
}

class _NuevoCalculoScreenState extends State<NuevoCalculoScreen> {
  final db = DatabaseHelper();

  // ✅ LÍMITES DE COMPONENTES
  static const int _componentesEsperados = 11;
  static const int _maxComponentes = 11;

  // ✅ UNIDADES DE MEDIDA REALES DEL CATÁLOGO
  static const List<String> _unidadesMedida = [
    'LT',
    'GL',
    'GR',
    'KG',
    'MT',
  ];

  final List<Map<String, dynamic>> _componentes = [];
  late List<Map<String, dynamic>> catalogo;

  bool _cargandoPrevios = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    _inicializarCatalogo();

    try {
      final previo =
          await db.obtenerUltimoCalculoConComponentes(widget.idVehiculo);

      if (!mounted) return;

      if (previo != null && (previo['componentes'] as List).isNotEmpty) {
        final List componentesGuardados = previo['componentes'] as List;

        for (final comp in _componentes) {
          _disposeComponente(comp);
        }
        _componentes.clear();

        for (final row in componentesGuardados) {
          final map = Map<String, dynamic>.from(row as Map);
          final nombre = map['nombre']?.toString() ?? '';
          final reseta = (map['reseta'] as num?)?.toDouble() ?? 0.0;
          final valorReal = (map['valor_real'] as num?)?.toDouble();
          final unidad = _normalizarUnidad(map['unidad']?.toString());

          _componentes.add({
            'nombre': nombre,
            'reseta': reseta,
            'unidad': unidad,
            'valorRealController': TextEditingController(
              text: valorReal != null ? valorReal.toStringAsFixed(2) : '',
            ),
            'resetaController': TextEditingController(
              text: reseta.toStringAsFixed(2),
            ),
            'diferencia': valorReal != null
                ? (valorReal - reseta).toStringAsFixed(2)
                : '0.00',
          });
        }

        debugPrint('✅ Cálculo previo cargado: '
            '${_componentes.length} componentes');
      } else {
        debugPrint('ℹ️ No hay cálculo previo. Se usa el catálogo base.');
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar cálculo previo: $e');
    }

    if (!mounted) return;
    setState(() => _cargandoPrevios = false);

    if (_componentes.isNotEmpty &&
        _componentes.length < _componentesEsperados) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final faltantes = _componentesEsperados - _componentes.length;
        _showSnack(
          '⚠️ Faltan $faltantes componente${faltantes == 1 ? '' : 's'} '
          'para completar los $_componentesEsperados.',
          esAdvertencia: true,
        );
      });
    }
  }

  String _normalizarNombre(String nombre) {
    return nombre
        .trim()
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'\bDE\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
        if (_unidadesMedida.contains(u)) return u;
        return 'LT';
    }
  }

  void _inicializarCatalogo() {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔍 nombreVehiculo recibido: "${widget.nombreVehiculo}"');
    debugPrint('🔍 codigoVehiculo recibido: "${widget.codigoVehiculo}"');
    debugPrint('🔍 Modelos disponibles: ${DatosModelos.modelos.length}');
    debugPrint('═══════════════════════════════════════════');

    final nombreNormalizado = _normalizarNombre(widget.nombreVehiculo);

    for (final modelo in DatosModelos.datosPorModelo.keys) {
      if (_normalizarNombre(modelo) == nombreNormalizado) {
        catalogo = DatosModelos.getComponentesPorModelo(modelo);
        debugPrint('✅ Coincidencia EXACTA: "$modelo" '
            '(${catalogo.length} componentes)');
        _validarCatalogo();
        return;
      }
    }

    for (final modelo in DatosModelos.datosPorModelo.keys) {
      final modeloNorm = _normalizarNombre(modelo);
      if (modeloNorm.startsWith(nombreNormalizado) ||
          nombreNormalizado.startsWith(modeloNorm) ||
          modeloNorm.contains(nombreNormalizado) ||
          nombreNormalizado.contains(modeloNorm)) {
        catalogo = DatosModelos.getComponentesPorModelo(modelo);
        debugPrint('⚠️ Coincidencia PARCIAL: "$modelo" '
            '(${catalogo.length} componentes)');
        _validarCatalogo();
        return;
      }
    }

    debugPrint('❌ No se encontró modelo para "${widget.nombreVehiculo}"');
    catalogo = const [
      {
        'nombre': 'ACEITE CAJA SYNGEAR AT 75W90 GL4 - VEEDOL',
        'reseta': 1.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE DIFERENCIAL 80W90 GL5',
        'reseta': 1.60,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 4.40,
        'unidad': 'LT'
      },
    ];
    _validarCatalogo();
  }

  void _validarCatalogo() {
    if (catalogo.isEmpty) {
      debugPrint('⚠️ Catálogo vacío, usando fallback');
      catalogo = const [
        {
          'nombre': 'ACEITE CAJA SYNGEAR AT 75W90 GL4 - VEEDOL',
          'reseta': 1.50,
          'unidad': 'LT'
        },
        {
          'nombre': 'ACEITE DE DIFERENCIAL 80W90 GL5',
          'reseta': 1.60,
          'unidad': 'LT'
        },
        {
          'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
          'reseta': 4.40,
          'unidad': 'LT'
        },
      ];
    }
    if (_componentes.isEmpty) {
      _componentes.add(_nuevoComponente(catalogo.first));
    }
  }

  // ============================================================
  // CREAR COMPONENTE
  // ============================================================

  Map<String, dynamic> _nuevoComponente(Map<String, dynamic> item) {
    return {
      'nombre': item['nombre'],
      'reseta': item['reseta'],
      'unidad': _normalizarUnidad(
        item['unidad']?.toString() ?? item['medida']?.toString(),
      ),
      'valorRealController': TextEditingController(),
      'resetaController': TextEditingController(
        text: (item['reseta'] as num?)?.toStringAsFixed(2) ?? '',
      ),
      'diferencia': '0.00',
    };
  }

  void _disposeComponente(Map<String, dynamic> comp) {
    (comp['valorRealController'] as TextEditingController?)?.dispose();
    (comp['resetaController'] as TextEditingController?)?.dispose();
  }

  // ============================================================
  // DIFERENCIA
  // ============================================================

  void _calcularDiferenciaIndividual(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _componentes.length) return;

    final comp = _componentes[index];
    final valorReal = double.tryParse(
          (comp['valorRealController'] as TextEditingController).text,
        ) ??
        0.0;
    final reseta = double.tryParse(comp['reseta']?.toString() ?? '') ?? 0.0;

    final diferencia = valorReal > 0 ? (valorReal - reseta) : 0.0;

    setState(() {
      comp['diferencia'] = diferencia.toStringAsFixed(2);
    });
  }

  // ============================================================
  // DUPLICADOS
  // ============================================================

  bool _estaDuplicado(String nombre, {int? indexExcluir}) {
    for (int i = 0; i < _componentes.length; i++) {
      if (i == indexExcluir) continue;
      if (_componentes[i]['nombre'] == nombre) return true;
    }
    return false;
  }

  bool _todosUsados() {
    return catalogo.every(
      (item) => _estaDuplicado(item['nombre'] as String),
    );
  }

  // ============================================================
  // AGREGAR / ELIMINAR
  // ============================================================

  void _agregarComponente() {
    if (!mounted) return;

    if (_componentes.length >= _maxComponentes) {
      _showSnack(
        '❌ Error: máximo $_maxComponentes componentes por cálculo. ',
        esError: true,
      );
      return;
    }

    if (catalogo.isEmpty) {
      _showSnack('No hay catálogo de componentes disponible', esError: true);
      return;
    }

    if (_todosUsados()) {
      _showSnack('Ya agregaste todos los componentes disponibles',
          esAdvertencia: true);
      return;
    }

    final primerDisponible = catalogo.firstWhere(
      (item) => !_estaDuplicado(item['nombre'] as String),
      orElse: () => catalogo.first,
    );

    setState(() {
      _componentes.add(_nuevoComponente(primerDisponible));
    });

    if (_componentes.length == _componentesEsperados) {
      _showSnack(
        '✅ Has completado los $_componentesEsperados componentes esperados.',
      );
    }
  }

  void _eliminarComponente(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _componentes.length) return;

    final comp = _componentes[index];
    _disposeComponente(comp);

    setState(() {
      _componentes.removeAt(index);
    });

    if (_componentes.isNotEmpty &&
        _componentes.length < _componentesEsperados) {
      final faltantes = _componentesEsperados - _componentes.length;
      _showSnack(
        '⚠️ Faltan $faltantes componente${faltantes == 1 ? '' : 's'} '
        'para completar los $_componentesEsperados.',
        esAdvertencia: true,
      );
    }
  }

  // ============================================================
  // QR
  // ============================================================

  Future<void> _escanearQR(int index, bool esValorReal) async {
    final valorEscaneado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const EscanerQRScreen()),
    );

    if (!mounted) return;
    if (valorEscaneado == null || valorEscaneado.isEmpty) return;
    if (index < 0 || index >= _componentes.length) return;

    final contenido = valorEscaneado.trim();

    debugPrint('═══════════════════════════════════════════');
    debugPrint('📷 QR crudo: "$contenido"');
    debugPrint('📷 Longitud: ${contenido.length}');
    debugPrint('═══════════════════════════════════════════');

    String? nombreComponente;
    double? valor;

    if (contenido.startsWith('{')) {
      try {
        final decoded = jsonDecode(contenido);
        if (decoded is Map) {
          nombreComponente = decoded['componente']?.toString() ??
              decoded['nombre']?.toString() ??
              decoded['name']?.toString() ??
              decoded['producto']?.toString() ??
              decoded['product']?.toString();

          final valorRaw = decoded['valor'] ??
              decoded['value'] ??
              decoded['cantidad'] ??
              decoded['cantidad_real'] ??
              decoded['cant'];
          valor = double.tryParse(
            valorRaw?.toString().replaceAll(',', '.') ?? '',
          );
        }
      } catch (e) {
        debugPrint('❌ Error parseando JSON: $e');
      }
    } else if (contenido.contains('|')) {
      final partes = contenido.split('|');
      nombreComponente = partes[0].trim();
      if (partes.length > 1) {
        valor = double.tryParse(partes[1].trim().replaceAll(',', '.'));
      }
    } else if (contenido.contains(',') || contenido.contains(';')) {
      final sep = contenido.contains(',') ? ',' : ';';
      final partes = contenido.split(sep);
      if (partes.length >= 2) {
        final posibleNombre = partes[0].trim();
        final posibleValor =
            double.tryParse(partes[1].trim().replaceAll(',', '.'));
        if (posibleValor != null &&
            RegExp(r'[A-Za-z]').hasMatch(posibleNombre)) {
          nombreComponente = posibleNombre;
          valor = posibleValor;
        }
      }
    } else {
      final soloNumero = double.tryParse(contenido.replaceAll(',', '.'));
      if (soloNumero != null) {
        valor = soloNumero;
      } else {
        nombreComponente = contenido;
      }
    }

    debugPrint('📷 Parseado → componente: "$nombreComponente" | valor: $valor');

    if (nombreComponente != null && nombreComponente.isNotEmpty) {
      final normalizado = _normalizarNombre(nombreComponente);

      Map<String, dynamic>? itemEncontrado;
      for (final item in catalogo) {
        final nombreCat = _normalizarNombre(item['nombre'] as String);
        if (nombreCat == normalizado ||
            nombreCat.contains(normalizado) ||
            normalizado.contains(nombreCat)) {
          itemEncontrado = item;
          break;
        }
      }

      if (itemEncontrado != null) {
        if (_estaDuplicado(
          itemEncontrado['nombre'] as String,
          indexExcluir: index,
        )) {
          _showSnack(
            'El componente "${itemEncontrado['nombre']}" ya está agregado',
            esAdvertencia: true,
          );
          return;
        }

        setState(() {
          _componentes[index]['nombre'] = itemEncontrado!['nombre'];
          _componentes[index]['reseta'] = itemEncontrado['reseta'];
          _componentes[index]['unidad'] = _normalizarUnidad(
            itemEncontrado['unidad']?.toString() ??
                itemEncontrado['medida']?.toString(),
          );

          (_componentes[index]['resetaController'] as TextEditingController)
                  .text =
              (itemEncontrado['reseta'] as num?)?.toStringAsFixed(2) ?? '0.00';

          if (valor != null) {
            (_componentes[index]['valorRealController']
                    as TextEditingController)
                .text = valor!.toStringAsFixed(2);
          }
        });

        _calcularDiferenciaIndividual(index);

        _showSnack(
          valor != null
              ? '✅ ${itemEncontrado['nombre']} → ${valor.toStringAsFixed(2)} ${_componentes[index]['unidad']}'
              : '✅ ${itemEncontrado['nombre']} (ingresa el valor real)',
        );
        return;
      } else {
        debugPrint(
            '⚠️ Componente "$nombreComponente" NO está en el catálogo actual');
        _showSnack(
          'El componente "$nombreComponente" no está en la lista del modelo',
          esAdvertencia: true,
        );
        return;
      }
    }

    if (valor != null) {
      final valorFinal = valor!;
      setState(() {
        if (esValorReal) {
          (_componentes[index]['valorRealController'] as TextEditingController)
              .text = valorFinal.toStringAsFixed(2);
        } else {
          _componentes[index]['reseta'] = valorFinal;
          (_componentes[index]['resetaController'] as TextEditingController)
              .text = valorFinal.toStringAsFixed(2);
        }
      });
      _calcularDiferenciaIndividual(index);
    } else {
      _showSnack('QR inválido: "$contenido"', esError: true);
    }
  }

  // ============================================================
  // ✅ NUEVO: DIÁLOGO DE UBICACIÓN EN PLANTA DE ENSAMBLE
  // ============================================================

  Future<Map<String, dynamic>?> _seleccionarAreaYCamara() async {
    String areaSel = 'CHASIS';
    int? camaraSel;
    final notasController = TextEditingController();
    bool entregar = false;

    // ✅ Intentamos cargar la ubicación actual para pre-seleccionarla
    try {
      final actual = await db.getVehiculoById(widget.idVehiculo);
      if (actual != null) {
        if (actual.areaActual != null &&
            Vehiculo.areasDisponibles.contains(actual.areaActual)) {
          areaSel = actual.areaActual!;
        }
        if (actual.camaraActual != null) {
          camaraSel = actual.camaraActual;
        }
      }
    } catch (_) {}

    if (!mounted) return null;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.precision_manufacturing,
                    color: Colors.purple.shade700, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '¿Dónde quedó el vehículo?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de área
                const Text(
                  'Área:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: Vehiculo.areasDisponibles.map((area) {
                    final selected = areaSel == area;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: area == Vehiculo.areasDisponibles.last ? 0 : 8,
                        ),
                        child: GestureDetector(
                          onTap: () => setStateDialog(() => areaSel = area),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.purple.shade700
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                area,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Selector de cámara
                Row(
                  children: [
                    const Text(
                      'Cámara:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      camaraSel != null
                          ? 'Seleccionada: C$camaraSel'
                          : 'Sin seleccionar',
                      style: TextStyle(
                        fontSize: 10,
                        color: camaraSel != null
                            ? Colors.purple.shade700
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(Vehiculo.totalCamaras, (i) {
                    final num = i + 1;
                    final selected = camaraSel == num;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => camaraSel = num),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.purple.shade700
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? Colors.purple.shade700
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$num',
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),

                // Notas
                TextField(
                  controller: notasController,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Pasó a control de calidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Checkbox: entregar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: CheckboxListTile(
                    value: entregar,
                    onChanged: (val) =>
                        setStateDialog(() => entregar = val ?? false),
                    title: const Text(
                      'Marcar como ENTREGADO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'El vehículo sale del flujo de producción',
                      style: TextStyle(fontSize: 10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('OMITIR'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (camaraSel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona la cámara actual'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'area': areaSel,
                  'camara': camaraSel,
                  'notas': notasController.text.trim(),
                  'entregado': entregar,
                });
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('GUARDAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> _guardarCalculo() async {
    if (_componentes.isEmpty) {
      _showSnack('❌ Error: agrega al menos 1 componente', esError: true);
      return;
    }

    if (_componentes.length > _maxComponentes) {
      _showSnack(
        '❌ Error: no puedes guardar con más de $_maxComponentes componentes.',
        esError: true,
      );
      return;
    }

    if (_componentes.length < _componentesEsperados) {
      final faltantes = _componentesEsperados - _componentes.length;
      final respuesta = await _confirmarGuardadoIncompleto(faltantes);
      if (respuesta != true) return;
    }

    final List<Map<String, dynamic>> componentesParaGuardar = [];
    double diferenciaTotal = 0.0;

    for (var comp in _componentes) {
      final nombre = comp['nombre'] as String?;
      if (nombre == null || nombre.isEmpty) continue;

      final valorRealTexto =
          (comp['valorRealController'] as TextEditingController).text.trim();
      final valorReal = double.tryParse(valorRealTexto);
      final reseta = double.tryParse(comp['reseta'].toString()) ?? 0.0;
      final unidad = comp['unidad'] as String? ?? 'LT';

      if (valorReal == null || valorReal <= 0) continue;

      diferenciaTotal += (valorReal - reseta);

      componentesParaGuardar.add({
        'nombre': nombre,
        'reseta': reseta,
        'valor_real': valorReal,
        'unidad': unidad,
      });
    }

    if (componentesParaGuardar.isEmpty) {
      _showSnack(
        '❌ Ingresa al menos un Valor Real válido (mayor a 0)',
        esError: true,
      );
      return;
    }

    // ✅ NUEVO: preguntar ubicación en planta de ensamble
    final ubicacion = await _seleccionarAreaYCamara();

    try {
      final calculoNuevo = Calculo(
        idVehiculo: widget.idVehiculo,
        diferencia: diferenciaTotal.toStringAsFixed(2),
        createdAt: DateTime.now(),
      );

      await db.guardarCalculoCompleto(calculoNuevo, componentesParaGuardar);

      // ✅ NUEVO: mover vehículo en planta de ensamble
      if (ubicacion != null) {
        await db.moverVehiculoACamara(
          widget.idVehiculo,
          area: ubicacion['area'] as String,
          camara: ubicacion['camara'] as int,
          notas: ubicacion['notas'] as String?,
          entregado: ubicacion['entregado'] as bool? ?? false,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al guardar: $e', esError: true);
      }
    }
  }

  Future<bool?> _confirmarGuardadoIncompleto(int faltantes) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Faltan $faltantes componente${faltantes == 1 ? '' : 's'}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has agregado ${_componentes.length} de $_componentesEsperados componentes.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lo normal es registrar los $_componentesEsperados componentes. ',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Guardar igual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(
    String msg, {
    bool esError = false,
    bool esAdvertencia = false,
  }) {
    if (!mounted) return;

    Color bgColor = Colors.black87;
    IconData icono = Icons.info_outline;

    if (esError) {
      bgColor = Colors.red.shade700;
      icono = Icons.error_outline;
    } else if (esAdvertencia) {
      bgColor = Colors.orange.shade800;
      icono = Icons.warning_amber_rounded;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icono, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: esError ? 3 : 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    for (final comp in _componentes) {
      _disposeComponente(comp);
    }
    _componentes.clear();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.codigoVehiculo != null &&
                widget.codigoVehiculo!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2, size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.codigoVehiculo!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              widget.nombreVehiculo,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargandoPrevios
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Componentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Agrega los componentes del cálculo',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  _buildHeaderRow(),
                  const SizedBox(height: 10),
                  ...List.generate(_componentes.length, (index) {
                    return _buildComponenteRow(index);
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filled(
                      onPressed: (_componentes.length >= _maxComponentes ||
                              _todosUsados())
                          ? null
                          : _agregarComponente,
                      icon: const Icon(Icons.add),
                      tooltip: _componentes.length >= _maxComponentes
                          ? 'Máximo $_maxComponentes componentes alcanzado'
                          : _todosUsados()
                              ? 'Todos los componentes ya fueron agregados'
                              : 'Agregar componente',
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarCalculo,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar Cálculo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderRow() {
    final cantidad = _componentes.length;
    final completo = cantidad == _componentesEsperados;
    final faltan = cantidad < _componentesEsperados;

    Color bg;
    Color fg;
    IconData icono;

    if (completo) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icono = Icons.check_circle_outline;
    } else if (faltan) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      icono = Icons.warning_amber_rounded;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      icono = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: fg),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Componentes del cálculo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$cantidad / $_componentesEsperados',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponenteRow(int index) {
    final componente = _componentes[index];
    final nombreActual = componente['nombre'] as String?;

    final nombresBase = catalogo.map((e) => e['nombre'] as String).toList();
    final nombresFinal = <String>{...nombresBase};
    if (nombreActual != null && nombreActual.isNotEmpty) {
      nombresFinal.add(nombreActual);
    }
    for (final c in _componentes) {
      final n = c['nombre'] as String?;
      if (n != null && n.isNotEmpty) nombresFinal.add(n);
    }

    final opcionesDisponibles = nombresFinal.where((nombreItem) {
      if (nombreItem == nombreActual) return true;
      return !_estaDuplicado(nombreItem, indexExcluir: index);
    }).toList();

    final bool nombreValido =
        nombreActual != null && opcionesDisponibles.contains(nombreActual);
    final String? dropdownValue = nombreValido ? nombreActual : null;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (_componentes.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: 'Eliminar componente',
                    onPressed: () => _eliminarComponente(index),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Componente',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minHeight: 42),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: dropdownValue,
                  selectedItemBuilder: (context) {
                    return opcionesDisponibles.map<Widget>((nombre) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nombre,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList();
                  },
                  items: opcionesDisponibles.map((nombre) {
                    return DropdownMenuItem<String>(
                      value: nombre,
                      child: SizedBox(
                        width: 300,
                        child: Text(
                          nombre,
                          style: const TextStyle(fontSize: 12),
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (valorSeleccionado) {
                    if (valorSeleccionado == null) return;

                    if (_estaDuplicado(valorSeleccionado,
                        indexExcluir: index)) {
                      _showSnack('Ese componente ya está agregado',
                          esAdvertencia: true);
                      return;
                    }

                    final enCatalogo = catalogo.firstWhere(
                      (c) => c['nombre'] == valorSeleccionado,
                      orElse: () => <String, dynamic>{},
                    );

                    setState(() {
                      componente['nombre'] = valorSeleccionado;

                      if (enCatalogo.isNotEmpty) {
                        componente['reseta'] = enCatalogo['reseta'];
                        componente['unidad'] = _normalizarUnidad(
                          enCatalogo['unidad']?.toString() ??
                              enCatalogo['medida']?.toString(),
                        );
                        (componente['resetaController']
                                as TextEditingController)
                            .text = (enCatalogo['reseta'] as num?)
                                ?.toStringAsFixed(2) ??
                            '0.00';
                      }
                    });

                    _calcularDiferenciaIndividual(index);
                  },
                  hint: const Text(
                    'Seleccionar componente',
                    style: TextStyle(fontSize: 12),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  menuMaxHeight: 400,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCampo(
                    label: 'Reseta',
                    child: TextField(
                      controller: componente['resetaController']
                          as TextEditingController,
                      readOnly: true,
                      enabled: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _buildCampo(
                    label: 'Unidad',
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _unidadesMedida.contains(componente['unidad'])
                              ? componente['unidad']
                              : 'LT',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          items: _unidadesMedida.map((u) {
                            return DropdownMenuItem<String>(
                              value: u,
                              child: Text(
                                u,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (nuevaUnidad) {
                            if (nuevaUnidad == null) return;
                            setState(() {
                              componente['unidad'] = nuevaUnidad;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: _buildCampo(
                    label: 'Valor Real',
                    child: TextField(
                      controller: componente['valorRealController']
                          as TextEditingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        isDense: true,
                        hintText: '0.00',
                      ),
                      onChanged: (value) {
                        _calcularDiferenciaIndividual(index);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: _buildCampo(
                    label: 'Diferencia',
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        '${componente['diferencia'] ?? '0.00'} ${componente['unidad'] ?? ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _colorDiferencia(
                            componente['diferencia']?.toString() ?? '0.00',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _escanearQR(index, true),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text(
                  'Escanear Valor Real',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Color _colorDiferencia(String diff) {
    final valor = double.tryParse(diff) ?? 0.0;
    if (valor > 0) return Colors.orange.shade700;
    if (valor < 0) return Colors.green.shade700;
    return Colors.grey.shade700;
  }
}
