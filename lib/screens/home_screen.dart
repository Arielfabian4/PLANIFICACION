import 'package:flutter/material.dart';
import 'package:vehiculos_app/models/vehiculo.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/screens/inventario_screen.dart';
import 'package:vehiculos_app/screens/consumo_screen.dart';
import 'package:vehiculos_app/screens/unidades_por_hora_screen.dart';
import 'package:vehiculos_app/screens/resumen_flota_screen.dart';
import 'package:vehiculos_app/screens/lote_detalle_screen.dart';
import 'package:vehiculos_app/screens/camaras_screen.dart';
import 'package:vehiculos_app/screens/resumen_dia_screen.dart'; // ✅ NUEVO
import 'package:vehiculos_app/data/recetas_service.dart';
import 'package:vehiculos_app/data/datos_modelos.dart';
import 'package:vehiculos_app/data/productos_service.dart';

// ============================================================
// 🏎️ TEMA AUTOMOTRIZ
// ============================================================
class AutomotiveTheme {
  static const Color carbonDark = Color(0xFF0D1117);
  static const Color carbonLight = Color(0xFF161B22);
  static const Color carbonSurface = Color(0xFF1A1F26);
  static const Color racingRed = Color(0xFFE63946);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color electricBlue = Color(0xFF1E90FF);
  static const Color chromeSilver = Color(0xFFB0BEC5);
  static const Color asphaltGray = Color(0xFF2A2F36);
  static const Color dashGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color purpleAccent = Color(0xFF9C27B0);

  static const LinearGradient racingGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient carbonGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF1F2630)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient speedGradient = LinearGradient(
    colors: [Color(0xFF1E90FF), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

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

  Map<String, List<Vehiculo>> _lotes = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _cargarProductosIniciales();
    _loadVehiculos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      final Map<String, List<Vehiculo>> agrupados = {};
      for (final v in vehiculos) {
        final key = (v.lote == null || v.lote!.trim().isEmpty)
            ? 'Sin lote'
            : v.lote!.trim();
        agrupados.putIfAbsent(key, () => []).add(v);
      }

      final productos = await ProductosService.obtenerTodos();

      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
        _lotes = agrupados;
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
  // FILTRAR LOTES
  // ============================================================
  Map<String, List<Vehiculo>> _lotesFiltrados() {
    if (_searchQuery.trim().isEmpty) return _lotes;

    final query = _searchQuery.trim().toLowerCase();
    final Map<String, List<Vehiculo>> filtrados = {};

    _lotes.forEach((nombreLote, vehiculos) {
      final coincideLote = nombreLote.toLowerCase().contains(query);
      final vehiculosCoincidentes = vehiculos.where((v) {
        final modelo = v.modelo.toLowerCase();
        final codigo = (v.codigo ?? '').toLowerCase();
        return modelo.contains(query) || codigo.contains(query);
      }).toList();

      if (coincideLote) {
        filtrados[nombreLote] = vehiculos;
      } else if (vehiculosCoincidentes.isNotEmpty) {
        filtrados[nombreLote] = vehiculosCoincidentes;
      }
    });

    return filtrados;
  }

  // ============================================================
  // NAVEGAR A DETALLE DE LOTE
  // ============================================================
  void _abrirLote(String nombreLote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoteDetalleScreen(
          lote: nombreLote == 'Sin lote' ? null : nombreLote,
        ),
      ),
    ).then((_) => _loadVehiculos());
  }

  // ============================================================
  // 🗑️ ELIMINAR LOTE COMPLETO
  // ============================================================
  Future<void> _eliminarLote(
      String nombreLote, List<Vehiculo> vehiculos) async {
    final esSinLote = nombreLote == 'Sin lote';
    final total = vehiculos.length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _buildAutoDialog(
        title: 'ELIMINAR LOTE',
        icon: Icons.delete_forever,
        accent: AutomotiveTheme.racingRed,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AutomotiveTheme.racingRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AutomotiveTheme.racingRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AutomotiveTheme.racingRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      esSinLote
                          ? 'Vas a eliminar todos los vehículos sin lote.'
                          : 'Vas a eliminar el lote completo y todos sus vehículos.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AutomotiveTheme.asphaltGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AutomotiveTheme.asphaltGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esSinLote ? 'SIN LOTE' : nombreLote.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total ${total == 1 ? 'vehículo' : 'vehículos'} serán eliminados',
                    style: const TextStyle(
                      color: AutomotiveTheme.chromeSilver,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Esta acción no se puede deshacer.',
              style: TextStyle(
                color: AutomotiveTheme.racingRed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AutomotiveTheme.chromeSilver)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('ELIMINAR',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AutomotiveTheme.racingRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      int eliminados = 0;
      for (final v in vehiculos) {
        if (v.idVehiculo != null) {
          await _db.deleteVehiculo(v.idVehiculo!);
          eliminados++;
        }
      }

      await _loadVehiculos();

      _showSnackBar(
        esSinLote
            ? '$eliminados ${eliminados == 1 ? 'vehículo sin lote' : 'vehículos sin lote'} eliminado${eliminados == 1 ? '' : 's'}'
            : 'Lote "$nombreLote" eliminado ($eliminados ${eliminados == 1 ? 'vehículo' : 'vehículos'})',
        icon: Icons.check_circle,
        color: AutomotiveTheme.dashGreen,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _showSnackBar('Error al eliminar: $e',
          icon: Icons.error, color: AutomotiveTheme.racingRed);
    }
  }

  // ============================================================
  // MENÚ FAB — estilo racing
  // ============================================================
  void _mostrarMenuNuevo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: AutomotiveTheme.carbonGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AutomotiveTheme.racingRed, width: 3),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: AutomotiveTheme.racingGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AutomotiveTheme.racingGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.bolt, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NUEVO REGISTRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AutomotiveTheme.asphaltGray, height: 1),
              _buildMenuItem(
                icon: Icons.directions_car_filled,
                color: AutomotiveTheme.electricBlue,
                title: 'Vehículo individual',
                subtitle: 'Selecciona un modelo',
                onTap: () {
                  Navigator.pop(ctx);
                  _agregarVehiculo();
                },
              ),
              _buildMenuItem(
                icon: Icons.playlist_add,
                color: AutomotiveTheme.dashGreen,
                title: 'Registro por lotes',
                subtitle: 'Modelo + cantidad + nombre del lote',
                onTap: () {
                  Navigator.pop(ctx);
                  _agregarVehiculosPorLotes();
                },
              ),
              _buildMenuItem(
                icon: Icons.add_circle_outline,
                color: AutomotiveTheme.warningAmber,
                title: 'Nuevo modelo + receta',
                subtitle: 'Crear modelo con componentes',
                onTap: () {
                  Navigator.pop(ctx);
                  _agregarNuevoModelo();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AutomotiveTheme.chromeSilver,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: color.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AGREGAR VEHÍCULO (individual)
  // ============================================================
  Future<void> _agregarVehiculo() async {
    String? modeloSeleccionado;
    String? loteSeleccionado;
    String? codigoPreview;
    bool cargandoCodigo = false;
    final loteController = TextEditingController();

    final lotesExistentes = _lotes.keys.where((k) => k != 'Sin lote').toList();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => _buildAutoDialog(
          title: 'NUEVO VEHÍCULO',
          icon: Icons.directions_car_filled,
          accent: AutomotiveTheme.electricBlue,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAutoDropdown<String>(
                  value: modeloSeleccionado,
                  label: 'Modelo',
                  icon: Icons.airport_shuttle,
                  hint: 'Selecciona un modelo',
                  items: _modelosDisponibles
                      .map((m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    setStateDialog(() {
                      modeloSeleccionado = value;
                      codigoPreview = null;
                      cargandoCodigo = true;
                    });
                    if (value != null) {
                      final c = await _db.generarSiguienteCodigo(
                        value,
                        lote: loteController.text.trim().isEmpty
                            ? null
                            : loteController.text.trim(),
                      );
                      if (!dialogContext.mounted) return;
                      setStateDialog(() {
                        codigoPreview = c;
                        cargandoCodigo = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (lotesExistentes.isNotEmpty) ...[
                  _buildAutoDropdown<String>(
                    value: loteSeleccionado,
                    label: 'Lote (opcional)',
                    icon: Icons.inventory_2_outlined,
                    hint: 'Selecciona un lote',
                    items: lotesExistentes
                        .map((l) => DropdownMenuItem<String>(
                              value: l,
                              child: Text(l,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) async {
                      setStateDialog(() {
                        loteSeleccionado = v;
                        if (v != null) loteController.text = v;
                        cargandoCodigo = true;
                      });
                      if (modeloSeleccionado != null) {
                        final c = await _db.generarSiguienteCodigo(
                          modeloSeleccionado!,
                          lote: v ?? loteController.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        setStateDialog(() {
                          codigoPreview = c;
                          cargandoCodigo = false;
                        });
                      } else {
                        setStateDialog(() => cargandoCodigo = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildAutoTextField(
                  controller: loteController,
                  label: 'O escribe un nuevo lote',
                  hint: 'Ej: Lote Enero 2026',
                  icon: Icons.edit_outlined,
                  onChanged: (v) {
                    if (v.isNotEmpty) {
                      setStateDialog(() => loteSeleccionado = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (cargandoCodigo)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AutomotiveTheme.racingRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generando código...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AutomotiveTheme.chromeSilver,
                        ),
                      ),
                    ],
                  )
                else if (codigoPreview != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          AutomotiveTheme.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            AutomotiveTheme.electricBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2,
                            size: 16, color: AutomotiveTheme.electricBlue),
                        const SizedBox(width: 8),
                        Text('CÓDIGO: ',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: AutomotiveTheme.chromeSilver)),
                        Text(
                          codigoPreview!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.electricBlue,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AutomotiveTheme.chromeSilver)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (modeloSeleccionado?.isNotEmpty ?? false) {
                  Navigator.pop(dialogContext, true);
                } else {
                  _showSnackBar('Selecciona un modelo',
                      icon: Icons.warning_amber,
                      color: AutomotiveTheme.warningAmber);
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('GUARDAR',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.racingRed,
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

    if (result == true && modeloSeleccionado != null) {
      final loteFinal = loteController.text.trim().isEmpty
          ? null
          : loteController.text.trim();
      final codigo = await _db.generarSiguienteCodigo(
        modeloSeleccionado!,
        lote: loteFinal,
      );
      await _guardarVehiculo(modeloSeleccionado!,
          codigo: codigo, lote: loteFinal);
    }
  }

  // ============================================================
  // REGISTRO POR LOTES
  // ============================================================
  Future<void> _agregarVehiculosPorLotes() async {
    final List<Map<String, dynamic>> lote = [];

    String? modeloSeleccionado;
    final cantidadController = TextEditingController(text: '1');
    final nombreLoteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          int totalUnidades = 0;
          for (final item in lote) {
            totalUnidades += (item['cantidad'] as int?) ?? 0;
          }

          return _buildAutoDialog(
            title: 'REGISTRO POR LOTES',
            icon: Icons.playlist_add,
            accent: AutomotiveTheme.dashGreen,
            maxWidth: 460,
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAutoTextField(
                      controller: nombreLoteController,
                      label: 'Nombre del lote',
                      hint: 'Ej: Lote Enero 2026',
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildAutoDropdown<String>(
                      value: modeloSeleccionado,
                      label: 'Modelo',
                      icon: Icons.directions_car,
                      hint: 'Selecciona un modelo',
                      items: _modelosDisponibles
                          .map((m) => DropdownMenuItem<String>(
                                value: m,
                                child: Text(m,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setStateDialog(() => modeloSeleccionado = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildAutoTextField(
                            controller: cantidadController,
                            label: 'Cantidad',
                            hint: 'Ej: 18',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final cantidad =
                                  int.tryParse(cantidadController.text.trim());
                              if (modeloSeleccionado == null) {
                                _showSnackBar('Selecciona un modelo',
                                    icon: Icons.warning_amber,
                                    color: AutomotiveTheme.warningAmber);
                                return;
                              }
                              if (cantidad == null || cantidad <= 0) {
                                _showSnackBar('Cantidad inválida',
                                    icon: Icons.warning_amber,
                                    color: AutomotiveTheme.warningAmber);
                                return;
                              }
                              setStateDialog(() {
                                final idx = lote.indexWhere(
                                    (e) => e['modelo'] == modeloSeleccionado);
                                if (idx >= 0) {
                                  lote[idx] = {
                                    'modelo': modeloSeleccionado,
                                    'cantidad': (lote[idx]['cantidad'] as int) +
                                        cantidad,
                                  };
                                } else {
                                  lote.add({
                                    'modelo': modeloSeleccionado,
                                    'cantidad': cantidad,
                                  });
                                }
                                modeloSeleccionado = null;
                                cantidadController.text = '1';
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('AGREGAR',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AutomotiveTheme.dashGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                        color: AutomotiveTheme.asphaltGray, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.list_alt,
                            size: 16, color: AutomotiveTheme.dashGreen),
                        const SizedBox(width: 6),
                        const Text('LOTE ACTUAL',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AutomotiveTheme.dashGreen
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AutomotiveTheme.dashGreen
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '$totalUnidades ${totalUnidades == 1 ? 'UNIDAD' : 'UNIDADES'}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.dashGreen,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (lote.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AutomotiveTheme.asphaltGray
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AutomotiveTheme.asphaltGray,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 32, color: Colors.grey.shade600),
                            const SizedBox(height: 6),
                            Text(
                              'Aún no has agregado modelos',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(lote.length, (i) {
                        final item = lote[i];
                        final modelo = item['modelo'] as String;
                        final cant = item['cantidad'] as int;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AutomotiveTheme.dashGreen
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AutomotiveTheme.dashGreen
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car,
                                  size: 18, color: AutomotiveTheme.dashGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(modelo,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AutomotiveTheme.carbonDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AutomotiveTheme.dashGreen
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Text('×$cant',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AutomotiveTheme.dashGreen)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AutomotiveTheme.racingRed),
                                onPressed: () {
                                  setStateDialog(() => lote.removeAt(i));
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
                child: const Text('Cancelar',
                    style: TextStyle(color: AutomotiveTheme.chromeSilver)),
              ),
              ElevatedButton.icon(
                onPressed: lote.isEmpty
                    ? null
                    : () {
                        final nombreLote = nombreLoteController.text.trim();
                        if (nombreLote.isEmpty) {
                          _showSnackBar('Ingresa un nombre para el lote',
                              icon: Icons.warning_amber,
                              color: AutomotiveTheme.warningAmber);
                          return;
                        }
                        Navigator.pop(dialogContext, true);
                      },
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  lote.isEmpty ? 'GUARDAR' : 'GUARDAR $totalUnidades',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AutomotiveTheme.dashGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && lote.isNotEmpty) {
      final nombreLote = nombreLoteController.text.trim();
      final List<Map<String, String>> items = [];
      for (final item in lote) {
        final modelo = item['modelo'] as String;
        final cant = item['cantidad'] as int;
        final codigos = await _db.generarCodigosLote(
          modelo,
          cant,
          lote: nombreLote,
        );
        for (final c in codigos) {
          items.add({'modelo': modelo, 'codigo': c, 'lote': nombreLote});
        }
      }
      await _guardarVehiculosPorLotes(items);
    }
  }

  Future<void> _guardarVehiculosPorLotes(
      List<Map<String, String>> items) async {
    if (items.isEmpty) return;
    try {
      await _db.insertVehiculosConCodigo(items);
      await _loadVehiculos();

      final nombreLote = items.first['lote'] ?? '';
      _showSnackBar(
        '${items.length} ${items.length == 1 ? 'vehículo' : 'vehículos'} en "$nombreLote"',
        icon: Icons.check_circle,
        color: AutomotiveTheme.dashGreen,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _showSnackBar('Error al guardar: $e',
          icon: Icons.error, color: AutomotiveTheme.racingRed);
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
        builder: (context, setStateDialog) => _buildAutoDialog(
          title: 'NUEVO MODELO + RECETA',
          icon: Icons.add_circle_outline,
          accent: AutomotiveTheme.warningAmber,
          maxWidth: 460,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAutoTextField(
                    controller: modeloController,
                    label: 'Nombre del modelo',
                    hint: 'Ej: TOYOTA HILUX 2.8',
                    icon: Icons.directions_car,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 18, color: AutomotiveTheme.warningAmber),
                      const SizedBox(width: 6),
                      const Text('RECETA DEL MODELO',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: Colors.white)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _agregarComponenteAReceta(
                            dialogContext, recetaTemporal, setStateDialog),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('AÑADIR',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        style: TextButton.styleFrom(
                          foregroundColor: AutomotiveTheme.warningAmber,
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
                        color:
                            AutomotiveTheme.asphaltGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AutomotiveTheme.asphaltGray),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Colors.grey.shade600, size: 32),
                          const SizedBox(height: 6),
                          Text('Sin componentes',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
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
                          color: AutomotiveTheme.warningAmber
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AutomotiveTheme.warningAmber
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nombre'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('Cantidad: ${item['reseta']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AutomotiveTheme.warningAmber,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AutomotiveTheme.racingRed),
                              onPressed: () {
                                setStateDialog(
                                    () => recetaTemporal.removeAt(i));
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
              child: const Text('Cancelar',
                  style: TextStyle(color: AutomotiveTheme.chromeSilver)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final nombre = modeloController.text.trim().toUpperCase();
                if (nombre.isEmpty) {
                  _showSnackBar('Ingresa un nombre para el modelo',
                      icon: Icons.warning_amber,
                      color: AutomotiveTheme.warningAmber);
                  return;
                }
                if (_modelosDisponibles.contains(nombre)) {
                  _showSnackBar('Este modelo ya existe',
                      icon: Icons.warning_amber,
                      color: AutomotiveTheme.warningAmber);
                  return;
                }
                if (recetaTemporal.isEmpty) {
                  _showSnackBar('Agrega al menos un componente',
                      icon: Icons.warning_amber,
                      color: AutomotiveTheme.warningAmber);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('GUARDAR',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.warningAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
      final codigo = await _db.generarSiguienteCodigo(modelo);
      await _guardarVehiculo(modelo, codigo: codigo);
      _showSnackBar(
        'Modelo "$modelo" creado',
        icon: Icons.check_circle,
        color: AutomotiveTheme.dashGreen,
      );
    }
  }

  // ============================================================
  // EDITAR RECETA
  // ============================================================
  Future<void> _editarRecetaModelo() async {
    final modeloSeleccionado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: AutomotiveTheme.carbonGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AutomotiveTheme.warningAmber, width: 3),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AutomotiveTheme.warningAmber,
                      AutomotiveTheme.neonOrange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AutomotiveTheme.warningAmber
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AutomotiveTheme.warningAmber
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.edit_note,
                          color: AutomotiveTheme.warningAmber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SELECCIONA EL MODELO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AutomotiveTheme.asphaltGray, height: 1),
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
                            ? AutomotiveTheme.dashGreen
                            : AutomotiveTheme.electricBlue,
                      ),
                      title: Text(modelo,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AutomotiveTheme.chromeSilver),
                      onTap: () => Navigator.pop(ctx, modelo),
                    );
                  },
                ),
              ),
            ],
          ),
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
        builder: (context, setStateDialog) => _buildAutoDialog(
          title: 'EDITAR RECETA',
          subtitle: modelo,
          icon: Icons.edit_note,
          accent: AutomotiveTheme.warningAmber,
          maxWidth: 460,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 18, color: AutomotiveTheme.warningAmber),
                      const SizedBox(width: 6),
                      const Text('COMPONENTES',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: Colors.white)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _agregarComponenteAReceta(
                            dialogContext, receta, setStateDialog),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('AÑADIR',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        style: TextButton.styleFrom(
                          foregroundColor: AutomotiveTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (receta.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            AutomotiveTheme.asphaltGray.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Sin componentes',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    )
                  else
                    ...List.generate(receta.length, (i) {
                      final item = receta[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AutomotiveTheme.warningAmber
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AutomotiveTheme.warningAmber
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nombre'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  Text('Cantidad: ${item['reseta']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AutomotiveTheme.warningAmber,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AutomotiveTheme.neonOrange),
                              onPressed: () => _editarCantidadComponente(
                                  dialogContext, receta, i, setStateDialog),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AutomotiveTheme.racingRed),
                              onPressed: () =>
                                  setStateDialog(() => receta.removeAt(i)),
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
              child: const Text('Cancelar',
                  style: TextStyle(color: AutomotiveTheme.chromeSilver)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (receta.isEmpty) {
                  _showSnackBar('La receta no puede quedar vacía',
                      icon: Icons.warning_amber,
                      color: AutomotiveTheme.warningAmber);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('GUARDAR',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.warningAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await RecetasService.guardarReceta(modelo, receta);
      _showSnackBar('Receta de "$modelo" actualizada',
          icon: Icons.check_circle, color: AutomotiveTheme.dashGreen);
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
      builder: (ctx) => _buildAutoDialog(
        title: 'EDITAR CANTIDAD',
        icon: Icons.numbers,
        accent: AutomotiveTheme.neonOrange,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item['nombre'],
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 12),
            _buildAutoTextField(
              controller: controller,
              label: 'Nueva cantidad',
              icon: Icons.numbers,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AutomotiveTheme.chromeSilver)),
          ),
          ElevatedButton(
            onPressed: () {
              final nueva = double.tryParse(controller.text.trim());
              if (nueva == null || nueva <= 0) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.neonOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('GUARDAR',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final nueva = double.parse(controller.text.trim());
      setStateDialog(() {
        receta[index] = {'nombre': item['nombre'], 'reseta': nueva};
      });
    }
  }

  Future<void> _agregarComponenteAReceta(
    BuildContext dialogContext,
    List<Map<String, dynamic>> receta,
    StateSetter setStateDialog,
  ) async {
    String? componenteSeleccionado;
    bool esPersonalizado = false;
    final personalizadoController = TextEditingController();
    final cantidadController = TextEditingController();

    final usados = receta.map((e) => e['nombre'] as String).toSet();
    final disponibles =
        _componentesDisponibles.where((c) => !usados.contains(c)).toList();

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateInner) => _buildAutoDialog(
          title: 'NUEVO COMPONENTE',
          icon: Icons.add_box_outlined,
          accent: AutomotiveTheme.electricBlue,
          maxWidth: 400,
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateInner(() => esPersonalizado = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !esPersonalizado
                                  ? AutomotiveTheme.electricBlue
                                      .withValues(alpha: 0.2)
                                  : AutomotiveTheme.asphaltGray
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !esPersonalizado
                                    ? AutomotiveTheme.electricBlue
                                    : AutomotiveTheme.asphaltGray,
                              ),
                            ),
                            child: Text('DE LA LISTA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: !esPersonalizado
                                        ? Colors.white
                                        : AutomotiveTheme.chromeSilver,
                                    fontSize: 10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateInner(() => esPersonalizado = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: esPersonalizado
                                  ? AutomotiveTheme.electricBlue
                                      .withValues(alpha: 0.2)
                                  : AutomotiveTheme.asphaltGray
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: esPersonalizado
                                    ? AutomotiveTheme.electricBlue
                                    : AutomotiveTheme.asphaltGray,
                              ),
                            ),
                            child: Text('ESCRIBIR OTRO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: esPersonalizado
                                        ? Colors.white
                                        : AutomotiveTheme.chromeSilver,
                                    fontSize: 10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!esPersonalizado)
                    _buildAutoDropdown<String>(
                      value: componenteSeleccionado,
                      label: 'Componente',
                      icon: Icons.category_outlined,
                      hint: 'Selecciona',
                      items: disponibles
                          .map((c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setStateInner(() => componenteSeleccionado = v),
                    )
                  else
                    _buildAutoTextField(
                      controller: personalizadoController,
                      label: 'Nombre',
                      icon: Icons.edit,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  const SizedBox(height: 12),
                  _buildAutoTextField(
                    controller: cantidadController,
                    label: 'Cantidad',
                    icon: Icons.numbers,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AutomotiveTheme.chromeSilver)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final cantidad =
                    double.tryParse(cantidadController.text.trim());
                final nombre = esPersonalizado
                    ? personalizadoController.text.trim().toUpperCase()
                    : componenteSeleccionado;
                if (nombre == null || nombre.isEmpty || cantidad == null) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('AGREGAR',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.electricBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
        receta.add({'nombre': nombre, 'reseta': cantidad});
      });
    }
  }

  // ============================================================
  // PRODUCTOS
  // ============================================================
  Future<void> _verProductos() async {
    final productos = await ProductosService.obtenerTodos();
    if (!mounted) return;
    setState(() => _componentesDisponibles = productos);

    await ProductosService.obtenerPersonalizados();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AutomotiveTheme.carbonGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF9C27B0), width: 3),
              ),
            ),
            child: DraggableScrollableSheet(
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
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                          ),
                          borderRadius: BorderRadius.circular(3),
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
                                color: const Color(0xFF9C27B0)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF9C27B0)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: Color(0xFF9C27B0), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CATÁLOGO DE PRODUCTOS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 1.5,
                                          color: Colors.white)),
                                  Text('${productos.length} productos',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AutomotiveTheme.chromeSilver)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          color: AutomotiveTheme.asphaltGray, height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: productos.length,
                          itemBuilder: (context, i) {
                            final p = productos[i];
                            final esP = ProductosService.esPersonalizado(p);
                            return ListTile(
                              leading: Icon(
                                esP ? Icons.star : Icons.inventory_2,
                                color: esP
                                    ? const Color(0xFF9C27B0)
                                    : AutomotiveTheme.electricBlue,
                              ),
                              title: Text(p,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white)),
                              trailing: esP
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AutomotiveTheme.racingRed,
                                          size: 20),
                                      onPressed: () async {
                                        await ProductosService.eliminarProducto(
                                            p);
                                        if (!bottomSheetContext.mounted) return;
                                        Navigator.pop(bottomSheetContext);
                                        _verProductos();
                                      },
                                    )
                                  : null,
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
                            bottomSheetContext);
                        if (creado == true && bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                          _verProductos();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('NUEVO',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, letterSpacing: 1)),
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _crearProductoDesdeBottomSheet(
      BuildContext bottomSheetContext) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: bottomSheetContext,
      builder: (dialogContext) => _buildAutoDialog(
        title: 'NUEVO PRODUCTO',
        icon: Icons.add_box_outlined,
        accent: const Color(0xFF9C27B0),
        content: _buildAutoTextField(
          controller: controller,
          label: 'Nombre',
          icon: Icons.edit,
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AutomotiveTheme.chromeSilver)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('GUARDAR',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
        if (mounted) setState(() => _componentesDisponibles = productos);
        _showSnackBar('Producto agregado',
            icon: Icons.check_circle, color: AutomotiveTheme.dashGreen);
        return true;
      } else {
        _showSnackBar('Ya existe',
            icon: Icons.warning_amber, color: AutomotiveTheme.warningAmber);
        return false;
      }
    }
    return null;
  }

  // ============================================================
  // GUARDAR VEHÍCULO
  // ============================================================
  Future<void> _guardarVehiculo(String modelo,
      {String? codigo, String? lote}) async {
    try {
      await _db
          .insertVehiculo(Vehiculo(modelo: modelo, codigo: codigo, lote: lote));
      await _loadVehiculos();
      _showSnackBar(
        codigo != null ? 'Vehículo $codigo agregado' : 'Vehículo agregado',
        icon: Icons.check_circle,
        color: AutomotiveTheme.dashGreen,
      );
    } catch (e) {
      _showSnackBar('Error al guardar: $e',
          icon: Icons.error, color: AutomotiveTheme.racingRed);
    }
  }

  // ============================================================
  // HELPERS DE UI AUTOMOTRIZ
  // ============================================================
  Widget _buildAutoDialog({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color accent,
    required Widget content,
    required List<Widget> actions,
    double? maxWidth,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 420,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AutomotiveTheme.carbonGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: AutomotiveTheme.chromeSilver,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: content,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AutomotiveTheme.asphaltGray,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: AutomotiveTheme.racingRed,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: AutomotiveTheme.chromeSilver, fontSize: 12),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        prefixIcon: Icon(icon, color: AutomotiveTheme.chromeSilver, size: 20),
        filled: true,
        fillColor: AutomotiveTheme.asphaltGray.withValues(alpha: 0.5),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AutomotiveTheme.asphaltGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AutomotiveTheme.asphaltGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AutomotiveTheme.racingRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAutoDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AutomotiveTheme.carbonSurface,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      iconEnabledColor: AutomotiveTheme.chromeSilver,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: AutomotiveTheme.chromeSilver, fontSize: 12),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        prefixIcon: Icon(icon, color: AutomotiveTheme.chromeSilver, size: 20),
        filled: true,
        fillColor: AutomotiveTheme.asphaltGray.withValues(alpha: 0.5),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AutomotiveTheme.asphaltGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AutomotiveTheme.asphaltGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AutomotiveTheme.racingRed, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
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
          backgroundColor: AutomotiveTheme.carbonSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  (color ?? AutomotiveTheme.racingRed).withValues(alpha: 0.5),
            ),
          ),
        ),
      );
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

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AutomotiveTheme.carbonDark,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AutomotiveTheme.racingRed.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _mostrarMenuNuevo,
          tooltip: 'Nuevo',
          icon: const Icon(Icons.bolt, size: 24),
          label: const Text(
            'NUEVO',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: AutomotiveTheme.racingRed,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AutomotiveTheme.carbonLight,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AutomotiveTheme.carbonGradient,
          border: Border(
            bottom: BorderSide(color: AutomotiveTheme.racingRed, width: 3),
          ),
        ),
      ),
      title: _searchVisible
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: AutomotiveTheme.racingRed,
              decoration: InputDecoration(
                hintText: 'Buscar lote, modelo o código...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
              },
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AutomotiveTheme.racingGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AutomotiveTheme.racingRed.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MI FLOTA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
      actions: [
        if (_searchVisible && _searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: AutomotiveTheme.racingRed),
            tooltip: 'Limpiar',
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
        IconButton(
          icon: Icon(
            _searchVisible ? Icons.search_off : Icons.search,
            color: AutomotiveTheme.racingRed,
          ),
          tooltip: _searchVisible ? 'Cerrar buscador' : 'Buscar',
          onPressed: () {
            setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AutomotiveTheme.carbonDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: AutomotiveTheme.carbonGradient,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AutomotiveTheme.racingRed,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AutomotiveTheme.racingGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AutomotiveTheme.racingRed
                                  .withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.speed,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MI FLOTA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '${_vehiculos.length} UNIDADES ACTIVAS',
                              style: const TextStyle(
                                color: AutomotiveTheme.chromeSilver,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildHeaderStat(Icons.directions_car,
                          '${_vehiculos.length}', 'VEHÍCULOS'),
                      const SizedBox(width: 8),
                      _buildHeaderStat(
                          Icons.inventory_2, '${_lotes.length}', 'LOTES'),
                      const SizedBox(width: 8),
                      _buildHeaderStat(Icons.category,
                          '${_modelosDisponibles.length}', 'MODELOS'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildSectionTitle('// GESTIÓN'),
                  _buildHonorItem(
                    icon: Icons.add_circle_outline,
                    title: 'Ingresar nuevo modelo',
                    subtitle: 'Crear modelo + receta',
                    color: AutomotiveTheme.dashGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _agregarNuevoModelo();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.edit_note,
                    title: 'Editar receta de modelo',
                    subtitle: 'Agregar o eliminar componentes',
                    color: AutomotiveTheme.warningAmber,
                    onTap: () {
                      Navigator.pop(context);
                      _editarRecetaModelo();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.playlist_add,
                    title: 'Registro por lotes',
                    subtitle: 'Varios vehículos a la vez',
                    color: AutomotiveTheme.electricBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _agregarVehiculosPorLotes();
                    },
                  ),
                  _buildHonorItem(
                    icon: Icons.bar_chart,
                    title: 'Resumen de flota',
                    subtitle: 'Conteo por modelo',
                    color: AutomotiveTheme.dashGreen,
                    onTap: () => _navegarA(const ResumenFlotaScreen()),
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('// MÓDULOS'),
                  // ✅ NUEVO: Resumen del día
                  _buildHonorItem(
                    icon: Icons.today,
                    title: 'Resumen del día',
                    subtitle: 'Fluidos y unidades por día',
                    color: AutomotiveTheme.warningAmber,
                    onTap: () => _navegarA(const ResumenDiaScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.schedule_outlined,
                    title: 'Unidades por hora',
                    subtitle: 'Cálculo de rendimiento',
                    color: AutomotiveTheme.electricBlue,
                    onTap: () => _navegarA(const UnidadesPorHoraScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Consumo',
                    subtitle: 'Control de combustible',
                    color: AutomotiveTheme.neonOrange,
                    onTap: () => _navegarA(const ConsumoScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.inventory_outlined,
                    title: 'Inventario',
                    subtitle: 'Gestión de inventario',
                    color: const Color(0xFF5C6BC0),
                    onTap: () => _navegarA(const InventarioScreen()),
                  ),
                  _buildHonorItem(
                    icon: Icons.videocam_outlined,
                    title: 'Cámaras',
                    subtitle: 'Monitoreo visual',
                    color: AutomotiveTheme.racingRed,
                    onTap: () => _navegarA(const CamarasScreen()),
                  ),
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
                  _buildSectionTitle('// SISTEMA'),
                  _buildHonorItem(
                    icon: Icons.refresh,
                    title: 'Actualizar datos',
                    subtitle: 'Recargar información',
                    color: AutomotiveTheme.dashGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _loadVehiculos();
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AutomotiveTheme.asphaltGray,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AutomotiveTheme.racingRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AutomotiveTheme.racingRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.info_outline,
                        size: 14, color: AutomotiveTheme.racingRed),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'VERSIÓN 1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: AutomotiveTheme.chromeSilver,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AutomotiveTheme.racingRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AutomotiveTheme.racingRed, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AutomotiveTheme.chromeSilver,
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w900,
          color: AutomotiveTheme.racingRed,
          letterSpacing: 2,
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AutomotiveTheme.chromeSilver,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: color.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AutomotiveTheme.racingRed),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AutomotiveTheme.racingRed),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: const TextStyle(color: AutomotiveTheme.racingRed)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadVehiculos,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.racingRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_lotes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildLotesList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AutomotiveTheme.carbonGradient,
                border: Border.all(
                  color: AutomotiveTheme.racingRed.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AutomotiveTheme.racingRed.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.garage_outlined,
                size: 65,
                color: AutomotiveTheme.racingRed,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'GARAGE VACÍO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enciende el motor agregando tu primer vehículo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AutomotiveTheme.chromeSilver,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _mostrarMenuNuevo,
              icon: const Icon(Icons.bolt, size: 22),
              label: const Text(
                'ARRANCAR',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveTheme.racingRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: AutomotiveTheme.racingRed.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotesList() {
    final lotesFiltrados = _lotesFiltrados();

    final keys = lotesFiltrados.keys.toList()
      ..sort((a, b) {
        if (a == 'Sin lote') return 1;
        if (b == 'Sin lote') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final totalVehiculos =
        lotesFiltrados.values.fold<int>(0, (s, v) => s + v.length);

    final hayBusqueda = _searchQuery.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadVehiculos,
      color: AutomotiveTheme.racingRed,
      backgroundColor: AutomotiveTheme.carbonLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.carbonGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AutomotiveTheme.racingRed.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AutomotiveTheme.racingRed.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AutomotiveTheme.racingGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AutomotiveTheme.racingRed
                                .withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.garage_outlined,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hayBusqueda ? 'BÚSQUEDA ACTIVA' : 'PANEL DE FLOTA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lotesFiltrados.length} lotes · $totalVehiculos unidades',
                            style: const TextStyle(
                              color: AutomotiveTheme.chromeSilver,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AutomotiveTheme.speedGradient,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AutomotiveTheme.dashGreen
                                .withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalVehiculos > 0
                        ? (totalVehiculos / (totalVehiculos + 10))
                            .clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: AutomotiveTheme.asphaltGray,
                    valueColor:
                        const AlwaysStoppedAnimation(AutomotiveTheme.racingRed),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (lotesFiltrados.isEmpty && hayBusqueda) _buildSinResultados(),
          if (lotesFiltrados.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AutomotiveTheme.racingGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hayBusqueda ? 'COINCIDENCIAS' : 'SELECCIONA UN LOTE',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            ...keys.map((key) => _buildLoteCard(key, lotesFiltrados[key]!)),
          ],
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.carbonGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AutomotiveTheme.neonOrange.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AutomotiveTheme.neonOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 40,
              color: AutomotiveTheme.neonOrange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SIN COINCIDENCIAS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No se encontró "$_searchQuery" en la flota',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AutomotiveTheme.chromeSilver,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.refresh,
                size: 16, color: AutomotiveTheme.racingRed),
            label: const Text(
              'REINICIAR BÚSQUEDA',
              style: TextStyle(
                color: AutomotiveTheme.racingRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(String nombreLote, List<Vehiculo> vehiculos) {
    final esSinLote = nombreLote == 'Sin lote';
    final hayBusqueda = _searchQuery.trim().isNotEmpty;

    final coloresLote = [
      AutomotiveTheme.racingRed,
      AutomotiveTheme.neonOrange,
      AutomotiveTheme.electricBlue,
      AutomotiveTheme.dashGreen,
      AutomotiveTheme.warningAmber,
      const Color(0xFF9C27B0),
    ];
    final color = esSinLote
        ? AutomotiveTheme.chromeSilver
        : coloresLote[nombreLote.hashCode.abs() % coloresLote.length];

    final modelosUnicos = vehiculos.map((v) => v.modelo).toSet();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F26), Color(0xFF0F1318)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirLote(nombreLote),
          splashColor: color.withValues(alpha: 0.2),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.0),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          Icon(
                            esSinLote
                                ? Icons.help_outline
                                : Icons.directions_car_filled,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreLote.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _miniStat(
                                Icons.directions_car,
                                '${vehiculos.length}',
                                color,
                              ),
                              const SizedBox(width: 8),
                              _miniStat(
                                Icons.category_outlined,
                                '${modelosUnicos.length}',
                                color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ultimoCodigoBadge(vehiculos, color),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: hayBusqueda
                                ? vehiculos.take(3).map((v) {
                                    return _racingChip(
                                      '${v.codigo ?? ''} · ${v.modelo}',
                                      color,
                                    );
                                  }).toList()
                                : (modelosUnicos.take(2).map((m) {
                                    return _racingChip(m, color);
                                  }).toList()
                                  ..addAll(
                                    modelosUnicos.length > 2
                                        ? [
                                            _racingChip(
                                              '+${modelosUnicos.length - 2}',
                                              AutomotiveTheme.chromeSilver,
                                            )
                                          ]
                                        : [],
                                  )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionIconButton(
                          icon: Icons.delete_outline,
                          color: AutomotiveTheme.racingRed,
                          tooltip: 'Eliminar lote',
                          onTap: () => _eliminarLote(nombreLote, vehiculos),
                        ),
                        const SizedBox(height: 6),
                        _buildActionIconButton(
                          icon: Icons.arrow_forward_ios,
                          color: color,
                          tooltip: 'Abrir lote',
                          onTap: () => _abrirLote(nombreLote),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🏁 BADGE: ÚLTIMO CÓDIGO + SIGUIENTE SUGERIDO
  // ============================================================
  Widget _ultimoCodigoBadge(List<Vehiculo> vehiculos, Color color) {
    if (vehiculos.isEmpty) return const SizedBox.shrink();

    // Ordenar por createdAt desc para saber el último ingresado
    final ordenados = [...vehiculos]..sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    final ultimo = ordenados.first;
    final codigo = ultimo.codigo ?? '—';

    // Extraer número final del código (ej: LOTE60-031 → 31)
    final match = RegExp(r'(\d+)\s*$').firstMatch(codigo);
    final ultimoNum = match != null ? int.tryParse(match.group(1)!) : null;
    final siguiente = ultimoNum != null ? ultimoNum + 1 : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AutomotiveTheme.carbonDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ÚLTIMO: $codigo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (siguiente != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AutomotiveTheme.dashGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AutomotiveTheme.dashGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'SIGUE: $siguiente',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AutomotiveTheme.dashGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: color.withValues(alpha: 0.25),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _racingChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
