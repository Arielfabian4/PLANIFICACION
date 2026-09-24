import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vehiculos_app/database/database_helper.dart';

// ══════════════════════════════════════════════════════════════
// 🎨 TEMA LOCAL (evita import circular con home_screen)
// ══════════════════════════════════════════════════════════════
class _T {
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

  static const LinearGradient carbonGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF1F2630)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ResumenDiaScreen extends StatefulWidget {
  const ResumenDiaScreen({super.key});

  @override
  State<ResumenDiaScreen> createState() => _ResumenDiaScreenState();
}

class _ResumenDiaScreenState extends State<ResumenDiaScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  DateTime _diaSeleccionado = DateTime.now();
  bool _cargando = true;
  bool _exportando = false;

  Map<String, dynamic> _resumen = {
    'total_calculos': 0,
    'total_unidades': 0,
    'total_real': 0.0,
    'total_teorico': 0.0,
    'total_entradas': 0,
    'total_salidas': 0,
    'total_exactos': 0,
  };

  List<Map<String, dynamic>> _porComponente = [];
  List<Map<String, dynamic>> _porVehiculo = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  DateTime get _inicioDia => DateTime(
        _diaSeleccionado.year,
        _diaSeleccionado.month,
        _diaSeleccionado.day,
      );

  DateTime get _finDia => _inicioDia.add(const Duration(days: 1));

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      final desde = _inicioDia;
      final hasta = _finDia;

      final resumen = await _db.obtenerResumenGeneralConsumoPorFechaHora(
        desde: desde,
        hasta: hasta,
      );
      final porComponente = await _db.obtenerTotalesPorComponentePorFechaHora(
        desde: desde,
        hasta: hasta,
      );
      final porVehiculo = await _db.obtenerTotalesPorVehiculoPorFechaHora(
        desde: desde,
        hasta: hasta,
      );

      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _porComponente = porComponente;
        _porVehiculo = porVehiculo;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('❌ Error resumen del día: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _elegirDia() async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado,
      firstDate: hoy.subtract(const Duration(days: 365)),
      lastDate: hoy,
      locale: const Locale('es'),
    );
    if (elegido != null) {
      setState(() => _diaSeleccionado = elegido);
      _cargar();
    }
  }

  void _cambiarDia(int delta) {
    final nuevo = _diaSeleccionado.add(Duration(days: delta));
    if (nuevo.isAfter(DateTime.now())) return;
    setState(() => _diaSeleccionado = nuevo);
    _cargar();
  }

  String get _tituloDia {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    final esHoy = _mismoDia(_diaSeleccionado, hoy);
    final esAyer = _mismoDia(_diaSeleccionado, ayer);

    final fecha = DateFormat('EEEE d MMM yyyy', 'es').format(_diaSeleccionado);
    if (esHoy) return 'HOY · $fecha';
    if (esAyer) return 'AYER · $fecha';
    return fecha.toUpperCase();
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ══════════════════════════════════════════════════════════════
  // 📊 EXPORTAR EXCEL
  // ══════════════════════════════════════════════════════════════
  Future<void> _exportarExcel() async {
    final totalUnidades = (_resumen['total_unidades'] as int?) ?? 0;
    final totalCalculos = (_resumen['total_calculos'] as int?) ?? 0;

    if (totalUnidades == 0 && totalCalculos == 0) {
      _showSnackBar(
        'No hay datos para exportar en este día',
        icon: Icons.info_outline,
        color: _T.warningAmber,
      );
      return;
    }

    setState(() => _exportando = true);

    try {
      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();

      // HOJA 1: RESUMEN
      const hojaResumen = 'Resumen';
      if (defaultSheet != null) {
        excel.rename(defaultSheet, hojaResumen);
      } else {
        excel[hojaResumen];
      }
      final sheet1 = excel[hojaResumen];

      final tituloCell = sheet1.cell(CellIndex.indexByString('A1'));
      tituloCell.value = TextCellValue('RESUMEN DEL DÍA');
      tituloCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('#E63946'),
      );

      final fechaCell = sheet1.cell(CellIndex.indexByString('A2'));
      fechaCell.value = TextCellValue(_tituloDia);
      fechaCell.cellStyle = CellStyle(bold: true, fontSize: 12);

      final h1 = sheet1.cell(CellIndex.indexByString('A4'));
      h1.value = TextCellValue('MÉTRICA');
      h1.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1F2630'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      final h2 = sheet1.cell(CellIndex.indexByString('B4'));
      h2.value = TextCellValue('VALOR');
      h2.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1F2630'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      final totalReal = (_resumen['total_real'] as num?)?.toDouble() ?? 0.0;
      final totalTeorico =
          (_resumen['total_teorico'] as num?)?.toDouble() ?? 0.0;
      final diferencia = totalReal - totalTeorico;

      final filasResumen = <List<dynamic>>[
        ['Unidades ingresadas', totalUnidades],
        ['Cálculos realizados', totalCalculos],
        ['Entradas', (_resumen['total_entradas'] as int?) ?? 0],
        ['Salidas', (_resumen['total_salidas'] as int?) ?? 0],
        ['Exactos', (_resumen['total_exactos'] as int?) ?? 0],
        ['Total real (fluidos)', totalReal],
        ['Total teórico (fluidos)', totalTeorico],
        ['Diferencia', diferencia],
      ];

      int rowIdx = 5;
      for (final fila in filasResumen) {
        sheet1
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
            .value = TextCellValue(fila[0].toString());
        sheet1
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
            .value = DoubleCellValue((fila[1] as num).toDouble());
        rowIdx++;
      }

      sheet1.setColumnWidth(0, 28);
      sheet1.setColumnWidth(1, 18);

      // HOJA 2: FLUIDOS
      const hojaFluidos = 'Fluidos';
      excel[hojaFluidos];
      final sheet2 = excel[hojaFluidos];

      final titF = sheet2.cell(CellIndex.indexByString('A1'));
      titF.value = TextCellValue('FLUIDOS DEL DÍA');
      titF.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1E90FF'),
      );

      final headersFluidos = [
        'Fluido',
        'Unidad',
        'Veces usado',
        'Real',
        'Teórico',
        'Diferencia',
      ];
      for (int i = 0; i < headersFluidos.length; i++) {
        final cell = sheet2.cell(CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 2,
        ));
        cell.value = TextCellValue(headersFluidos[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#1F2630'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      int rowF = 3;
      for (final c in _porComponente) {
        final nombre = c['nombre']?.toString() ?? '';
        final unidad = c['unidad']?.toString() ?? 'LT';
        final veces = (c['veces_usado'] as int?) ?? 0;
        final real = (c['total_real'] as num?)?.toDouble() ?? 0.0;
        final teorico = (c['total_teorico'] as num?)?.toDouble() ?? 0.0;
        final dif = real - teorico;

        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowF))
            .value = TextCellValue(nombre);
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowF))
            .value = TextCellValue(unidad);
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowF))
            .value = IntCellValue(veces);
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowF))
            .value = DoubleCellValue(real);
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowF))
            .value = DoubleCellValue(teorico);
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowF))
            .value = DoubleCellValue(dif);
        rowF++;
      }

      sheet2.setColumnWidth(0, 45);
      sheet2.setColumnWidth(1, 10);
      sheet2.setColumnWidth(2, 12);
      sheet2.setColumnWidth(3, 12);
      sheet2.setColumnWidth(4, 12);
      sheet2.setColumnWidth(5, 12);

      // HOJA 3: UNIDADES
      const hojaVehiculos = 'Unidades';
      excel[hojaVehiculos];
      final sheet3 = excel[hojaVehiculos];

      final titV = sheet3.cell(CellIndex.indexByString('A1'));
      titV.value = TextCellValue('UNIDADES INGRESADAS');
      titV.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#00E676'),
      );

      final headersVeh = [
        'Modelo',
        'Código',
        'Lote',
        'Cálculos',
        'Real',
        'Teórico',
        'Diferencia',
      ];
      for (int i = 0; i < headersVeh.length; i++) {
        final cell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 2,
        ));
        cell.value = TextCellValue(headersVeh[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#1F2630'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      int rowV = 3;
      for (final v in _porVehiculo) {
        final modelo = v['nombreVehiculo']?.toString() ?? '';
        final codigo = v['codigoVehiculo']?.toString() ?? '';
        final lote = v['loteVehiculo']?.toString() ?? '';
        final calculos = (v['total_calculos'] as int?) ?? 0;
        final real = (v['total_real'] as num?)?.toDouble() ?? 0.0;
        final teorico = (v['total_teorico'] as num?)?.toDouble() ?? 0.0;
        final dif = real - teorico;

        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowV))
            .value = TextCellValue(modelo);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowV))
            .value = TextCellValue(codigo);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowV))
            .value = TextCellValue(lote);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowV))
            .value = IntCellValue(calculos);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowV))
            .value = DoubleCellValue(real);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowV))
            .value = DoubleCellValue(teorico);
        sheet3
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowV))
            .value = DoubleCellValue(dif);
        rowV++;
      }

      sheet3.setColumnWidth(0, 30);
      sheet3.setColumnWidth(1, 18);
      sheet3.setColumnWidth(2, 20);
      sheet3.setColumnWidth(3, 12);
      sheet3.setColumnWidth(4, 12);
      sheet3.setColumnWidth(5, 12);
      sheet3.setColumnWidth(6, 12);

      // GUARDAR
      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Error al generar el Excel');
      }

      final fechaStr = '${_inicioDia.year}-'
          '${_inicioDia.month.toString().padLeft(2, '0')}-'
          '${_inicioDia.day.toString().padLeft(2, '0')}';
      final nombreArchivo = 'resumen_dia_$fechaStr.xlsx';

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$nombreArchivo';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _exportando = false);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _T.carbonSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _T.dashGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle,
                    color: _T.dashGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Excel generado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreArchivo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                path,
                style: TextStyle(
                  color: _T.chromeSilver.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: _T.chromeSilver),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final xFile = XFile(path);
                  await Share.shareXFiles(
                    [xFile],
                    subject: 'Resumen del día · $_tituloDia',
                    text: 'Resumen del día generado desde AutoPlanificación.',
                  );
                } catch (e) {
                  if (!mounted) return;
                  _showSnackBar(
                    'No se pudo compartir: $e',
                    icon: Icons.error_outline,
                    color: _T.racingRed,
                  );
                }
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text(
                'COMPARTIR',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.dashGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportando = false);
      _showSnackBar(
        'Error al exportar: $e',
        icon: Icons.error_outline,
        color: _T.racingRed,
      );
    }
  }

  void _showSnackBar(
    String message, {
    IconData icon = Icons.info_outline,
    Color color = const Color(0xFF00E676),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _T.carbonSurface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.carbonDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _T.carbonLight,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _T.carbonGradient,
          ),
        ),
        title: const Text(
          'RESUMEN DEL DÍA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _T.dashGreen,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.file_download_outlined,
                color: _T.dashGreen,
              ),
              tooltip: 'Exportar a Excel',
              onPressed: _cargando ? null : _exportarExcel,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _T.racingRed),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: _T.racingRed,
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              color: _T.racingRed,
              backgroundColor: _T.carbonLight,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildSelectorDia(),
                  const SizedBox(height: 16),
                  _buildResumenKpis(),
                  const SizedBox(height: 20),
                  _buildSeccionFluidos(),
                  const SizedBox(height: 20),
                  _buildSeccionVehiculos(),
                  const SizedBox(height: 20),
                  _buildBotonExportar(),
                ],
              ),
            ),
    );
  }

  Widget _buildBotonExportar() {
    final tieneDatos = _porComponente.isNotEmpty || _porVehiculo.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (!tieneDatos || _exportando) ? null : _exportarExcel,
        icon: _exportando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.file_download_outlined, size: 20),
        label: Text(
          _exportando ? 'GENERANDO...' : 'EXPORTAR A EXCEL',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.dashGreen,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _T.asphaltGray.withValues(alpha: 0.5),
          disabledForegroundColor: _T.chromeSilver.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          shadowColor: _T.dashGreen.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSelectorDia() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: _T.carbonGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _cambiarDia(-1),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            tooltip: 'Día anterior',
          ),
          Expanded(
            child: InkWell(
              onTap: _elegirDia,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    const Text(
                      'FECHA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: _T.chromeSilver,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tituloDia,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _mismoDia(_diaSeleccionado, DateTime.now())
                ? null
                : () => _cambiarDia(1),
            icon: Icon(
              Icons.chevron_right,
              color: _mismoDia(_diaSeleccionado, DateTime.now())
                  ? _T.chromeSilver.withValues(alpha: 0.3)
                  : Colors.white,
            ),
            tooltip: 'Día siguiente',
          ),
        ],
      ),
    );
  }

  Widget _buildResumenKpis() {
    final totalReal = (_resumen['total_real'] as num?)?.toDouble() ?? 0.0;
    final totalTeorico = (_resumen['total_teorico'] as num?)?.toDouble() ?? 0.0;
    final diferencia = totalReal - totalTeorico;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.directions_car_filled,
                label: 'UNIDADES',
                value: '${_resumen['total_unidades'] ?? 0}',
                color: _T.electricBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.calculate,
                label: 'CÁLCULOS',
                value: '${_resumen['total_calculos'] ?? 0}',
                color: _T.warningAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.arrow_downward,
                label: 'ENTRADAS',
                value: '${_resumen['total_entradas'] ?? 0}',
                color: _T.dashGreen,
                small: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.arrow_upward,
                label: 'SALIDAS',
                value: '${_resumen['total_salidas'] ?? 0}',
                color: _T.neonOrange,
                small: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.check_circle_outline,
                label: 'EXACTOS',
                value: '${_resumen['total_exactos'] ?? 0}',
                color: _T.chromeSilver,
                small: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDiferenciaCard(diferencia, totalTeorico),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: small ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: _T.carbonGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(small ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: small ? 16 : 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: small ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _T.chromeSilver,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: small ? 15 : 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiferenciaCard(double diferencia, double totalTeorico) {
    final esPositivo = diferencia > 0;
    final esNegativo = diferencia < 0;
    final color = esPositivo
        ? _T.neonOrange
        : esNegativo
            ? _T.dashGreen
            : _T.chromeSilver;

    final porcentaje = totalTeorico > 0
        ? (diferencia / totalTeorico * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esPositivo
                  ? Icons.trending_up
                  : esNegativo
                      ? Icons.trending_down
                      : Icons.trending_flat,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIFERENCIA TOTAL DEL DÍA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _T.chromeSilver,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${esPositivo ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${esPositivo ? '+' : ''}$porcentaje%)',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TEÓRICO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: _T.chromeSilver.withValues(alpha: 0.7),
                ),
              ),
              Text(
                totalTeorico.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFluidos() {
    return _buildSeccion(
      titulo: 'FLUIDOS DEL DÍA',
      icono: Icons.water_drop,
      color: _T.electricBlue,
      child: _porComponente.isEmpty
          ? _buildVacio('No hay fluidos registrados este día')
          : Column(
              children: _porComponente.map((c) {
                final nombre = c['nombre']?.toString() ?? '';
                final totalReal = (c['total_real'] as num?)?.toDouble() ?? 0.0;
                final totalTeorico =
                    (c['total_teorico'] as num?)?.toDouble() ?? 0.0;
                final unidad = c['unidad']?.toString() ?? 'LT';
                final veces = (c['veces_usado'] as int?) ?? 0;
                final dif = totalReal - totalTeorico;

                return _buildFilaFluido(
                  nombre: nombre,
                  totalReal: totalReal,
                  totalTeorico: totalTeorico,
                  unidad: unidad,
                  veces: veces,
                  diferencia: dif,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFilaFluido({
    required String nombre,
    required double totalReal,
    required double totalTeorico,
    required String unidad,
    required int veces,
    required double diferencia,
  }) {
    final esPositivo = diferencia > 0;
    final esNegativo = diferencia < 0;
    final colorDif = esPositivo
        ? _T.neonOrange
        : esNegativo
            ? _T.dashGreen
            : _T.chromeSilver;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _T.electricBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$veces ${veces == 1 ? 'vez' : 'veces'}',
                  style: const TextStyle(
                    color: _T.electricBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniDato(
                  'REAL',
                  '${totalReal.toStringAsFixed(2)} $unidad',
                  _T.dashGreen,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _miniDato(
                  'TEÓRICO',
                  '${totalTeorico.toStringAsFixed(2)} $unidad',
                  _T.chromeSilver,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _miniDato(
                  'DIF.',
                  '${esPositivo ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                  colorDif,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDato(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionVehiculos() {
    return _buildSeccion(
      titulo: 'UNIDADES INGRESADAS',
      icono: Icons.directions_car,
      color: _T.dashGreen,
      child: _porVehiculo.isEmpty
          ? _buildVacio('No hay vehículos procesados este día')
          : Column(
              children: _porVehiculo.map((v) {
                final modelo = v['nombreVehiculo']?.toString() ?? '';
                final codigo = v['codigoVehiculo']?.toString() ?? '';
                final lote = v['loteVehiculo']?.toString() ?? '';
                final totalReal = (v['total_real'] as num?)?.toDouble() ?? 0.0;
                final totalTeorico =
                    (v['total_teorico'] as num?)?.toDouble() ?? 0.0;
                final calculos = (v['total_calculos'] as int?) ?? 0;
                final dif = totalReal - totalTeorico;

                return _buildFilaVehiculo(
                  modelo: modelo,
                  codigo: codigo,
                  lote: lote,
                  totalReal: totalReal,
                  totalTeorico: totalTeorico,
                  calculos: calculos,
                  diferencia: dif,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFilaVehiculo({
    required String modelo,
    required String codigo,
    required String lote,
    required double totalReal,
    required double totalTeorico,
    required int calculos,
    required double diferencia,
  }) {
    final esPositivo = diferencia > 0;
    final esNegativo = diferencia < 0;
    final colorDif = esPositivo
        ? _T.neonOrange
        : esNegativo
            ? _T.dashGreen
            : _T.chromeSilver;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _T.dashGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_filled,
              color: _T.dashGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (codigo.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _T.electricBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          codigo,
                          style: const TextStyle(
                            color: _T.electricBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (lote.isNotEmpty)
                      Expanded(
                        child: Text(
                          '· $lote',
                          style: TextStyle(
                            color: _T.chromeSilver.withValues(alpha: 0.8),
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                children: [
                  Text(
                    '$calculos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    calculos == 1 ? 'calc' : 'calcs',
                    style: const TextStyle(
                      color: _T.chromeSilver,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${esPositivo ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorDif,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildVacio(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 32,
            color: _T.chromeSilver.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _T.chromeSilver.withValues(alpha: 0.7),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
