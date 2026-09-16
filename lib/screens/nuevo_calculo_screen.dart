import 'package:flutter/material.dart';
import 'package:vehiculos_app/models/componente.dart';
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

  // Lista temporal de componentes (cada uno con su valor real y diferencia)
  List<Map<String, dynamic>> _componentes = [];

  // Catálogo dinámico: Solo los componentes de este modelo
  late List<Map<String, dynamic>> catalogo;

  @override
  void initState() {
    super.initState();

    // Cargar los datos del modelo
    catalogo = DatosModelos.getComponentesPorModelo(widget.nombreVehiculo);

    // Si el catálogo está vacío, cargamos una lista genérica
    if (catalogo.isEmpty) {
      catalogo = [
        {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.50},
        {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 1.60},
        {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 4.40},
      ];
    }

    // Agregar el primer componente con su controlador de valor real
    _componentes.add({
      'nombre': catalogo.first['nombre'],
      'reseta': catalogo.first['reseta'],
      'valorRealController': TextEditingController(),
      'diferencia': '0.00',
    });
  }

  void _calcularDiferenciaIndividual(int index) {
    double valorReal =
        double.tryParse(_componentes[index]['valorRealController'].text) ?? 0.0;
    double reseta =
        double.tryParse(_componentes[index]['reseta'].toString()) ?? 0.0;
    double diferencia = 0.0;
    if (valorReal > 0) {
      diferencia = valorReal - reseta;
    }
    setState(() {
      _componentes[index]['diferencia'] = diferencia.toStringAsFixed(2);
    });
  }

  void _agregarComponente() {
    setState(() {
      _componentes.add({
        'nombre': catalogo.first['nombre'],
        'reseta': catalogo.first['reseta'],
        'valorRealController': TextEditingController(),
        'diferencia': '0.00',
      });
    });
  }

  void _eliminarComponente(int index) {
    setState(() {
      _componentes[index]['valorRealController'].dispose();
      _componentes.removeAt(index);
    });
  }

  Future<void> _escanearQR(int index, bool esValorReal) async {
    final valorEscaneado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const EscanerQRScreen()),
    );

    if (valorEscaneado != null) {
      double? valorNumerico = double.tryParse(valorEscaneado);
      setState(() {
        if (esValorReal) {
          _componentes[index]['valorRealController'].text =
              valorNumerico?.toStringAsFixed(2) ?? valorEscaneado;
        } else {
          _componentes[index]['reseta'] = valorNumerico ?? valorEscaneado;
        }
      });
      _calcularDiferenciaIndividual(index);
    }
  }

  Future<void> _guardarCalculo() async {
    bool tieneValorReal = false;
    for (var comp in _componentes) {
      if (comp['valorRealController'].text.isNotEmpty) {
        tieneValorReal = true;
        break;
      }
    }

    if (!tieneValorReal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa al menos un Valor Real de un componente')),
      );
      return;
    }

    final componentesValidos =
        _componentes.where((c) => c['nombre'] != '').toList();
    if (componentesValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un componente')),
      );
      return;
    }

    try {
      // Calcular la diferencia total
      double diferenciaTotal = 0.0;
      for (var comp in _componentes) {
        double valorReal =
            double.tryParse(comp['valorRealController'].text) ?? 0.0;
        double reseta = double.tryParse(comp['reseta'].toString()) ?? 0.0;
        if (valorReal > 0) {
          diferenciaTotal += (valorReal - reseta);
        }
      }

      Calculo calculoNuevo = Calculo(
        idVehiculo: widget.idVehiculo,
        diferencia: diferenciaTotal.toStringAsFixed(2),
        createdAt: DateTime.now(),
      );

      int idCalculoGenerado = await db.insertCalculo(calculoNuevo);

      for (var comp in componentesValidos) {
        Componente nuevoComponente = Componente(
          idCalculo: idCalculoGenerado,
          nombre: comp['nombre'],
          reseta: comp['reseta'],
        );
        await db.insertComponente(nuevoComponente);

        double cantidadUsada =
            double.tryParse(comp['reseta'].toString()) ?? 0.0;
        await db.restarStock(comp['nombre'] as String, cantidadUsada);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo cálculo: ${widget.nombreVehiculo}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título Componentes
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

            // ENCABEZADOS EN LÍNEA HORIZONTAL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Nombre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Reseta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Valor Real',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Diferencia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // LISTA DE COMPONENTES
            ...List.generate(_componentes.length, (index) {
              final componente = _componentes[index];

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // NOMBRE - Dropdown
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: componente['nombre'] == ''
                                  ? null
                                  : componente['nombre'] as String?,
                              items: catalogo.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['nombre'] as String,
                                  child: Text(
                                    item['nombre'] as String,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (valorSeleccionado) {
                                if (valorSeleccionado == null) return;
                                setState(() {
                                  componente['nombre'] = valorSeleccionado;
                                  final item = catalogo.firstWhere(
                                    (c) => c['nombre'] == valorSeleccionado,
                                  );
                                  componente['reseta'] = item['reseta'];
                                });
                                _calcularDiferenciaIndividual(index);
                              },
                              hint: const Text(
                                'Seleccionar',
                                style: TextStyle(fontSize: 12),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // RESETA
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(
                            text: (componente['reseta'] as num?)
                                    ?.toStringAsFixed(2) ??
                                '',
                          ),
                          readOnly: true,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // VALOR REAL
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón QR arriba
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.qr_code_scanner, size: 18),
                                color: Colors.green,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 20,
                                ),
                                tooltip: 'Escanear Valor Real',
                                onPressed: () => _escanearQR(index, true),
                              ),
                            ),
                            // Campo de texto abajo
                            TextField(
                              controller: componente['valorRealController'],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                _calcularDiferenciaIndividual(index);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // DIFERENCIA
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(
                            text: componente['diferencia'] ?? '0.00',
                          ),
                          readOnly: true,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                      ),

                      // Botón eliminar
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        iconSize: 20,
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
                ),
              );
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
              child: ElevatedButton(
                onPressed: _guardarCalculo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Cálculo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
