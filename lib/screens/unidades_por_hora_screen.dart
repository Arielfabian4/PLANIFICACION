import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

// ============================================================
// 🏎️ TEMA HUD AUTOMOTRIZ
// ============================================================
class HudTheme {
  static const Color hudBg = Color(0xFF050A0F);
  static const Color hudPanel = Color(0xFF0A1419);
  static const Color hudLine = Color(0xFF1A3038);
  static const Color hudCyan = Color(0xFF00E5FF);
  static const Color hudMagenta = Color(0xFFFF006E);
  static const Color hudLime = Color(0xFF00FF88);
  static const Color chromeSilver = Color(0xFFB0BEC5);
}

// 🎨 Panel HUD con esquinas cortadas
class _HudPanelPainter extends CustomPainter {
  final Color accent;
  _HudPanelPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 14.0;
    final paintFill = Paint()
      ..color = HudTheme.hudPanel
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

    canvas.drawLine(
      Offset(cut + 6, 0),
      Offset(size.width * 0.4, 0),
      paintAccent,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width - cut - 6, size.height),
      paintAccent,
    );

    final cornerPaint = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        const Offset(cut, 0), const Offset(cut + 10, 0), cornerPaint);
    canvas.drawLine(Offset(size.width - cut - 10, 0),
        Offset(size.width - cut, 0), cornerPaint);
    canvas.drawLine(Offset(0, size.height - cut),
        Offset(0, size.height - cut + 10), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height - cut - 10),
        Offset(size.width, size.height - cut), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _HudPanelPainter old) => old.accent != accent;
}

class UnidadesPorHoraScreen extends StatefulWidget {
  const UnidadesPorHoraScreen({super.key});

  @override
  State<UnidadesPorHoraScreen> createState() => _UnidadesPorHoraScreenState();
}

class _UnidadesPorHoraScreenState extends State<UnidadesPorHoraScreen> {
  final db = DatabaseHelper();

  DateTime _diaSeleccionado = DateTime.now();
  List<Map<String, dynamic>> _datos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final desde = DateTime(
        _diaSeleccionado.year,
        _diaSeleccionado.month,
        _diaSeleccionado.day,
        0,
        0,
        0,
      );
      final hasta = DateTime(
        _diaSeleccionado.year,
        _diaSeleccionado.month,
        _diaSeleccionado.day,
        23,
        59,
        59,
      );

      final data = await db.obtenerResumenPorHora(
        desde: desde,
        hasta: hasta,
      );

      if (!mounted) return;
      setState(() {
        _datos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error: $e', esError: true);
    }
  }

  Future<void> _seleccionarDia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona el día',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HudTheme.hudCyan,
              onPrimary: Colors.black,
              surface: HudTheme.hudPanel,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: HudTheme.hudPanel,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => _diaSeleccionado = picked);
    await _cargarDatos();
  }

  void _showSnack(String msg, {bool esError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: esError ? HudTheme.hudMagenta : HudTheme.hudPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: BorderSide(
              color: (esError ? HudTheme.hudMagenta : HudTheme.hudLime)
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
      );
  }

  int get _totalUnidades => _datos.fold<int>(
        0,
        (sum, d) => sum + ((d['total_unidades'] as num?)?.toInt() ?? 0),
      );

  int get _totalEntradas => _datos.fold<int>(
        0,
        (sum, d) => sum + ((d['entradas'] as num?)?.toInt() ?? 0),
      );

  int get _totalSalidas => _datos.fold<int>(
        0,
        (sum, d) => sum + ((d['salidas'] as num?)?.toInt() ?? 0),
      );

  int get _totalCalculos => _datos.fold<int>(
        0,
        (sum, d) => sum + ((d['calculos'] as num?)?.toInt() ?? 0),
      );

  double get _totalReal => _datos.fold<double>(
        0.0,
        (sum, d) => sum + ((d['total_real'] as num?)?.toDouble() ?? 0.0),
      );

  double get _totalTeorico => _datos.fold<double>(
        0.0,
        (sum, d) => sum + ((d['total_teorico'] as num?)?.toDouble() ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HudTheme.hudBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HudTheme.hudPanel,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050A0F), Color(0xFF0A1419)],
            ),
            border: Border(
              bottom: BorderSide(color: HudTheme.hudCyan, width: 2),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HudTheme.hudCyan.withValues(alpha: 0.15),
                border:
                    Border.all(color: HudTheme.hudCyan.withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.schedule_outlined,
                  color: HudTheme.hudCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'UNIDADES / HORA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh, color: HudTheme.hudCyan),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: HudTheme.hudCyan),
              )
            : Column(
                children: [
                  _buildSelectorDia(),
                  _buildResumenTotales(),
                  Expanded(child: _buildLista()),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // HELPERS HUD
  // ============================================================

  Widget _buildHudPanel({
    required Widget child,
    Color accent = HudTheme.hudCyan,
    EdgeInsets? padding,
    String? cornerLabel,
  }) {
    return CustomPaint(
      painter: _HudPanelPainter(accent: accent),
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
                  color: HudTheme.hudBg,
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

  Widget _buildHudHeader(String titulo, {Color accent = HudTheme.hudCyan}) {
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
          child: Container(height: 1, color: HudTheme.hudLine),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTOR DÍA
  // ============================================================

  Widget _buildSelectorDia() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: _seleccionarDia,
        child: _buildHudPanel(
          accent: HudTheme.hudCyan,
          cornerLabel: 'SYS::DATE',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HudTheme.hudCyan.withValues(alpha: 0.12),
                  border: Border.all(
                      color: HudTheme.hudCyan.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: HudTheme.hudCyan,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'DÍA SELECCIONADO',
                  style: TextStyle(
                    fontSize: 10,
                    color: HudTheme.chromeSilver,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(_diaSeleccionado),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_drop_down, color: HudTheme.hudCyan),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMEN TOTALES
  // ============================================================

  Widget _buildResumenTotales() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _buildHudPanel(
        accent: HudTheme.hudCyan,
        cornerLabel: 'SYS::DAY',
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHudHeader('RESUMEN DEL DÍA'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetrica(
                    'UNIDADES',
                    '$_totalUnidades',
                    HudTheme.hudCyan,
                  ),
                ),
                Expanded(
                  child: _buildMiniMetrica(
                    'ENTRADAS',
                    '+$_totalEntradas',
                    HudTheme.hudLime,
                  ),
                ),
                Expanded(
                  child: _buildMiniMetrica(
                    'SALIDAS',
                    '-$_totalSalidas',
                    HudTheme.hudMagenta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(color: HudTheme.hudLine, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetrica(
                    'CÁLCULOS',
                    '$_totalCalculos',
                    Colors.white,
                  ),
                  Container(width: 1, height: 30, color: HudTheme.hudLine),
                  _buildMiniMetrica(
                    'REAL (L)',
                    _totalReal.toStringAsFixed(2),
                    HudTheme.hudCyan,
                  ),
                  Container(width: 1, height: 30, color: HudTheme.hudLine),
                  _buildMiniMetrica(
                    'TEÓRICO (L)',
                    _totalTeorico.toStringAsFixed(2),
                    HudTheme.hudMagenta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetrica(String label, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: HudTheme.chromeSilver,
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LISTA
  // ============================================================

  Widget _buildLista() {
    if (_datos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: HudTheme.hudCyan.withValues(alpha: 0.05),
                  border: Border.all(color: HudTheme.hudLine, width: 1),
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 60,
                  color: HudTheme.hudCyan,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '// SIN MOVIMIENTOS ESTE DÍA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona otro día para ver datos',
                style: TextStyle(
                    fontSize: 11,
                    color: HudTheme.chromeSilver,
                    letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _datos.length,
      itemBuilder: (context, index) {
        return _buildHoraCard(_datos[index]);
      },
    );
  }

  Widget _buildHoraCard(Map<String, dynamic> item) {
    final horaRaw = item['hora']?.toString() ?? '';
    String horaBonita = horaRaw;

    try {
      final dt = DateTime.parse(horaRaw);
      horaBonita = DateFormat('HH:00').format(dt);
    } catch (_) {
      if (horaRaw.length >= 13) {
        horaBonita = '${horaRaw.substring(11, 13)}:00';
      }
    }

    final calculos = (item['calculos'] as num?)?.toInt() ?? 0;
    final unidades = (item['total_unidades'] as num?)?.toInt() ?? 0;
    final entradas = (item['entradas'] as num?)?.toInt() ?? 0;
    final salidas = (item['salidas'] as num?)?.toInt() ?? 0;
    final totalReal = (item['total_real'] as num?)?.toDouble() ?? 0.0;
    final totalTeorico = (item['total_teorico'] as num?)?.toDouble() ?? 0.0;
    final diferencia = totalReal - totalTeorico;

    // Color de acento según dominancia
    Color accent;
    if (entradas > salidas) {
      accent = HudTheme.hudLime;
    } else if (salidas > entradas) {
      accent = HudTheme.hudMagenta;
    } else {
      accent = HudTheme.hudCyan;
    }

    final colorDif = diferencia > 0
        ? HudTheme.hudMagenta
        : diferencia < 0
            ? HudTheme.hudLime
            : HudTheme.chromeSilver;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildHudPanel(
        accent: accent,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Hora + unidades
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        horaBonita,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$unidades',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'UNIDADES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: HudTheme.chromeSilver,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: HudTheme.hudLine),
            const SizedBox(height: 12),

            // Fila 2: Cálculos / Entradas / Salidas
            Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    Icons.calculate_outlined,
                    'CÁLCULOS',
                    '$calculos',
                    HudTheme.hudCyan,
                  ),
                ),
                Container(width: 1, height: 30, color: HudTheme.hudLine),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.arrow_downward,
                    'ENTRADAS',
                    '+$entradas',
                    HudTheme.hudLime,
                  ),
                ),
                Container(width: 1, height: 30, color: HudTheme.hudLine),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.arrow_upward,
                    'SALIDAS',
                    '-$salidas',
                    HudTheme.hudMagenta,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: HudTheme.hudLine),
            const SizedBox(height: 12),

            // Fila 3: Totales L
            Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    Icons.water_drop_outlined,
                    'REAL',
                    totalReal.toStringAsFixed(2),
                    HudTheme.hudCyan,
                  ),
                ),
                Container(width: 1, height: 30, color: HudTheme.hudLine),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.science_outlined,
                    'TEÓRICO',
                    totalTeorico.toStringAsFixed(2),
                    HudTheme.hudMagenta,
                  ),
                ),
                Container(width: 1, height: 30, color: HudTheme.hudLine),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.compare_arrows,
                    'DIFERENCIA',
                    '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                    colorDif,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(
    IconData icono,
    String label,
    String valor,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: HudTheme.chromeSilver,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
