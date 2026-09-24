import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/exportar_excel_helper.dart';
import '../theme/ciauto_theme.dart';

// ============================================================
// 🏎️ TEMA AUTOMOTRIZ + HUD
// ============================================================
class AutomotiveTheme {
  // Base
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

  // 🎨 Paleta HUD neón
  static const Color hudCyan = Color(0xFF00E5FF);
  static const Color hudMagenta = Color(0xFFFF006E);
  static const Color hudLime = Color(0xFF00FF88);
  static const Color hudBg = Color(0xFF050A0F);
  static const Color hudPanel = Color(0xFF0A1419);
  static const Color hudLine = Color(0xFF1A3038);

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

  static const LinearGradient hudGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00FF88)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================
// 🎨 PAINTER: PANEL HUD CON ESQUINAS CORTADAS
// ============================================================
class HudPanelPainter extends CustomPainter {
  final Color accent;
  HudPanelPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 14.0;
    final paintFill = Paint()
      ..color = AutomotiveTheme.hudPanel
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final paintAccent = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintBorder);

    // Franja superior de acento
    canvas.drawLine(
      Offset(cut + 6, 0),
      Offset(size.width * 0.4, 0),
      paintAccent,
    );
    // Franja inferior derecha
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width - cut - 6, size.height),
      paintAccent,
    );

    // Pequeñas marcas técnicas en las esquinas
    final cornerPaint = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;
    // Superior izquierda
    canvas.drawLine(
        const Offset(cut, 0), const Offset(cut + 10, 0), cornerPaint);
    // Superior derecha
    canvas.drawLine(Offset(size.width - cut - 10, 0),
        Offset(size.width - cut, 0), cornerPaint);
    // Inferior izquierda
    canvas.drawLine(Offset(0, size.height - cut),
        Offset(0, size.height - cut + 10), cornerPaint);
    // Inferior derecha
    canvas.drawLine(Offset(size.width, size.height - cut - 10),
        Offset(size.width, size.height - cut), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant HudPanelPainter old) => old.accent != accent;
}

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AutomotiveTheme.hudCyan,
              onPrimary: Colors.black,
              surface: AutomotiveTheme.hudPanel,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AutomotiveTheme.hudPanel,
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AutomotiveTheme.hudCyan,
              onPrimary: Colors.black,
              surface: AutomotiveTheme.hudPanel,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AutomotiveTheme.hudPanel,
          ),
          child: child!,
        );
      },
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
        desde = DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
        hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
      case 'Semana':
        final hace7 = ahora.subtract(const Duration(days: 7));
        desde = DateTime(hace7.year, hace7.month, hace7.day, 0, 0, 0);
        hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
      case 'Mes':
        desde = DateTime(ahora.year, ahora.month, 1, 0, 0, 0);
        hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
      case 'Año':
        desde = DateTime(ahora.year, 1, 1, 0, 0, 0);
        hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
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
      backgroundColor: AutomotiveTheme.hudBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AutomotiveTheme.hudPanel,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050A0F), Color(0xFF0A1419)],
            ),
            border: Border(
              bottom: BorderSide(color: AutomotiveTheme.hudCyan, width: 2),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.local_gas_station,
                  color: AutomotiveTheme.hudCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'CONSUMO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar a Excel',
            icon: const Icon(Icons.table_chart_outlined,
                color: AutomotiveTheme.hudCyan),
            onPressed: _mostrarDialogoExportar,
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh, color: AutomotiveTheme.hudCyan),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child:
                    CircularProgressIndicator(color: AutomotiveTheme.hudCyan),
              )
            : RefreshIndicator(
                color: AutomotiveTheme.hudCyan,
                backgroundColor: AutomotiveTheme.hudPanel,
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
  // HELPERS UI HUD
  // ============================================================

  Widget _buildHudPanel({
    required Widget child,
    Color accent = AutomotiveTheme.hudCyan,
    EdgeInsets? padding,
    String? cornerLabel,
  }) {
    return CustomPaint(
      painter: HudPanelPainter(accent: accent),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        child: Stack(
          children: [
            child,
            if (cornerLabel != null)
              Positioned(
                top: -4,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AutomotiveTheme.hudBg,
                  child: Text(
                    cornerLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudHeader(String titulo,
      {Color accent = AutomotiveTheme.hudCyan}) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: accent),
        const SizedBox(width: 8),
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AutomotiveTheme.hudLine,
          ),
        ),
      ],
    );
  }

  Widget _buildGaugeCircular({
    required String label,
    required String valor,
    required String unidad,
    required double progreso,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.15),
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: progreso.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    unidad,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: color.withValues(alpha: 0.7),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXPORTAR
  // ============================================================

  Future<void> _mostrarDialogoExportar() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1419), Color(0xFF050A0F)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AutomotiveTheme.hudCyan.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.25),
                blurRadius: 30,
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
                      color: AutomotiveTheme.hudLine,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AutomotiveTheme.hudCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AutomotiveTheme.hudCyan.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(Icons.table_chart,
                          color: AutomotiveTheme.hudCyan, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'EXPORTAR A EXCEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildOpcionExportar(
                      'Cálculos completos',
                      'Historial con detalle por componente',
                      Icons.calculate_outlined,
                      AutomotiveTheme.hudCyan,
                      'calculos',
                      dialogContext,
                    ),
                    _buildOpcionExportar(
                      'Consumo por componente',
                      'Totales acumulados por ítem',
                      Icons.analytics_outlined,
                      AutomotiveTheme.hudMagenta,
                      'consumo',
                      dialogContext,
                    ),
                    _buildOpcionExportar(
                      'Reporte completo',
                      'Todo en un solo archivo con varias hojas',
                      Icons.description_outlined,
                      AutomotiveTheme.hudLime,
                      'todo',
                      dialogContext,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AutomotiveTheme.hudLine, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('CANCELAR',
                          style: TextStyle(
                              color: AutomotiveTheme.chromeSilver,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(dialogContext, valor),
          splashColor: color.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(icono, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
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

  Future<void> _exportarYCompartir(String tipo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: AutomotiveTheme.hudPanel,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AutomotiveTheme.hudCyan),
                SizedBox(height: 12),
                Text('Generando Excel...',
                    style: TextStyle(color: Colors.white)),
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
    return _buildHudPanel(
      accent:
          _hayFiltroFecha ? AutomotiveTheme.hudCyan : AutomotiveTheme.hudLine,
      cornerLabel: 'SYS::FILTER',
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
                  color: (_hayFiltroFecha
                          ? AutomotiveTheme.hudCyan
                          : AutomotiveTheme.chromeSilver)
                      .withValues(alpha: 0.12),
                  border: Border.all(
                    color: (_hayFiltroFecha
                            ? AutomotiveTheme.hudCyan
                            : AutomotiveTheme.chromeSilver)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.date_range,
                  color: _hayFiltroFecha
                      ? AutomotiveTheme.hudCyan
                      : AutomotiveTheme.chromeSilver,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FILTRO DE FECHA Y HORA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _rangoFechasTexto,
                      style: TextStyle(
                        fontSize: 11,
                        color: _hayFiltroFecha
                            ? AutomotiveTheme.hudCyan
                            : AutomotiveTheme.chromeSilver,
                        fontWeight: _hayFiltroFecha
                            ? FontWeight.w700
                            : FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hayFiltroFecha)
                IconButton(
                  tooltip: 'Limpiar filtro',
                  icon: const Icon(Icons.close, size: 20),
                  color: AutomotiveTheme.hudCyan,
                  onPressed: _limpiarFiltros,
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                  label: 'DESDE',
                  fecha: _fechaDesde,
                  onTap: () => _seleccionarFecha(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFechaButton(
                  label: 'HASTA',
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
                  label: 'HORA DESDE',
                  hora: _horaDesde,
                  onTap: () => _seleccionarHora(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHoraButton(
                  label: 'HORA HASTA',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo
              ? AutomotiveTheme.hudCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: activo ? AutomotiveTheme.hudCyan : AutomotiveTheme.hudLine,
          ),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color:
                activo ? AutomotiveTheme.hudCyan : AutomotiveTheme.chromeSilver,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tieneFecha
              ? AutomotiveTheme.hudCyan.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color:
                tieneFecha ? AutomotiveTheme.hudCyan : AutomotiveTheme.hudLine,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: tieneFecha
                  ? AutomotiveTheme.hudCyan
                  : AutomotiveTheme.chromeSilver,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: tieneFecha
                          ? AutomotiveTheme.hudCyan
                          : AutomotiveTheme.chromeSilver,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tieneFecha
                        ? DateFormat('dd/MM/yyyy').format(fecha)
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tieneFecha
                          ? Colors.white
                          : AutomotiveTheme.chromeSilver,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tieneHora
              ? AutomotiveTheme.hudCyan.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color:
                tieneHora ? AutomotiveTheme.hudCyan : AutomotiveTheme.hudLine,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: tieneHora
                  ? AutomotiveTheme.hudCyan
                  : AutomotiveTheme.chromeSilver,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: tieneHora
                          ? AutomotiveTheme.hudCyan
                          : AutomotiveTheme.chromeSilver,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tieneHora
                        ? '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tieneHora
                          ? Colors.white
                          : AutomotiveTheme.chromeSilver,
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
        ? AutomotiveTheme.hudMagenta
        : _diferenciaTotal < 0
            ? AutomotiveTheme.hudLime
            : AutomotiveTheme.chromeSilver;

    return _buildHudPanel(
      accent: AutomotiveTheme.hudCyan,
      cornerLabel: 'SYS::RESUMEN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHudHeader('RESUMEN DE CÁLCULOS'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: _buildMetrica(
                  'CÁLCULOS',
                  '$_cantidadCalculos',
                  Icons.calculate_outlined,
                  AutomotiveTheme.hudCyan,
                ),
              ),
              SizedBox(
                width: 160,
                child: _buildMetrica(
                  'DIFERENCIA (L)',
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
    final maxValor =
        [_totalReal, _totalTeorico].reduce((a, b) => a > b ? a : b);
    final progresoReal = maxValor > 0 ? _totalReal / maxValor : 0.0;
    final progresoTeorico = maxValor > 0 ? _totalTeorico / maxValor : 0.0;

    final colorDiferencia = _diferenciaGeneral > 0
        ? AutomotiveTheme.hudMagenta
        : _diferenciaGeneral < 0
            ? AutomotiveTheme.hudLime
            : AutomotiveTheme.chromeSilver;

    final totalComponentes = _resumenGeneral['total_componentes'] ?? 0;
    final totalCalculos = _resumenGeneral['total_calculos'] ?? 0;
    final totalVehiculos = _resumenGeneral['total_vehiculos'] ?? 0;

    return _buildHudPanel(
      accent: AutomotiveTheme.hudCyan,
      cornerLabel: 'SYS::CONSUMO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHudHeader('CONSUMO GENERAL ACUMULADO'),
          const SizedBox(height: 6),
          const Text(
            '// TOTAL DE TODOS LOS CÁLCULOS REGISTRADOS',
            style: TextStyle(
              fontSize: 10,
              color: AutomotiveTheme.chromeSilver,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGaugeCircular(
                label: 'REAL',
                valor: _totalReal.toStringAsFixed(1),
                unidad: 'L',
                progreso: progresoReal,
                color: AutomotiveTheme.hudCyan,
              ),
              _buildGaugeCircular(
                label: 'TEÓRICO',
                valor: _totalTeorico.toStringAsFixed(1),
                unidad: 'L',
                progreso: progresoTeorico,
                color: AutomotiveTheme.hudMagenta,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorDiferencia.withValues(alpha: 0.08),
              border: Border.all(color: colorDiferencia.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: colorDiferencia, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Δ DIFERENCIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: colorDiferencia,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_diferenciaGeneral >= 0 ? '+' : ''}${_diferenciaGeneral.toStringAsFixed(2)} L',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
              color: AutomotiveTheme.hudLine.withValues(alpha: 0.3),
              border: Border.all(color: AutomotiveTheme.hudLine),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetrica(
                    Icons.directions_car, '$totalVehiculos', 'VEHÍCULOS'),
                Container(width: 1, height: 30, color: AutomotiveTheme.hudLine),
                _buildMiniMetrica(
                    Icons.calculate, '$totalCalculos', 'CÁLCULOS'),
                Container(width: 1, height: 30, color: AutomotiveTheme.hudLine),
                _buildMiniMetrica(
                    Icons.inventory_2, '$totalComponentes', 'COMPONENTES'),
              ],
            ),
          ),
          if (_totalesPorComponente.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AutomotiveTheme.hudLine, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    size: 14,
                    color: AutomotiveTheme.hudCyan,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'COMPONENTES UTILIZADOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.12),
                    border: Border.all(
                        color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${_totalesPorComponente.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AutomotiveTheme.hudCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._totalesPorComponente.map(_buildComponenteUtilizado),
          ] else ...[
            const SizedBox(height: 16),
            const Divider(color: AutomotiveTheme.hudLine, height: 1),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '// SIN COMPONENTES REGISTRADOS',
                style: TextStyle(
                  fontSize: 11,
                  color: AutomotiveTheme.chromeSilver.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComponenteUtilizado(Map<String, dynamic> item) {
    final nombre = item['nombre']?.toString() ?? 'Componente';
    final totalReal = (item['total_real'] as num?)?.toDouble() ?? 0.0;
    final totalTeorico = (item['total_teorico'] as num?)?.toDouble() ?? 0.0;
    final veces = (item['veces_usado'] as num?)?.toInt() ?? 0;
    final unidad = item['unidad']?.toString() ?? 'L';
    final diferencia = totalReal - totalTeorico;

    final colorDif = diferencia > 0
        ? AutomotiveTheme.hudMagenta
        : diferencia < 0
            ? AutomotiveTheme.hudLime
            : AutomotiveTheme.chromeSilver;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: AutomotiveTheme.hudLine, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AutomotiveTheme.hudCyan.withValues(alpha: 0.10),
              border: Border.all(
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              size: 16,
              color: AutomotiveTheme.hudCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AutomotiveTheme.hudLine.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        '$veces ${veces == 1 ? 'vez' : 'veces'}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AutomotiveTheme.chromeSilver,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TEÓRICO: ${totalTeorico.toStringAsFixed(2)} $unidad',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AutomotiveTheme.chromeSilver,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    totalReal.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AutomotiveTheme.hudCyan,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    unidad,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AutomotiveTheme.hudCyan.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              _badge(
                '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                colorDif,
              ),
            ],
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

    return _buildHudPanel(
      accent: AutomotiveTheme.hudLime,
      cornerLabel: 'SYS::MOV',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHudHeader('MOVIMIENTO DE UNIDADES',
              accent: AutomotiveTheme.hudLime),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricaResponsive('UNIDADES TOTALES', '$unidades',
                  Icons.inventory, Colors.white),
              _buildMetricaResponsive('ENTRADAS (SOBRÓ)', '+$entradas',
                  Icons.arrow_downward, AutomotiveTheme.hudLime),
              _buildMetricaResponsive('SALIDAS (FALTÓ)', '-$salidas',
                  Icons.arrow_upward, AutomotiveTheme.hudMagenta),
              _buildMetricaResponsive('EXACTOS', '$exactos',
                  Icons.check_circle_outline, AutomotiveTheme.chromeSilver),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTADO DE TOTALES
  // ============================================================

  Widget _buildListadoTotales() {
    final tieneDatos = _totalesPorComponente.isNotEmpty;

    return _buildHudPanel(
      accent: AutomotiveTheme.hudCyan,
      cornerLabel: 'SYS::DATA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHudHeader('TOTALES DE CONSUMO'),
          const SizedBox(height: 16),
          if (!tieneDatos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '// SIN DATOS DE CONSUMO AÚN',
                  style: TextStyle(
                      color: AutomotiveTheme.chromeSilver, letterSpacing: 1.5),
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(color: AutomotiveTheme.hudLine),
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
          color: seleccionado
              ? AutomotiveTheme.hudCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: seleccionado ? AutomotiveTheme.hudCyan : Colors.transparent,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.3),
                    blurRadius: 8,
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
              color: seleccionado
                  ? AutomotiveTheme.hudCyan
                  : AutomotiveTheme.chromeSilver,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: seleccionado ? FontWeight.w900 : FontWeight.w600,
                  color: seleccionado
                      ? AutomotiveTheme.hudCyan
                      : AutomotiveTheme.chromeSilver,
                  letterSpacing: 0.5,
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
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.10),
                border: Border.all(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      columnaNombre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AutomotiveTheme.hudCyan,
                        letterSpacing: 2,
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
                          fontWeight: FontWeight.w900,
                          color: AutomotiveTheme.hudCyan,
                          letterSpacing: 2,
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
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudMagenta,
                              letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Center(
                      child: Text('DIFERENCIA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudLime,
                              letterSpacing: 2)),
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
                  ? AutomotiveTheme.hudMagenta
                  : diferencia < 0
                      ? AutomotiveTheme.hudLime
                      : AutomotiveTheme.chromeSilver;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(color: AutomotiveTheme.hudLine, width: 1),
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
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
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
                            color:
                                AutomotiveTheme.hudLine.withValues(alpha: 0.5),
                          ),
                          child: Text(
                            '$veces',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudCyan,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          totalTeorico.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudMagenta,
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
            '// SIN CONSUMOS REGISTRADOS POR HORA',
            style: TextStyle(
                color: AutomotiveTheme.chromeSilver, letterSpacing: 1.5),
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
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.10),
                border: Border.all(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text('HORA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudCyan,
                            letterSpacing: 2)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('CÁLCULOS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('UNIDADES',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudLime,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('ENTRADAS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudLime,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text('SALIDAS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudMagenta,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('REAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudMagenta,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Text('DIFERENCIA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudLime,
                              letterSpacing: 2)),
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
                  ? AutomotiveTheme.hudMagenta
                  : dif < 0
                      ? AutomotiveTheme.hudLime
                      : AutomotiveTheme.chromeSilver;

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
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(color: AutomotiveTheme.hudLine, width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AutomotiveTheme.hudCyan),
                          const SizedBox(width: 6),
                          Text(
                            horaBonita,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                            color:
                                AutomotiveTheme.hudLine.withValues(alpha: 0.5),
                          ),
                          child: Text(
                            '$calculos',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudLime,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: _badge('+$entradas', AutomotiveTheme.hudLime),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: _badge('-$salidas', AutomotiveTheme.hudMagenta),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          real.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudCyan,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          teorico.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudMagenta,
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
  // DETALLE POR HORA
  // ============================================================

  Widget _buildDetallePorHora(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '// SIN DETALLE DE COMPONENTES POR HORA',
            style: TextStyle(
                color: AutomotiveTheme.chromeSilver, letterSpacing: 1.5),
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
            color: Colors.black.withValues(alpha: 0.25),
            border: Border.all(color: AutomotiveTheme.hudLine),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: AutomotiveTheme.hudCyan,
              collapsedIconColor: AutomotiveTheme.chromeSilver,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AutomotiveTheme.hudCyan.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AutomotiveTheme.hudCyan),
                    const SizedBox(width: 6),
                    Text(
                      horaBonita,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AutomotiveTheme.hudCyan,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                '${componentes.length} ${componentes.length == 1 ? 'componente' : 'componentes'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                vehiculos.isEmpty
                    ? 'Sin vehículos'
                    : '${vehiculos.length} ${vehiculos.length == 1 ? 'vehículo' : 'vehículos'}',
                style: const TextStyle(
                    fontSize: 10, color: AutomotiveTheme.chromeSilver),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
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
                            color:
                                AutomotiveTheme.hudCyan.withValues(alpha: 0.10),
                            border: Border.all(
                                color: AutomotiveTheme.hudCyan
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text('COMPONENTE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AutomotiveTheme.hudCyan,
                                        letterSpacing: 2)),
                              ),
                              SizedBox(
                                width: 55,
                                child: Center(
                                  child: Text('VECES',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AutomotiveTheme.hudCyan,
                                          letterSpacing: 2)),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Center(
                                  child: Text('REAL',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AutomotiveTheme.hudCyan,
                                          letterSpacing: 2)),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Center(
                                  child: Text('TEÓR',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AutomotiveTheme.hudMagenta,
                                          letterSpacing: 2)),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text('E',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AutomotiveTheme.hudLime,
                                          letterSpacing: 2)),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text('S',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AutomotiveTheme.hudMagenta,
                                          letterSpacing: 2)),
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
                              color: Colors.black.withValues(alpha: 0.25),
                              border: Border.all(
                                  color: AutomotiveTheme.hudLine, width: 1),
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
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                                        color: AutomotiveTheme.hudLine
                                            .withValues(alpha: 0.5),
                                      ),
                                      child: Text(
                                        '$veces',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
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
                                        fontWeight: FontWeight.w900,
                                        color: AutomotiveTheme.hudCyan,
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
                                        fontWeight: FontWeight.w900,
                                        color: AutomotiveTheme.hudMagenta,
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
                                              color: AutomotiveTheme.hudLime
                                                  .withValues(alpha: 0.15),
                                              border: Border.all(
                                                  color: AutomotiveTheme.hudLime
                                                      .withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              '+$entradas',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: AutomotiveTheme.hudLime,
                                              ),
                                            ),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AutomotiveTheme
                                                    .chromeSilver)),
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
                                              color: AutomotiveTheme.hudMagenta
                                                  .withValues(alpha: 0.15),
                                              border: Border.all(
                                                  color: AutomotiveTheme
                                                      .hudMagenta
                                                      .withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              '-$salidas',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    AutomotiveTheme.hudMagenta,
                                              ),
                                            ),
                                          )
                                        : const Text('-',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AutomotiveTheme
                                                    .chromeSilver)),
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

  Widget _buildMiniMetrica(IconData icono, String valor, String label) {
    return Column(
      children: [
        Icon(icono, size: 18, color: AutomotiveTheme.hudCyan),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AutomotiveTheme.chromeSilver,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
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
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2),
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
              fontWeight: FontWeight.w900,
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
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.5,
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
              fontWeight: FontWeight.w900,
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
    return _buildHudPanel(
      accent: AutomotiveTheme.hudCyan,
      cornerLabel: 'SYS::SELECT',
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AutomotiveTheme.hudCyan.withValues(alpha: 0.12),
              border: Border.all(
                  color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: AutomotiveTheme.hudCyan,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'VEHÍCULO:',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.5,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filtroVehiculo,
              isExpanded: true,
              dropdownColor: AutomotiveTheme.hudPanel,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              iconEnabledColor: AutomotiveTheme.hudCyan,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: const BorderSide(color: AutomotiveTheme.hudLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: const BorderSide(color: AutomotiveTheme.hudLine),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  borderSide:
                      BorderSide(color: AutomotiveTheme.hudCyan, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
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
      return _buildHudPanel(
        accent: AutomotiveTheme.chromeSilver,
        cornerLabel: 'SYS::HIST',
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 60, color: AutomotiveTheme.chromeSilver),
                SizedBox(height: 12),
                Text(
                  '// NO HAY CÁLCULOS REGISTRADOS',
                  style: TextStyle(
                      fontSize: 12,
                      color: AutomotiveTheme.chromeSilver,
                      letterSpacing: 1.5),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(width: 3, height: 16, color: AutomotiveTheme.hudCyan),
              const SizedBox(width: 8),
              const Text(
                'HISTORIAL DE CÁLCULOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ],
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
        ? AutomotiveTheme.hudMagenta
        : diferencia < 0
            ? AutomotiveTheme.hudLime
            : AutomotiveTheme.chromeSilver;

    final nombre = calculo['nombreVehiculo']?.toString() ?? 'Vehículo';

    DateTime? fecha;
    try {
      final rawStr = calculo['created_at'].toString();
      final texto = rawStr.replaceFirst(' ', 'T');
      if (texto.endsWith('Z')) {
        fecha = DateTime.parse(texto).toLocal();
      } else {
        fecha = DateTime.parse('${texto}Z').toLocal();
      }
    } catch (_) {
      try {
        fecha = DateTime.parse(calculo['created_at'].toString());
      } catch (_) {
        fecha = null;
      }
    }

    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
        : 'Sin fecha';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: color,
          collapsedIconColor: AutomotiveTheme.chromeSilver,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              color: color,
            ),
          ),
          title: Text(
            nombre,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          subtitle: Text(
            fechaTexto,
            style: const TextStyle(
                fontSize: 11, color: AutomotiveTheme.chromeSilver),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)} L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, color: color),
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
                          color: AutomotiveTheme.hudCyan,
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
                      style: const TextStyle(color: AutomotiveTheme.hudMagenta),
                    ),
                  );
                }

                final componentes = snapshot.data ?? [];
                if (componentes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sin componentes registrados',
                      style: TextStyle(color: AutomotiveTheme.chromeSilver),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: AutomotiveTheme.hudLine),
                      const SizedBox(height: 4),
                      const Text(
                        'DETALLE POR COMPONENTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AutomotiveTheme.hudCyan,
                          letterSpacing: 2.5,
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
                color: AutomotiveTheme.hudCyan.withValues(alpha: 0.10),
                border: Border.all(
                    color: AutomotiveTheme.hudCyan.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text('COMPONENTE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AutomotiveTheme.hudCyan,
                            letterSpacing: 2)),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('STOCK',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('TEÓRICO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudMagenta,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text('REAL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text('STOCK - REAL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudCyan,
                              letterSpacing: 2)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Text('STOCK - TEÓRICO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AutomotiveTheme.hudMagenta,
                              letterSpacing: 2)),
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
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(color: AutomotiveTheme.hudLine, width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          stock.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          reseta.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AutomotiveTheme.hudMagenta,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          valorReal.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AutomotiveTheme.hudCyan,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: _badge(
                          stockReal.toStringAsFixed(2),
                          AutomotiveTheme.hudCyan,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: _badge(
                          stockTeorico.toStringAsFixed(2),
                          AutomotiveTheme.hudMagenta,
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
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
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
          backgroundColor:
              esError ? AutomotiveTheme.hudMagenta : AutomotiveTheme.hudPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: BorderSide(
              color: (esError
                      ? AutomotiveTheme.hudMagenta
                      : AutomotiveTheme.hudLime)
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
      );
  }
}
