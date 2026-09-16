import 'package:flutter/material.dart';
import 'package:vehiculos_app/models/vehiculo.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/screens/calculos_vehiculo_screen.dart';
import 'package:vehiculos_app/screens/inventario_screen.dart';
import 'package:vehiculos_app/screens/consumo_screen.dart';
import 'package:vehiculos_app/screens/unidades_por_hora_screen.dart';
import 'package:vehiculos_app/data/recetas_service.dart';
import 'package:vehiculos_app/data/datos_modelos.dart';
import 'package:vehiculos_app/data/productos_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // CONSTANTES
  // ============================================================
  static const List<String> _modelosVehiculos = [
    'SWM G01',
    'SWM G01 F',
    'SWM G01F AC 1.5 TA',
    'SHINERAY X30L',
    'V3 VAN AC 1.5 4P 4X2 TM',
    'V7 VAN AC 1.6 4P 4X2 TM',
    'KYC_V7_CARGO_1.6_4X2',
    'F3 AC 1.6 CD 4X2 TM GAS',
    'F3 AC 2.0 CD 4X2 TM DIE',
    'POER AC 2.0 CD 4X4 TM DIE',
    'POER AC 2.0 CD 4X2 TM DIE',
    'WINGLE 7 DIESEL 4X2',
    'WINGLE 7 DIESEL 4X4',
    'WINGLE STEED AC 2.4',
  ];

  // ============================================================
  // ESTADO
  // ============================================================
  final DatabaseHelper _db = DatabaseHelper();
  List<Vehiculo> _vehiculos = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> _modelosDisponibles = List.from(_modelosVehiculos);
  List<String> _componentesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarProductosIniciales();
    _loadVehiculos();
  }

  Future<void> _cargarProductosIniciales() async {
    final productos = await ProductosService.obtenerTodos();
    if (!mounted) return;
    setState(() {
      _componentesDisponibles = productos;
    });
  }

  // ============================================================
  // LÓGICA DE DATOS
  // ============================================================
  Future<void> _loadVehiculos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehiculos = await _db.getAllVehiculos();
      vehiculos.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      final recetas = await RecetasService.obtenerTodas();
      for (final modelo in recetas.keys) {
        if (!_modelosDisponibles.contains(modelo)) {
          _modelosDisponibles.add(modelo);
        }
      }

      for (final v in vehiculos) {
        if (!_modelosDisponibles.contains(v.modelo)) {
          _modelosDisponibles.add(v.modelo);
        }
      }

      final productos = await ProductosService.obtenerTodos();

      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
        _componentesDisponibles = productos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error en _loadVehiculos: $e');
    }
  }

  // ============================================================
  // AGREGAR VEHÍCULO
  // ============================================================
  Future<void> _agregarVehiculo() async {
    String? modeloSeleccionado;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_filled,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nuevo Vehículo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: modeloSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.airport_shuttle),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                hint: const Text('Selecciona un modelo'),
                isExpanded: true,
                items: _modelosDisponibles
                    .map(
                      (modelo) => DropdownMenuItem<String>(
                        value: modelo,
                        child: Text(
                          modelo,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setStateDialog(() => modeloSeleccionado = value);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Selecciona el modelo para registrarlo en tu flota',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (modeloSeleccionado?.isNotEmpty ?? false) {
                  Navigator.pop(dialogContext, true);
                } else {
                  _showSnackBar(
                    'Por favor selecciona un modelo',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  );
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && modeloSeleccionado != null) {
      await _guardarVehiculo(modeloSeleccionado!);
    }
  }

  // ============================================================
  // CREAR NUEVO MODELO + RECETA
  // ============================================================
  Future<void> _agregarNuevoModelo() async {
    final TextEditingController modeloController = TextEditingController();
    final List<Map<String, dynamic>> recetaTemporal = [];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nuevo Modelo + Receta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: modeloController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Nombre del modelo',
                      hintText: 'Ej: TOYOTA HILUX 2.8',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.directions_car),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Receta del modelo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _agregarComponenteAReceta(
                          dialogContext,
                          recetaTemporal,
                          setStateDialog,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Añadir',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recetaTemporal.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 6),
                          Text(
                            'Sin componentes\nPresiona "Añadir" para agregar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(recetaTemporal.length, (i) {
                      final item = recetaTemporal[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nombre'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cantidad: ${item['reseta']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red.shade400),
                              onPressed: () {
                                setStateDialog(() {
                                  recetaTemporal.removeAt(i);
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final nombre = modeloController.text.trim().toUpperCase();
                if (nombre.isEmpty) {
                  _showSnackBar(
                    'Ingresa un nombre para el modelo',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  );
                  return;
                }
                if (_modelosDisponibles.contains(nombre)) {
                  _showSnackBar(
                    'Este modelo ya existe',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  );
                  return;
                }
                if (recetaTemporal.isEmpty) {
                  _showSnackBar(
                    'Agrega al menos un componente a la receta',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

    if (result == true) {
      final modelo = modeloController.text.trim().toUpperCase();

      await RecetasService.guardarReceta(modelo, recetaTemporal);

      if (!_modelosDisponibles.contains(modelo)) {
        _modelosDisponibles.add(modelo);
      }

      await _guardarVehiculo(modelo);

      _showSnackBar(
        'Modelo "$modelo" creado con ${recetaTemporal.length} componentes',
        icon: Icons.check_circle,
        color: Colors.green,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ============================================================
  // EDITAR RECETA DE UN MODELO EXISTENTE
  // ============================================================
  Future<void> _editarRecetaModelo() async {
    final modeloSeleccionado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Selecciona el modelo a editar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _modelosDisponibles.length,
                itemBuilder: (context, i) {
                  final modelo = _modelosDisponibles[i];
                  final esPersonalizado = !_modelosVehiculos.contains(modelo);

                  return ListTile(
                    leading: Icon(
                      esPersonalizado ? Icons.star : Icons.directions_car,
                      color: esPersonalizado
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                    title: Text(
                      modelo,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(ctx, modelo),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (modeloSeleccionado == null || !mounted) return;

    List<Map<String, dynamic>> recetaActual;

    if (_modelosVehiculos.contains(modeloSeleccionado)) {
      final personalizada =
          await RecetasService.obtenerReceta(modeloSeleccionado);
      if (personalizada.isNotEmpty) {
        recetaActual = personalizada;
      } else {
        recetaActual = List<Map<String, dynamic>>.from(
          DatosModelos.getComponentesPorModelo(modeloSeleccionado),
        );
      }
    } else {
      recetaActual = await RecetasService.obtenerReceta(modeloSeleccionado);
    }

    if (!mounted) return;
    await _mostrarEditorReceta(modeloSeleccionado, recetaActual);
  }

  Future<void> _mostrarEditorReceta(
    String modelo,
    List<Map<String, dynamic>> recetaInicial,
  ) async {
    final List<Map<String, dynamic>> receta = List<Map<String, dynamic>>.from(
      recetaInicial.map((e) => {...e}),
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note,
                    color: Colors.amber.shade800, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Editar receta',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      modelo,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Componentes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _agregarComponenteAReceta(
                          dialogContext,
                          receta,
                          setStateDialog,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Añadir',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (receta.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 6),
                          Text(
                            'Sin componentes\nPresiona "Añadir" para agregar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(receta.length, (i) {
                      final item = receta[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nombre'],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cantidad: ${item['reseta']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  size: 18, color: Colors.orange.shade700),
                              onPressed: () => _editarCantidadComponente(
                                dialogContext,
                                receta,
                                i,
                                setStateDialog,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Editar cantidad',
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red.shade400),
                              onPressed: () {
                                setStateDialog(() {
                                  receta.removeAt(i);
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (receta.isEmpty) {
                  _showSnackBar(
                    'La receta no puede quedar vacía',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
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

    if (result == true) {
      await RecetasService.guardarReceta(modelo, receta);

      _showSnackBar(
        'Receta de "$modelo" actualizada (${receta.length} componentes)',
        icon: Icons.check_circle,
        color: Colors.green,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _editarCantidadComponente(
    BuildContext dialogContext,
    List<Map<String, dynamic>> receta,
    int index,
    StateSetter setStateDialog,
  ) async {
    final item = receta[index];
    final controller = TextEditingController(
      text: (item['reseta'] as num?)?.toString() ?? '',
    );

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar cantidad', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['nombre'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Nueva cantidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.numbers),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nueva = double.tryParse(controller.text.trim());
              if (nueva == null || nueva <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa una cantidad válida'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final nueva = double.parse(controller.text.trim());
      setStateDialog(() {
        receta[index] = {
          'nombre': item['nombre'],
          'reseta': nueva,
        };
      });
    }
  }

  // ============================================================
  // DIÁLOGO DE NUEVO COMPONENTE
  // ============================================================
  Future<void> _agregarComponenteAReceta(
    BuildContext dialogContext,
    List<Map<String, dynamic>> receta,
    StateSetter setStateDialog,
  ) async {
    String? componenteSeleccionado;
    bool esPersonalizado = false;
    final TextEditingController personalizadoController =
        TextEditingController();
    final TextEditingController cantidadController = TextEditingController();

    final usados = receta.map((e) => e['nombre'] as String).toSet();
    final disponibles =
        _componentesDisponibles.where((c) => !usados.contains(c)).toList();

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_box_outlined,
                    color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Nuevo componente', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setStateInner(() => esPersonalizado = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !esPersonalizado
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !esPersonalizado
                                    ? [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'De la lista',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !esPersonalizado
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setStateInner(() => esPersonalizado = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: esPersonalizado
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: esPersonalizado
                                    ? [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Escribir otro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: esPersonalizado
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!esPersonalizado)
                    DropdownButtonFormField<String>(
                      initialValue: componenteSeleccionado,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Componente',
                        hintText: disponibles.isEmpty
                            ? 'No hay más componentes'
                            : 'Selecciona un componente',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.label_outline),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: disponibles
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateInner(() => componenteSeleccionado = value);
                      },
                    )
                  else
                    TextField(
                      controller: personalizadoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Nombre del componente',
                        hintText: 'Ej: ACEITE DE MOTOR 5W-40',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.edit_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad (reseta)',
                      hintText: 'Ej: 4.50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final cantidad =
                    double.tryParse(cantidadController.text.trim());
                final nombre = esPersonalizado
                    ? personalizadoController.text.trim().toUpperCase()
                    : componenteSeleccionado;

                if (nombre == null || nombre.isEmpty || cantidad == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Completa el componente y la cantidad correctamente'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

    if (ok == true) {
      final nombre = esPersonalizado
          ? personalizadoController.text.trim().toUpperCase()
          : componenteSeleccionado!;
      final cantidad = double.parse(cantidadController.text.trim());

      setStateDialog(() {
        receta.add({
          'nombre': nombre,
          'reseta': cantidad,
        });
      });
    }
  }

  // ============================================================
  // PRODUCTOS: VER + CREAR
  // ============================================================
  Future<void> _verProductos() async {
    final productos = await ProductosService.obtenerTodos();
    if (!mounted) return;

    setState(() {
      _componentesDisponibles = productos;
    });

    final personalizados = await ProductosService.obtenerPersonalizados();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Stack(
              children: [
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                color: Colors.purple.shade700, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Productos disponibles',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  '${productos.length} productos '
                                  '(${personalizados.length} personalizados)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          final esPersonalizado =
                              ProductosService.esPersonalizado(producto);

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: esPersonalizado
                                      ? Colors.purple.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  esPersonalizado
                                      ? Icons.star
                                      : Icons.inventory_2,
                                  color: esPersonalizado
                                      ? Colors.purple.shade700
                                      : Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                producto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: esPersonalizado
                                  ? Text(
                                      'PERSONALIZADO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    )
                                  : null,
                              trailing: esPersonalizado
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar producto',
                                      onPressed: () async {
                                        final confirmar =
                                            await showDialog<bool>(
                                          context: bottomSheetContext,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title:
                                                const Text('Eliminar producto'),
                                            content: Text(
                                              '¿Eliminar "$producto" del catálogo?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmar == true) {
                                          await ProductosService
                                              .eliminarProducto(producto);
                                          if (!bottomSheetContext.mounted) {
                                            return;
                                          }
                                          Navigator.pop(bottomSheetContext);
                                          _verProductos();
                                          _showSnackBar(
                                            'Producto eliminado',
                                            icon: Icons.delete,
                                            color: Colors.orange,
                                          );
                                        }
                                      },
                                    )
                                  : Icon(
                                      Icons.verified,
                                      color: Colors.blue.shade400,
                                      size: 18,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton.extended(
                    heroTag: 'fab_crear_producto_sheet',
                    onPressed: () async {
                      final creado = await _crearProductoDesdeBottomSheet(
                        bottomSheetContext,
                      );

                      if (creado == true && bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                        _verProductos();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo producto'),
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _crearProductoDesdeBottomSheet(
    BuildContext bottomSheetContext,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: bottomSheetContext,
      builder: (dialogContext) => AlertDialog(
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
              child:
                  Icon(Icons.add_box, color: Colors.purple.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nuevo Producto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                hintText: 'Ej: FILTRO DE ACEITE XYZ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se agregará al catálogo de componentes disponibles',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un nombre para el producto'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Guardar'),
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
    );

    if (result == true) {
      final nombre = controller.text.trim().toUpperCase();
      final agregado = await ProductosService.agregarProducto(nombre);

      if (!mounted) return null;

      if (agregado) {
        final productos = await ProductosService.obtenerTodos();
        if (mounted) {
          setState(() {
            _componentesDisponibles = productos;
          });
        }

        _showSnackBar(
          'Producto "$nombre" agregado',
          icon: Icons.check_circle,
          color: Colors.green,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        _showSnackBar(
          'El producto "$nombre" ya existe',
          icon: Icons.warning_amber,
          color: Colors.orange,
        );
        return false;
      }
    }

    return null;
  }

  Future<void> _guardarVehiculo(String modelo) async {
    try {
      await _db.insertVehiculo(Vehiculo(modelo: modelo));
      await _loadVehiculos();

      _showSnackBar(
        'Vehículo agregado correctamente',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'Error al guardar: $e',
        icon: Icons.error,
        color: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _eliminarVehiculo(Vehiculo vehiculo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Vehículo',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de eliminar este vehículo?'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vehiculo.modelo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Se eliminarán todos los cálculos asociados.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && vehiculo.idVehiculo != null) {
      await _confirmarEliminacion(vehiculo.idVehiculo!);
    }
  }

  Future<void> _confirmarEliminacion(int idVehiculo) async {
    try {
      final vehiculo = _vehiculos.firstWhere((v) => v.idVehiculo == idVehiculo);

      await _db.deleteVehiculo(idVehiculo);

      if (DatosModelos.esPersonalizado(vehiculo.modelo)) {
        final otros = _vehiculos
            .where((v) =>
                v.idVehiculo != idVehiculo && v.modelo == vehiculo.modelo)
            .toList();
        if (otros.isEmpty) {
          await RecetasService.eliminarReceta(vehiculo.modelo);
          _modelosDisponibles.remove(vehiculo.modelo);
        }
      }

      await _loadVehiculos();

      _showSnackBar(
        'Vehículo eliminado',
        icon: Icons.delete,
        color: Colors.orange,
      );
    } catch (e) {
      _showSnackBar(
        'Error: $e',
        icon: Icons.error,
        color: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  void _showSnackBar(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color ?? Colors.white),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================
  void _navegarA(Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navegarACalculos(Vehiculo vehiculo) {
    if (vehiculo.idVehiculo == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoCalculoScreen(
          idVehiculo: vehiculo.idVehiculo!,
          nombreVehiculo: vehiculo.modelo,
        ),
      ),
    ).then((_) => _loadVehiculos());
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarVehiculo,
        tooltip: 'Agregar vehículo',
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      title: const Row(
        children: [
          Icon(Icons.directions_car_filled, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Mi Flota',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER ESTILO HONOR
  // ============================================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF7F9FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ─── HEADER TIPO HONOR ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D3E8B), Color(0xFF2C5FBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mi Flota',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_vehiculos.length} ${_vehiculos.length == 1 ? 'vehículo activo' : 'vehículos activos'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mini stats dentro del header
                  Row(
                    children: [
                      _buildHeaderStat(
                        Icons.directions_car,
                        '${_vehiculos.length}',
                        'Vehículos',
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderStat(
                        Icons.list_alt,
                        '${_modelosDisponibles.length}',
                        'Modelos',
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderStat(
                        Icons.inventory_2_outlined,
                        '${_componentesDisponibles.length}',
                        'Productos',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── OPCIONES ───
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildSectionTitle('GESTIÓN DE VEHÍCULOS'),
                  _buildHonorItem(
                    icon: Icons.add_circle_outline,
                    title: 'Ingresar nuevo modelo',
                    subtitle: 'Crear modelo + receta completa',
                    color: const Color(0xFF3DDC84),
                    onTap: () {
                      Navigator.pop(context);
                      _agregarNuevoModelo();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.edit_note,
                    title: 'Editar receta de modelo',
                    subtitle: 'Agregar, editar o eliminar componentes',
                    color: const Color(0xFFFFB800),
                    onTap: () {
                      Navigator.pop(context);
                      _editarRecetaModelo();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.directions_car,
                    title: 'Agregar vehículo',
                    subtitle: 'Desde modelos existentes',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.pop(context);
                      _agregarVehiculo();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.list_alt,
                    title: 'Modelos disponibles',
                    subtitle: '${_modelosDisponibles.length} en catálogo',
                    color: const Color(0xFF7C4DFF),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarModelosDisponibles();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('PRODUCTOS'),
                  _buildHonorItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Productos creados',
                    subtitle: '${_componentesDisponibles.length} en catálogo',
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.pop(context);
                      _verProductos();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('MÓDULOS'),
                  _buildHonorItem(
                    icon: Icons.schedule_outlined,
                    title: 'Unidades por hora',
                    subtitle: 'Cálculo de rendimiento',
                    color: const Color(0xFF00BCD4),
                    onTap: () => _navegarA(const UnidadesPorHoraScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Consumo',
                    subtitle: 'Control de combustible',
                    color: const Color(0xFFFF7043),
                    onTap: () => _navegarA(const ConsumoScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.inventory_outlined,
                    title: 'Inventario',
                    subtitle: 'Gestión de inventario',
                    color: const Color(0xFF5C6BC0),
                    onTap: () => _navegarA(const InventarioScreen()),
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('SISTEMA'),
                  _buildHonorItem(
                    icon: Icons.refresh,
                    title: 'Actualizar datos',
                    subtitle: 'Recargar información',
                    color: const Color(0xFF26A69A),
                    onTap: () {
                      Navigator.pop(context);
                      _loadVehiculos();
                      _showSnackBar(
                        'Datos actualizados',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ─── FOOTER ───
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3E8B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFF1D3E8B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A6477),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Honor UI',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A849B),
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildHonorItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Ícono en burbuja
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A849B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOSTRAR MODELOS DISPONIBLES
  // ============================================================
  void _mostrarModelosDisponibles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.list_alt,
                        color: Colors.indigo.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modelos disponibles',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${_modelosDisponibles.length} modelos en catálogo',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _modelosDisponibles.length,
                itemBuilder: (context, index) {
                  final modelo = _modelosDisponibles[index];
                  final enUso = _vehiculos.any((v) => v.modelo == modelo);
                  final esPersonalizado = !_modelosVehiculos.contains(modelo);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _guardarVehiculo(modelo);
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: esPersonalizado
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          esPersonalizado ? Icons.star : Icons.directions_car,
                          color: esPersonalizado
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        modelo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          if (esPersonalizado)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PERSONALIZADO',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          if (enUso)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EN FLOTA',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_vehiculos.isEmpty) {
      return _buildEmptyState();
    }

    return _buildVehiculosList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadVehiculos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.garage_outlined,
                size: 60,
                color: primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu flota está vacía',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer vehículo para comenzar\na gestionar cálculos y consumo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _agregarVehiculo,
              icon: const Icon(Icons.add),
              label: const Text('Agregar vehículo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculosList() {
    return RefreshIndicator(
      onRefresh: _loadVehiculos,
      child: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: _vehiculos.length,
              itemBuilder: (context, index) {
                return _buildVehiculoCard(_vehiculos[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final total = _vehiculos.length;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.garage_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de flota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Estado actual de tus vehículos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total == 1 ? 'Vehículo' : 'Vehículos',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculoCard(Vehiculo vehiculo, int index) {
    final colores = [
      Colors.blue.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade700,
      Colors.deepPurple.shade600,
      Colors.cyan.shade800,
    ];
    final color = colores[index % colores.length];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navegarACalculos(vehiculo),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_filled,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EN FLOTA',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehiculo.modelo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    iconSize: 22,
                    onPressed: () => _eliminarVehiculo(vehiculo),
                    tooltip: 'Eliminar vehículo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (vehiculo.createdAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Registrado: ${_formatDate(vehiculo.createdAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navegarACalculos(vehiculo),
                  icon: const Icon(Icons.assessment_outlined, size: 18),
                  label: const Text('Ver Cálculos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
