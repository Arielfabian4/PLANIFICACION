import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/exportar_excel_helper.dart';
import '../theme/ciauto_theme.dart';

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

  List<Map<String, dynamic>> _totalesPorComponente = [];
  List<Map<String, dynamic>> _totalesPorVehiculo = [];
  List<Map<String, dynamic>> _consumoPorHora = [];
  List<Map<String, dynamic>> _detallePorHora = [];
  int _tabSeleccionada = 0;

  Map<String, dynamic> _resumenGeneral = {
    'total_real': 0.0,
    'total_teorico': 0.0,
    'total_componentes': 0,
    'total_calculos': 0,
    'total_vehiculos': 0,
  };

  String _filtroVehiculo = 'Todos';
  bool _cargando = true;

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
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
      final desdeCompleto =
          _combinarFechaHora(_fechaDesde, _horaDesde, esInicio: true);
      final hastaCompleto =
          _combinarFechaHora(_fechaHasta, _horaHasta, esInicio: false);

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
      final detalleHora = await db.obtenerDetalleComponentesPorHora(
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
        _detallePorHora = detalleHora;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar: $e', esError: true);
    }
  }

  List<Map<String, dynamic>> _aplicarFiltroVehiculo(
      List<Map<String, dynamic>> datos, String filtro) {
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
    return Scaffold(
      backgroundColor: CiautoColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CiautoColors.red,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.local_gas_station, color: Colors.white),
            SizedBox(width: 8),
            Text('Consumo', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
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
            ? const Center(
                child: CircularProgressIndicator(color: CiautoColors.red),
              )
            : RefreshIndicator(
                color: CiautoColors.red,
                onRefresh: _cargarDatos,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFiltroFechaCard(),
                          const SizedBox(height: 14),
                          _buildResumenCard(),
                          const SizedBox(height: 14),
                          _buildConsumoGeneralCard(),
                          const SizedBox(height: 14),
                          _buildResumenEntradasSalidas(),
                          const SizedBox(height: 14),
                          _buildListadoTotales(),
                          const SizedBox(height: 14),
                          _buildFiltroCard(),
                          const SizedBox(height: 14),
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
  // EXPORTAR
  // ============================================================

  Future<void> _mostrarDialogoExportar() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.table_chart, color: CiautoColors.red),
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
              CiautoColors.red,
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
      title: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.pop(dialogContext, valor),
    );
  }

  Future<void> _exportarYCompartir(String tipo) async {
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
                CircularProgressIndicator(color: CiautoColors.red),
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
      if (mounted) Navigator.pop(context);
      if (archivo == null) {
        _mostrarMensaje('No hay datos para exportar', esError: true);
        return;
      }
      await excelHelper.compartirExcel(archivo);
      if (mounted) _mostrarMensaje('✅ Excel generado y compartido');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarMensaje('Error al exportar: $e', esError: true);
    }
  }

  // ============================================================
  // FILTRO FECHA/HORA
  // ============================================================

  Widget _buildFiltroFechaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
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
                      ? CiautoColors.redLight
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.date_range,
                  color: _hayFiltroFecha ? CiautoColors.red : CiautoColors.gray,
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
                        fontWeight: FontWeight.w700,
                        color: CiautoColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _rangoFechasTexto,
                      style: TextStyle(
                        fontSize: 12,
                        color: _hayFiltroFecha
                            ? CiautoColors.red
                            : CiautoColors.gray,
                        fontWeight: _hayFiltroFecha
                            ? FontWeight.w700
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
                  color: CiautoColors.red,
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
    );
  }

  Widget _buildChipRapido(String label) {
    final activo = _esRangoActivo(label);
    return GestureDetector(
      onTap: () => _aplicarRangoRapido(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? CiautoColors.red : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? CiautoColors.red : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : CiautoColors.gray,
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
          color: tieneFecha ? CiautoColors.redLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tieneFecha
                ? CiautoColors.red.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: tieneFecha ? CiautoColors.red : CiautoColors.gray,
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
                      fontWeight: FontWeight.w700,
                      color: tieneFecha ? CiautoColors.red : CiautoColors.gray,
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
                      color:
                          tieneFecha ? CiautoColors.dark : Colors.grey.shade500,
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
          color: tieneHora ? CiautoColors.redLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tieneHora
                ? CiautoColors.red.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: tieneHora ? CiautoColors.red : CiautoColors.gray,
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
                      fontWeight: FontWeight.w700,
                      color: tieneHora ? CiautoColors.red : CiautoColors.gray,
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
                      color:
                          tieneHora ? CiautoColors.dark : Colors.grey.shade500,
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
  // RESUMEN
  // ============================================================

  Widget _buildResumenCard() {
    final colorTotal = _diferenciaTotal > 0
        ? Colors.orange.shade700
        : _diferenciaTotal < 0
            ? Colors.green.shade700
            : CiautoColors.gray;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CiautoColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_gas_station_outlined,
                  color: CiautoColors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Resumen de cálculos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CiautoColors.dark,
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
                  CiautoColors.red,
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
    );
  }

  Widget _buildConsumoGeneralCard() {
    final colorReal = Colors.orange.shade700;
    final colorTeorico = Colors.blue.shade700;
    final colorDiferencia = _diferenciaGeneral > 0
        ? Colors.red.shade700
        : _diferenciaGeneral < 0
            ? Colors.green.shade700
            : CiautoColors.gray;

    final totalComponentes = _resumenGeneral['total_componentes'] ?? 0;
    final totalCalculos = _resumenGeneral['total_calculos'] ?? 0;
    final totalVehiculos = _resumenGeneral['total_vehiculos'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CiautoColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: CiautoColors.red,
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
                        fontWeight: FontWeight.w700,
                        color: CiautoColors.dark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total de todos los cálculos registrados',
                      style: TextStyle(fontSize: 12, color: CiautoColors.gray),
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
                const Expanded(
                  child: Text(
                    'Diferencia (Real - Teórico)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CiautoColors.dark,
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
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildMiniMetrica(
                    Icons.calculate, '$totalCalculos', 'Cálculos'),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildMiniMetrica(
                    Icons.inventory_2, '$totalComponentes', 'Componentes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CiautoColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: CiautoColors.red,
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
                        fontWeight: FontWeight.w700,
                        color: CiautoColors.dark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Unidades consumidas, entradas y salidas por hora',
                      style: TextStyle(fontSize: 12, color: CiautoColors.gray),
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
              _buildMetricaResponsive('Unidades totales', '$unidades',
                  Icons.inventory, CiautoColors.dark),
              _buildMetricaResponsive('Entradas (sobró)', '+$entradas',
                  Icons.arrow_downward, Colors.green.shade700),
              _buildMetricaResponsive('Salidas (faltó)', '-$salidas',
                  Icons.arrow_upward, CiautoColors.red),
              _buildMetricaResponsive('Exactos', '$exactos',
                  Icons.check_circle_outline, CiautoColors.gray),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTADO DE TOTALES (con 4 pestañas)
  // ============================================================

  Widget _buildListadoTotales() {
    final tieneDatos = _totalesPorComponente.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CiautoColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: CiautoColors.red,
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
                        fontWeight: FontWeight.w700,
                        color: CiautoColors.dark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Detalle acumulado por ítem',
                      style: TextStyle(fontSize: 12, color: CiautoColors.gray),
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
                  style: TextStyle(color: CiautoColors.gray),
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
                        'Componente', Icons.inventory_2_outlined, 0),
                  ),
                  Expanded(
                    child: _buildTabButton(
                        'Vehículo', Icons.directions_car_outlined, 1),
                  ),
                  Expanded(
                    child: _buildTabButton('Por hora', Icons.access_time, 2),
                  ),
                  Expanded(
                    child: _buildTabButton('Detalle hora', Icons.list_alt, 3),
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
            else if (_tabSeleccionada == 2)
              _buildTablaPorHora(_consumoPorHora)
            else
              _buildDetallePorHora(_detallePorHora),
          ],
        ],
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
              size: 14,
              color: seleccionado ? CiautoColors.red : CiautoColors.gray,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      seleccionado ? FontWeight.w700 : FontWeight.normal,
                  color: seleccionado ? CiautoColors.red : CiautoColors.gray,
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
                color: CiautoColors.redLight,
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
                        fontWeight: FontWeight.w800,
                        color: CiautoColors.redDark,
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
                          fontWeight: FontWeight.w800,
                          color: CiautoColors.redDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('REAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Center(
                      child: Text('DIFERENCIA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
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
                      : CiautoColors.gray;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CiautoColors.border),
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
                          color: CiautoColors.dark,
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
                        child: _badge(
                          '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)}',
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

  Widget _buildTablaPorHora(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Sin consumos registrados por hora',
            style: TextStyle(color: CiautoColors.gray),
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
                color: CiautoColors.redLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text('HORA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: CiautoColors.redDark)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('CÁLCULOS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('UNIDADES',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.purple)),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('ENTRADAS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.green)),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('SALIDAS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.red)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('REAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue)),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Text('DIFERENCIA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
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
                      : CiautoColors.gray;

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
                  border: Border.all(color: CiautoColors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: CiautoColors.red),
                          const SizedBox(width: 6),
                          Text(
                            horaBonita,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CiautoColors.dark,
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
                        child: _badge('-$salidas', CiautoColors.red),
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
  // DETALLE POR HORA (CORREGIDO — SIN "OVERFLOWED")
  // ============================================================

  Widget _buildDetallePorHora(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Sin detalle de componentes por hora',
            style: TextStyle(color: CiautoColors.gray),
          ),
        ),
      );
    }

    return Column(
      children: datos.map((bloque) {
        final horaRaw = bloque['hora']?.toString() ?? '';
        final vehiculos = (bloque['vehiculos'] as List?)?.cast<String>() ?? [];
        final componentes =
            (bloque['componentes'] as List?)?.cast<Map<String, dynamic>>() ??
                [];

        String horaBonita = horaRaw;
        try {
          final dt = DateTime.parse(horaRaw);
          horaBonita = DateFormat('dd/MM/yyyy HH:00').format(dt);
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CiautoColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CiautoColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CiautoColors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: CiautoColors.red),
                    const SizedBox(width: 6),
                    Text(
                      horaBonita,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CiautoColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                '${componentes.length} ${componentes.length == 1 ? 'componente' : 'componentes'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CiautoColors.dark,
                ),
              ),
              subtitle: Text(
                vehiculos.isEmpty
                    ? 'Sin vehículos'
                    : '${vehiculos.length} ${vehiculos.length == 1 ? 'vehículo' : 'vehículos'}',
                style: const TextStyle(fontSize: 10, color: CiautoColors.gray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                // ─── SCROLL HORIZONTAL PARA EVITAR "OVERFLOWED" ───
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: CiautoColors.redLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text('COMPONENTE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: CiautoColors.redDark)),
                              ),
                              SizedBox(
                                width: 55,
                                child: Center(
                                  child: Text('VECES',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: CiautoColors.redDark)),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Center(
                                  child: Text('REAL',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orange)),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Center(
                                  child: Text('TEÓR',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.blue)),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text('E',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green)),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text('S',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: CiautoColors.red)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...componentes.map((c) {
                          final nombre = c['nombre']?.toString() ?? '';
                          final veces = (c['veces'] as num?)?.toInt() ?? 0;
                          final real =
                              (c['total_real'] as num?)?.toDouble() ?? 0.0;
                          final teorico =
                              (c['total_teorico'] as num?)?.toDouble() ?? 0.0;
                          final entradas =
                              (c['entradas'] as num?)?.toInt() ?? 0;
                          final salidas = (c['salidas'] as num?)?.toInt() ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: CiautoColors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: CiautoColors.dark,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 55,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$veces',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Center(
                                    child: Text(
                                      real.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Center(
                                    child: Text(
                                      teorico.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Center(
                                    child: entradas > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+$entradas',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: CiautoColors.gray)),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Center(
                                    child: salidas > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: CiautoColors.red
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-$salidas',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: CiautoColors.red,
                                              ),
                                            ),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: CiautoColors.gray)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CiautoColors.gray,
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
        Icon(icono, size: 18, color: CiautoColors.gray),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CiautoColors.dark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: CiautoColors.gray),
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
                  style:
                      const TextStyle(fontSize: 12, color: CiautoColors.gray),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CiautoColors.gray,
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
  // FILTRO VEHÍCULO
  // ============================================================

  Widget _buildFiltroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CiautoColors.redLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: CiautoColors.red,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Vehículo:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: CiautoColors.dark,
            ),
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
    );
  }

  // ============================================================
  // LISTA DE CÁLCULOS
  // ============================================================

  Widget _buildListaCalculos() {
    if (_calculosFiltrados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CiautoColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 60, color: CiautoColors.gray),
              SizedBox(height: 12),
              Text(
                'No hay cálculos registrados',
                style: TextStyle(fontSize: 16, color: CiautoColors.gray),
              ),
            ],
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CiautoColors.dark,
            ),
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
            : CiautoColors.gray;

    final nombre = calculo['nombreVehiculo']?.toString() ?? 'Vehículo';

    DateTime? fecha;
    try {
      final raw = DateTime.parse(calculo['created_at'].toString());
      fecha = raw.isUtc ? raw.toLocal() : raw;
    } catch (_) {}

    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
        : 'Sin fecha';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CiautoColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: CiautoColors.redGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: Colors.white,
            ),
          ),
          title: Text(
            nombre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CiautoColors.dark,
            ),
          ),
          subtitle: Text(
            fechaTexto,
            style: const TextStyle(fontSize: 12, color: CiautoColors.gray),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const Icon(Icons.expand_more, color: CiautoColors.gray),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CiautoColors.red,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: CiautoColors.red),
                    ),
                  );
                }

                final componentes = snapshot.data ?? [];
                if (componentes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sin componentes registrados',
                      style: TextStyle(color: CiautoColors.gray),
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
                          fontWeight: FontWeight.w700,
                          color: CiautoColors.dark,
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
                color: CiautoColors.redLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text('COMPONENTE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: CiautoColors.redDark)),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('STOCK',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('REAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CiautoColors.redDark)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text('STOCK - REAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text('STOCK - TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue)),
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
                  border: Border.all(color: CiautoColors.border),
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
                            fontSize: 12, color: CiautoColors.dark),
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
                            color: CiautoColors.dark,
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
          backgroundColor: esError ? CiautoColors.red : null,
        ),
      );
  }
}
