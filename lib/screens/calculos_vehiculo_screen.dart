import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vehiculos_app/data/datos_modelos.dart';
import 'package:vehiculos_app/screens/escaner_qr_screen.dart';
import '../database/database_helper.dart';
import '../models/calculo.dart';

class NuevoCalculoScreen extends StatefulWidget {
  final int idVehiculo;
  final String nombreVehiculo;

  const NuevoCalculoScreen({
    super.key,
    required this.idVehiculo,
    required this.nombreVehiculo,
  });

  @override
  State<NuevoCalculoScreen> createState() => _NuevoCalculoScreenState();
}

class _NuevoCalculoScreenState extends State<NuevoCalculoScreen> {
  final db = DatabaseHelper();

  final List<Map<String, dynamic>> _componentes = [];
  late List<Map<String, dynamic>> catalogo;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _inicializarCatalogo();
  }

  /// ✅ Normaliza un texto para comparar:
  /// - Trim, mayúsculas
  /// - Quita acentos (Á→A, É→E, Í→I, Ó→O, Ú→U, Ü→U)
  /// - Quita la palabra "DE" (para que "ACEITE CAJA" == "ACEITE DE CAJA")
  /// - Colapsa espacios, guiones y guiones bajos
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
        .replaceAll(RegExp(r'\bDE\b'), '') // quita "DE"
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// ✅ Inicializa el catálogo buscando el modelo del vehículo.
  /// Primero coincidencia exacta, luego parcial, si no, fallback.
  void _inicializarCatalogo() {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔍 nombreVehiculo recibido: "${widget.nombreVehiculo}"');
    debugPrint('🔍 Modelos disponibles: ${DatosModelos.modelos.length}');
    debugPrint('═══════════════════════════════════════════');

    final nombreNormalizado = _normalizarNombre(widget.nombreVehiculo);

    // 1️⃣ Coincidencia EXACTA
    for (final modelo in DatosModelos.datosPorModelo.keys) {
      if (_normalizarNombre(modelo) == nombreNormalizado) {
        catalogo = DatosModelos.getComponentesPorModelo(modelo);
        debugPrint('✅ Coincidencia EXACTA: "$modelo" '
            '(${catalogo.length} componentes)');
        _validarCatalogo();
        return;
      }
    }

    // 2️⃣ Coincidencia PARCIAL
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

    // 3️⃣ Fallback
    debugPrint('❌ No se encontró modelo para "${widget.nombreVehiculo}"');
    catalogo = const [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.50},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 1.60},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 4.40},
    ];
    _validarCatalogo();
  }

  void _validarCatalogo() {
    if (catalogo.isEmpty) {
      debugPrint('⚠️ Catálogo vacío, usando fallback');
      catalogo = const [
        {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.50},
        {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 1.60},
        {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 4.40},
      ];
    }
    _componentes.add(_nuevoComponente(catalogo.first));
  }

  // ============================================================
  // CREAR COMPONENTE
  // ============================================================

  Map<String, dynamic> _nuevoComponente(Map<String, dynamic> item) {
    return {
      'nombre': item['nombre'],
      'reseta': item['reseta'],
      'valorRealController': TextEditingController(),
      'resetaController': TextEditingController(
        text: (item['reseta'] as num?)?.toStringAsFixed(2) ?? '',
      ),
      'diferencia': '0.00',
    };
  }

  // ============================================================
  // LIBERAR CONTROLLERS
  // ============================================================

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
  // AGREGAR / ELIMINAR
  // ============================================================

  void _agregarComponente() {
    if (!mounted) return;
    if (catalogo.isEmpty) {
      _showSnack('No hay catálogo de componentes disponible');
      return;
    }
    setState(() {
      _componentes.add(_nuevoComponente(catalogo.first));
    });
  }

  void _eliminarComponente(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _componentes.length) return;

    final comp = _componentes[index];
    _disposeComponente(comp);

    setState(() {
      _componentes.removeAt(index);
    });
  }

  // ============================================================
  // QR
  // ============================================================

  /// ✅ Escanea un QR y rellena automáticamente:
  ///   1. El **componente** (buscándolo en el catálogo)
  ///   2. El **Valor Real** (si el QR lo trae)
  ///
  /// Formatos soportados:
  ///   - `NOMBRE_COMPONENTE` (solo nombre)
  ///   - `NOMBRE_COMPONENTE|4.50`
  ///   - `{"componente":"NOMBRE","valor":4.5}`
  ///   - `4.50` (solo valor)
  ///   - Texto libre que contenga un número
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

    // ─── 1) JSON ───
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
    }
    // ─── 2) Separador "|" ───
    else if (contenido.contains('|')) {
      final partes = contenido.split('|');
      nombreComponente = partes[0].trim();
      if (partes.length > 1) {
        valor = double.tryParse(partes[1].trim().replaceAll(',', '.'));
      }
    }
    // ─── 3) Separador "," o ";" ───
    else if (contenido.contains(',') || contenido.contains(';')) {
      final sep = contenido.contains(',') ? ',' : ';';
      final partes = contenido.split(sep);
      if (partes.length >= 2) {
        // Si la primera parte parece nombre (tiene letras) y la segunda número
        final posibleNombre = partes[0].trim();
        final posibleValor =
            double.tryParse(partes[1].trim().replaceAll(',', '.'));
        if (posibleValor != null &&
            RegExp(r'[A-Za-z]').hasMatch(posibleNombre)) {
          nombreComponente = posibleNombre;
          valor = posibleValor;
        }
      }
    }
    // ─── 4) Solo número o solo nombre ───
    else {
      final soloNumero = double.tryParse(contenido.replaceAll(',', '.'));
      if (soloNumero != null) {
        valor = soloNumero;
      } else {
        nombreComponente = contenido; // 👈 el QR es el NOMBRE del componente
      }
    }

    debugPrint('📷 Parseado → componente: "$nombreComponente" | valor: $valor');

    // ─── 5) Buscar el componente en el catálogo ───
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
        setState(() {
          _componentes[index]['nombre'] = itemEncontrado!['nombre'];
          _componentes[index]['reseta'] = itemEncontrado['reseta'];

          (_componentes[index]['resetaController'] as TextEditingController)
                  .text =
              (itemEncontrado['reseta'] as num?)?.toStringAsFixed(2) ?? '0.00';

          // Si el QR traía valor, sobreescribe el campo
          if (valor != null) {
            (_componentes[index]['valorRealController']
                    as TextEditingController)
                .text = valor!.toStringAsFixed(2);
          }
        });

        _calcularDiferenciaIndividual(index);

        _showSnack(
          valor != null
              ? '✅ ${itemEncontrado['nombre']} → ${valor.toStringAsFixed(2)}'
              : '✅ ${itemEncontrado['nombre']} (ingresa el valor real)',
        );
        return;
      } else {
        debugPrint(
            '⚠️ Componente "$nombreComponente" NO está en el catálogo actual');
        _showSnack(
          'El componente "$nombreComponente" no está en la lista del modelo',
        );
        return;
      }
    }

    // ─── 6) Fallback: solo rellenar valor ───
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
      _showSnack('QR inválido: "$contenido"');
    }
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> _guardarCalculo() async {
    final List<Map<String, dynamic>> componentesParaGuardar = [];
    double diferenciaTotal = 0.0;

    for (var comp in _componentes) {
      final nombre = comp['nombre'] as String?;
      if (nombre == null || nombre.isEmpty) continue;

      final valorRealTexto =
          (comp['valorRealController'] as TextEditingController).text.trim();
      final valorReal = double.tryParse(valorRealTexto);
      final reseta = double.tryParse(comp['reseta'].toString()) ?? 0.0;

      if (valorReal == null || valorReal <= 0) continue;

      diferenciaTotal += (valorReal - reseta);

      componentesParaGuardar.add({
        'nombre': nombre,
        'reseta': reseta,
        'valor_real': valorReal,
      });
    }

    if (componentesParaGuardar.isEmpty) {
      _showSnack('Ingresa al menos un Valor Real válido (mayor a 0)');
      return;
    }

    try {
      final calculoNuevo = Calculo(
        idVehiculo: widget.idVehiculo,
        diferencia: diferenciaTotal.toStringAsFixed(2),
        createdAt: DateTime.now(),
      );

      await db.guardarCalculoCompleto(calculoNuevo, componentesParaGuardar);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al guardar: $e');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
        title: Text(
          'Nuevo cálculo: ${widget.nombreVehiculo}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                onPressed: _agregarComponente,
                icon: const Icon(Icons.add),
                tooltip: 'Agregar componente',
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

  // ============================================================
  // ENCABEZADO COMPACTO
  // ============================================================

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.list_alt, size: 16, color: Colors.grey),
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_componentes.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE COMPONENTE
  // ============================================================

  Widget _buildComponenteRow(int index) {
    final componente = _componentes[index];
    final nombreActual = componente['nombre'] as String?;

    final bool nombreValido = catalogo.any(
      (item) => item['nombre'] == nombreActual,
    );
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
            // FILA 1: Número + Eliminar
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

            // FILA 2: Dropdown
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
                    return catalogo.map<Widget>((item) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item['nombre'] as String,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList();
                  },
                  items: catalogo.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['nombre'] as String,
                      child: SizedBox(
                        width: 300,
                        child: Text(
                          item['nombre'] as String,
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

                    final item = catalogo.firstWhere(
                      (c) => c['nombre'] == valorSeleccionado,
                      orElse: () =>
                          {'nombre': valorSeleccionado, 'reseta': 0.0},
                    );

                    setState(() {
                      componente['nombre'] = valorSeleccionado;
                      componente['reseta'] = item['reseta'];
                      (componente['resetaController'] as TextEditingController)
                              .text =
                          (item['reseta'] as num?)?.toStringAsFixed(2) ??
                              '0.00';
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

            // FILA 3: Reseta | Valor Real | Diferencia
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                Expanded(
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
                const SizedBox(width: 8),
                Expanded(
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
                        componente['diferencia'] ?? '0.00',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
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

            // FILA 4: Botón QR
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
