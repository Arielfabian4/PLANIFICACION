import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/exportar_excel_helper.dart';

class ConsumoScreen extends StatefulWidget {
  const ConsumoScreen({super.key});

  @override
  State<ConsumoScreen> createState() => _ConsumoScreenState();
}

class _ConsumoScreenState extends State<ConsumoScreen> {
  final DatabaseHelper db = DatabaseHelper();
  final ExportarExcelHelper excelHelper = ExportarExcelHelper();

  List<Map<String, dynamic>> _calculos = [];
  List<Map<String, dynamic>> _calculosFiltrados = [];
  List<String> _vehiculos = [];

  // Totales
  List<Map<String, dynamic>> _totalesPorComponente = [];
  List<Map<String, dynamic>> _totalesPorVehiculo = [];
  List<Map<String, dynamic>> _consumoPorHora = [];
  int _tabSeleccionada = 0; // 0 = componente, 1 = vehículo, 2 = por hora

  Map<String, dynamic> _resumenGeneral = {
    'total_real': 0.0,
    'total_teorico': 0.0,
    'total_componentes': 0,
    'total_calculos': 0,
    'total_vehiculos': 0,
  };

  String _filtroVehiculo = 'Todos';
  bool _cargando = true;

  // Filtro por fecha
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  // Filtro por hora
  TimeOfDay? _horaDesde;
  TimeOfDay? _horaHasta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  DateTime? _combinarFechaHora(
    DateTime? fecha,
    TimeOfDay? hora, {
    required bool esInicio,
  }) {
    if (fecha == null && hora == null) return null;

    final base = fecha ?? DateTime.now();

    if (hora == null) {
      return esInicio
          ? DateTime(base.year, base.month, base.day, 0, 0, 0)
          : DateTime(base.year, base.month, base.day, 23, 59, 59);
    }
    return DateTime(base.year, base.month, base.day, hora.hour, hora.minute, 0);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final desdeCompleto = _combinarFechaHora(
        _fechaDesde,
        _horaDesde,
        esInicio: true,
      );
      final hastaCompleto = _combinarFechaHora(
        _fechaHasta,
        _horaHasta,
        esInicio: false,
      );

      final datos = await db.obtenerCalculosConVehiculoPorFechaHora(
        desde: desdeCompleto,
        hasta: hastaCompleto,
      );
      final resumen = await db.obtenerResumenGeneralConsumoPorFechaHora(
        desde: desdeCompleto,
        hasta: hastaCompleto,
      );
      final totalesComp = await db.obtenerTotalesPorComponentePorFechaHora(
        desde: desdeCompleto,
        hasta: hastaCompleto,
      );
      final totalesVeh = await db.obtenerTotalesPorVehiculoPorFechaHora(
        desde: desdeCompleto,
        hasta: hastaCompleto,
      );
      final porHora = await db.obtenerResumenPorHora(
        desde: desdeCompleto,
        hasta: hastaCompleto,
      );

      final vehiculosSet = <String>{};
      for (final c in datos) {
        final nombre = c['nombreVehiculo']?.toString();
        if (nombre != null && nombre.isNotEmpty) {
          vehiculosSet.add(nombre);
        }
      }

      if (!mounted) return;

      setState(() {
        _calculos = datos;
        _calculosFiltrados = _aplicarFiltroVehiculo(datos, _filtroVehiculo);
        _vehiculos = ['Todos', ...vehiculosSet.toList()..sort()];
        _resumenGeneral = resumen;
        _totalesPorComponente = totalesComp;
        _totalesPorVehiculo = totalesVeh;
        _consumoPorHora = porHora;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar: $e', esError: true);
    }
  }

  List<Map<String, dynamic>> _aplicarFiltroVehiculo(
    List<Map<String, dynamic>> datos,
    String filtro,
  ) {
    if (filtro == 'Todos') return datos;
    return datos.where((c) => c['nombreVehiculo'] == filtro).toList();
  }

  void _aplicarFiltro(String? valor) {
    if (valor == null) return;
    setState(() {
      _filtroVehiculo = valor;
      _calculosFiltrados = _aplicarFiltroVehiculo(_calculos, valor);
    });
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esDesde
          ? (_fechaDesde ?? DateTime.now())
          : (_fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: esDesde ? 'Selecciona fecha inicial' : 'Selecciona fecha final',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked == null) return;

    setState(() {
      if (esDesde) {
        _fechaDesde = picked;
        if (_fechaHasta != null && _fechaHasta!.isBefore(picked)) {
          _fechaHasta = picked;
        }
      } else {
        _fechaHasta = picked;
        if (_fechaDesde != null && _fechaDesde!.isAfter(picked)) {
          _fechaDesde = picked;
        }
      }
    });

    await _cargarDatos();
  }

  Future<void> _seleccionarHora(bool esDesde) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: esDesde
          ? (_horaDesde ?? const TimeOfDay(hour: 0, minute: 0))
          : (_horaHasta ?? const TimeOfDay(hour: 23, minute: 59)),
      helpText: esDesde ? 'Selecciona hora inicial' : 'Selecciona hora final',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked == null) return;

    setState(() {
      if (esDesde) {
        _horaDesde = picked;
      } else {
        _horaHasta = picked;
      }
    });

    await _cargarDatos();
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _horaDesde = null;
      _horaHasta = null;
    });
    _cargarDatos();
  }

  void _aplicarRangoRapido(String rango) {
    final ahora = DateTime.now();
    DateTime? desde;
    DateTime? hasta;

    switch (rango) {
      case 'Hoy':
        desde = DateTime(ahora.year, ahora.month, ahora.day);
        hasta = desde;
        break;
      case 'Semana':
        desde = ahora.subtract(const Duration(days: 7));
        hasta = ahora;
        break;
      case 'Mes':
        desde = DateTime(ahora.year, ahora.month, 1);
        hasta = ahora;
        break;
      case 'Año':
        desde = DateTime(ahora.year, 1, 1);
        hasta = ahora;
        break;
      case 'Todo':
        desde = null;
        hasta = null;
        break;
    }

    setState(() {
      _fechaDesde = desde;
      _fechaHasta = hasta;
      _horaDesde = null;
      _horaHasta = null;
    });
    _cargarDatos();
  }

  bool get _hayFiltroFecha =>
      _fechaDesde != null ||
      _fechaHasta != null ||
      _horaDesde != null ||
      _horaHasta != null;

  double get _diferenciaTotal {
    double total = 0.0;
    for (final c in _calculosFiltrados) {
      total += double.tryParse(c['diferencia']?.toString() ?? '0') ?? 0.0;
    }
    return total;
  }

  int get _cantidadCalculos => _calculosFiltrados.length;

  double get _totalReal =>
      (_resumenGeneral['total_real'] as num?)?.toDouble() ?? 0.0;
  double get _totalTeorico =>
      (_resumenGeneral['total_teorico'] as num?)?.toDouble() ?? 0.0;
  double get _diferenciaGeneral => _totalReal - _totalTeorico;

  String get _rangoFechasTexto {
    if (!_hayFiltroFecha) return 'Todo el historial';

    final desdeFecha = _fechaDesde != null
        ? DateFormat('dd/MM/yyyy').format(_fechaDesde!)
        : 'Inicio';
    final hastaFecha = _fechaHasta != null
        ? DateFormat('dd/MM/yyyy').format(_fechaHasta!)
        : 'Hoy';

    final desdeHora = _horaDesde != null
        ? ' ${_horaDesde!.hour.toString().padLeft(2, '0')}:${_horaDesde!.minute.toString().padLeft(2, '0')}'
        : '';
    final hastaHora = _horaHasta != null
        ? ' ${_horaHasta!.hour.toString().padLeft(2, '0')}:${_horaHasta!.minute.toString().padLeft(2, '0')}'
        : '';

    return '$desdeFecha$desdeHora → $hastaFecha$hastaHora';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Consumo realizado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // ✅ BOTÓN EXPORTAR A EXCEL
          IconButton(
            tooltip: 'Exportar a Excel',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: _mostrarDialogoExportar,
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFiltroFechaCard(),
                          const SizedBox(height: 16),
                          _buildResumenCard(),
                          const SizedBox(height: 16),
                          _buildConsumoGeneralCard(),
                          const SizedBox(height: 16),
                          _buildResumenEntradasSalidas(),
                          const SizedBox(height: 16),
                          _buildListadoTotales(),
                          const SizedBox(height: 16),
                          _buildFiltroCard(),
                          const SizedBox(height: 16),
                          _buildListaCalculos(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // EXPORTAR A EXCEL
  // ============================================================

  Future<void> _mostrarDialogoExportar() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.table_chart, color: Colors.green),
            SizedBox(width: 8),
            Text('Exportar a Excel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOpcionExportar(
              'Cálculos completos',
              'Historial con detalle por componente',
              Icons.calculate_outlined,
              Colors.orange,
              'calculos',
              dialogContext,
            ),
            _buildOpcionExportar(
              'Consumo por componente',
              'Totales acumulados por ítem',
              Icons.analytics_outlined,
              Colors.purple,
              'consumo',
              dialogContext,
            ),
            _buildOpcionExportar(
              'Reporte completo',
              'Todo en un solo archivo con varias hojas',
              Icons.description_outlined,
              Colors.red,
              'todo',
              dialogContext,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (opcion == null || !mounted) return;
    await _exportarYCompartir(opcion);
  }

  Widget _buildOpcionExportar(
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
    String valor,
    BuildContext dialogContext,
  ) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: color, size: 22),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.pop(dialogContext, valor),
    );
  }

  Future<void> _exportarYCompartir(String tipo) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Generando Excel...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      File? archivo;

      switch (tipo) {
        case 'calculos':
          archivo = await excelHelper.exportarCalculos();
          break;
        case 'consumo':
          archivo = await excelHelper.exportarConsumoPorComponente();
          break;
        case 'todo':
          archivo = await excelHelper.exportarTodo();
          break;
      }

      // Cerrar el diálogo de carga
      if (mounted) Navigator.pop(context);

      if (archivo == null) {
        _mostrarMensaje(
          'No hay datos para exportar',
          esError: true,
        );
        return;
      }

      // Compartir el archivo
      await excelHelper.compartirExcel(archivo);

      if (mounted) {
        _mostrarMensaje('✅ Excel generado y compartido');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarMensaje('Error al exportar: $e', esError: true);
    }
  }

  // ============================================================
  // FILTRO POR FECHA Y HORA
  // ============================================================

  Widget _buildFiltroFechaCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _hayFiltroFecha
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.date_range,
                    color: _hayFiltroFecha
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtrar por fecha y hora',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rangoFechasTexto,
                        style: TextStyle(
                          fontSize: 12,
                          color: _hayFiltroFecha
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                          fontWeight: _hayFiltroFecha
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hayFiltroFecha)
                  IconButton(
                    tooltip: 'Limpiar filtro',
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.red.shade700,
                    onPressed: _limpiarFiltros,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipRapido('Hoy'),
                  const SizedBox(width: 6),
                  _buildChipRapido('Semana'),
                  const SizedBox(width: 6),
                  _buildChipRapido('Mes'),
                  const SizedBox(width: 6),
                  _buildChipRapido('Año'),
                  const SizedBox(width: 6),
                  _buildChipRapido('Todo'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFechaButton(
                    label: 'Desde (fecha)',
                    fecha: _fechaDesde,
                    onTap: () => _seleccionarFecha(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFechaButton(
                    label: 'Hasta (fecha)',
                    fecha: _fechaHasta,
                    onTap: () => _seleccionarFecha(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHoraButton(
                    label: 'Desde (hora)',
                    hora: _horaDesde,
                    onTap: () => _seleccionarHora(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHoraButton(
                    label: 'Hasta (hora)',
                    hora: _horaHasta,
                    onTap: () => _seleccionarHora(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipRapido(String label) {
    final activo = _esRangoActivo(label);
    return GestureDetector(
      onTap: () => _aplicarRangoRapido(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.blue.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  bool _esRangoActivo(String rango) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    switch (rango) {
      case 'Hoy':
        return _fechaDesde != null &&
            _fechaHasta != null &&
            _fechaDesde!.year == hoy.year &&
            _fechaDesde!.month == hoy.month &&
            _fechaDesde!.day == hoy.day &&
            _fechaHasta!.year == hoy.year &&
            _fechaHasta!.month == hoy.month &&
            _fechaHasta!.day == hoy.day;
      case 'Semana':
        if (_fechaDesde == null || _fechaHasta == null) return false;
        final diff = _fechaHasta!.difference(_fechaDesde!).inDays;
        return diff >= 6 && diff <= 8;
      case 'Mes':
        return _fechaDesde != null &&
            _fechaHasta != null &&
            _fechaDesde!.year == ahora.year &&
            _fechaDesde!.month == ahora.month &&
            _fechaDesde!.day == 1;
      case 'Año':
        return _fechaDesde != null &&
            _fechaHasta != null &&
            _fechaDesde!.year == ahora.year &&
            _fechaDesde!.month == 1 &&
            _fechaDesde!.day == 1;
      case 'Todo':
        return !_hayFiltroFecha;
      default:
        return false;
    }
  }

  Widget _buildFechaButton({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    final tieneFecha = fecha != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tieneFecha ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tieneFecha ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: tieneFecha ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tieneFecha
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tieneFecha
                        ? DateFormat('dd/MM/yyyy').format(fecha)
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tieneFecha ? Colors.black87 : Colors.grey.shade500,
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

  Widget _buildHoraButton({
    required String label,
    required TimeOfDay? hora,
    required VoidCallback onTap,
  }) {
    final tieneHora = hora != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tieneHora ? Colors.purple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tieneHora ? Colors.purple.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: tieneHora ? Colors.purple.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tieneHora
                          ? Colors.purple.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tieneHora
                        ? '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tieneHora ? Colors.black87 : Colors.grey.shade500,
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

  // ============================================================
  // RESUMEN DE CÁLCULOS
  // ============================================================

  Widget _buildResumenCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final colorTotal = _diferenciaTotal > 0
        ? Colors.orange.shade700
        : _diferenciaTotal < 0
            ? Colors.green.shade700
            : Colors.grey.shade700;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_gas_station_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Resumen de cálculos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: _buildMetrica(
                    'Cálculos',
                    '$_cantidadCalculos',
                    Icons.calculate_outlined,
                    Colors.blue.shade700,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _buildMetrica(
                    'Diferencia total (L)',
                    _diferenciaTotal.toStringAsFixed(2),
                    Icons.trending_up,
                    colorTotal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONSUMO GENERAL
  // ============================================================

  Widget _buildConsumoGeneralCard() {
    final colorReal = Colors.orange.shade700;
    final colorTeorico = Colors.blue.shade700;
    final colorDiferencia = _diferenciaGeneral > 0
        ? Colors.red.shade700
        : _diferenciaGeneral < 0
            ? Colors.green.shade700
            : Colors.grey.shade700;

    final totalComponentes = _resumenGeneral['total_componentes'] ?? 0;
    final totalCalculos = _resumenGeneral['total_calculos'] ?? 0;
    final totalVehiculos = _resumenGeneral['total_vehiculos'] ?? 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumo general acumulado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total de todos los cálculos registrados',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaGrande(
                    'CONSUMO REAL',
                    _totalReal.toStringAsFixed(2),
                    'L',
                    Icons.water_drop,
                    colorReal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricaGrande(
                    'CONSUMO TEÓRICO',
                    _totalTeorico.toStringAsFixed(2),
                    'L',
                    Icons.science_outlined,
                    colorTeorico,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorDiferencia.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colorDiferencia.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: colorDiferencia, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diferencia (Real - Teórico)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '${_diferenciaGeneral >= 0 ? '+' : ''}${_diferenciaGeneral.toStringAsFixed(2)} L',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorDiferencia,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetrica(
                      Icons.directions_car, '$totalVehiculos', 'Vehículos'),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildMiniMetrica(
                      Icons.calculate, '$totalCalculos', 'Cálculos'),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildMiniMetrica(
                      Icons.inventory_2, '$totalComponentes', 'Componentes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOVIMIENTO DE UNIDADES
  // ============================================================

  Widget _buildResumenEntradasSalidas() {
    int entradas = 0;
    int salidas = 0;
    int unidades = 0;
    int exactos = 0;

    for (final h in _consumoPorHora) {
      entradas += (h['entradas'] as num?)?.toInt() ?? 0;
      salidas += (h['salidas'] as num?)?.toInt() ?? 0;
      unidades += (h['total_unidades'] as num?)?.toInt() ?? 0;
      exactos += (h['exactos'] as num?)?.toInt() ?? 0;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.purple.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movimiento de unidades',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unidades consumidas, entradas y salidas por hora',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricaResponsive(
                  'Unidades totales',
                  '$unidades',
                  Icons.inventory,
                  Colors.purple.shade700,
                ),
                _buildMetricaResponsive(
                  'Entradas (sobró)',
                  '+$entradas',
                  Icons.arrow_downward,
                  Colors.green.shade700,
                ),
                _buildMetricaResponsive(
                  'Salidas (faltó)',
                  '-$salidas',
                  Icons.arrow_upward,
                  Colors.red.shade700,
                ),
                _buildMetricaResponsive(
                  'Exactos',
                  '$exactos',
                  Icons.check_circle_outline,
                  Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTADO DE TOTALES
  // ============================================================

  Widget _buildListadoTotales() {
    final tieneDatos = _totalesPorComponente.isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totales de consumo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Detalle acumulado por ítem',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!tieneDatos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Sin datos de consumo aún',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Por componente',
                        Icons.inventory_2_outlined,
                        0,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Por vehículo',
                        Icons.directions_car_outlined,
                        1,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Por hora',
                        Icons.access_time,
                        2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_tabSeleccionada == 0)
                _buildTablaTotales(
                  _totalesPorComponente,
                  columnaNombre: 'COMPONENTE',
                  mostrarVecesUsado: true,
                )
              else if (_tabSeleccionada == 1)
                _buildTablaTotales(
                  _totalesPorVehiculo,
                  columnaNombre: 'VEHÍCULO',
                  mostrarVecesUsado: false,
                )
              else
                _buildTablaPorHora(_consumoPorHora),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icono, int index) {
    final seleccionado = _tabSeleccionada == index;
    return GestureDetector(
      onTap: () => setState(() => _tabSeleccionada = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 16,
              color: seleccionado ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      seleccionado ? FontWeight.bold : FontWeight.normal,
                  color: seleccionado
                      ? Colors.blue.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaTotales(
    List<Map<String, dynamic>> datos, {
    required String columnaNombre,
    required bool mostrarVecesUsado,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 620),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      columnaNombre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        mostrarVecesUsado ? 'VECES' : 'CÁLCULOS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'REAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'TEÓRICO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        'DIFERENCIA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...datos.map((item) {
              final nombre =
                  (item['nombre'] ?? item['nombreVehiculo'])?.toString() ?? '';
              final totalReal = (item['total_real'] as num?)?.toDouble() ?? 0.0;
              final totalTeorico =
                  (item['total_teorico'] as num?)?.toDouble() ?? 0.0;
              final diferencia =
                  (item['diferencia'] as num?)?.toDouble() ?? 0.0;
              final veces = mostrarVecesUsado
                  ? (item['veces_usado'] as int?) ?? 0
                  : (item['total_calculos'] as int?) ?? 0;

              final colorDif = diferencia > 0
                  ? Colors.orange.shade700
                  : diferencia < 0
                      ? Colors.green.shade700
                      : Colors.grey.shade700;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$veces',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          totalReal.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          totalTeorico.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorDif.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorDif.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorDif,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaPorHora(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Sin consumos registrados por hora',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 860),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      'HORA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'CÁLCULOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'UNIDADES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'ENTRADAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'SALIDAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'REAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'TEÓRICO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        'DIFERENCIA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...datos.map((item) {
              final hora = item['hora']?.toString() ?? '';
              final calculos = (item['calculos'] as num?)?.toInt() ?? 0;
              final unidades = (item['total_unidades'] as num?)?.toInt() ?? 0;
              final entradas = (item['entradas'] as num?)?.toInt() ?? 0;
              final salidas = (item['salidas'] as num?)?.toInt() ?? 0;
              final real = (item['total_real'] as num?)?.toDouble() ?? 0.0;
              final teorico =
                  (item['total_teorico'] as num?)?.toDouble() ?? 0.0;
              final dif = real - teorico;

              final colorDif = dif > 0
                  ? Colors.orange.shade700
                  : dif < 0
                      ? Colors.green.shade700
                      : Colors.grey.shade700;

              String horaBonita = hora;
              try {
                final dt = DateTime.parse(hora);
                horaBonita = DateFormat('dd/MM HH:00').format(dt);
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            horaBonita,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$calculos',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          '$unidades',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: _badge('+$entradas', Colors.green.shade700),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: _badge('-$salidas', Colors.red.shade700),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          real.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          teorico.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Center(
                        child: _badge(
                          '${dif >= 0 ? '+' : ''}${dif.toStringAsFixed(2)}',
                          colorDif,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MÉTRICAS
  // ============================================================

  Widget _buildMetricaGrande(
    String label,
    String valor,
    String unidad,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unidad,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetrica(IconData icono, String valor, String label) {
    return Column(
      children: [
        Icon(icono, size: 18, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMetrica(
    String label,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaResponsive(
    String label,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTRO POR VEHÍCULO
  // ============================================================

  Widget _buildFiltroCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Vehículo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filtroVehiculo,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _vehiculos
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _aplicarFiltro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTA DE CÁLCULOS
  // ============================================================

  Widget _buildListaCalculos() {
    if (_calculosFiltrados.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No hay cálculos registrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Historial de cálculos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ..._calculosFiltrados.map(_buildCalculoExpandible),
      ],
    );
  }

  Widget _buildCalculoExpandible(Map<String, dynamic> calculo) {
    final idCalculo = calculo['id_calculo'] as int;
    final diferencia =
        double.tryParse(calculo['diferencia']?.toString() ?? '0') ?? 0.0;

    final color = diferencia > 0
        ? Colors.orange.shade700
        : diferencia < 0
            ? Colors.green.shade700
            : Colors.grey.shade700;

    final nombre = calculo['nombreVehiculo']?.toString() ?? 'Vehículo';

    DateTime? fecha;
    try {
      fecha = DateTime.parse(calculo['created_at'].toString());
    } catch (_) {}

    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
        : 'Sin fecha';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.directions_car_outlined, color: color),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          fechaTexto,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Text(
                '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)} L',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: db.obtenerConsumoDetalladoPorCalculo(idCalculo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final componentes = snapshot.data ?? [];

              if (componentes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sin componentes registrados',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 4),
                    const Text(
                      'Detalle por componente:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTablaConsumo(componentes),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTablaConsumo(List<Map<String, dynamic>> componentes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 780),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      'COMPONENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'STOCK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'TEÓRICO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(
                        'REAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text(
                        'STOCK - REAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text(
                        'STOCK - TEÓRICO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...componentes.map((c) {
              final nombre = c['nombre']?.toString() ?? '';
              final stock = (c['stock_actual'] as num?)?.toDouble() ?? 0.0;
              final reseta = (c['reseta'] as num?)?.toDouble() ?? 0.0;
              final valorReal = (c['valor_real'] as num?)?.toDouble() ?? 0.0;
              final stockReal =
                  (c['stock_restante_real'] as num?)?.toDouble() ?? 0.0;
              final stockTeorico =
                  (c['stock_restante_teorico'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          stock.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          reseta.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          valorReal.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: _badge(
                          stockReal.toStringAsFixed(2),
                          Colors.orange.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: _badge(
                          stockTeorico.toStringAsFixed(2),
                          Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _badge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
          backgroundColor: esError ? Colors.red.shade700 : null,
        ),
      );
  }
}
