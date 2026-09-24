import 'package:flutter/material.dart';
import 'package:vehiculos_app/models/vehiculo.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/screens/calculos_vehiculo_screen.dart';

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

class LoteDetalleScreen extends StatefulWidget {
  /// Nombre del lote a mostrar. Si es null, muestra los vehículos sin lote.
  final String? lote;

  const LoteDetalleScreen({super.key, required this.lote});

  @override
  State<LoteDetalleScreen> createState() => _LoteDetalleScreenState();
}

class _LoteDetalleScreenState extends State<LoteDetalleScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Vehiculo> _vehiculos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final todos = await _db.getAllVehiculos();
      final filtrados = widget.lote == null
          ? todos.where((v) => v.lote == null || v.lote!.isEmpty).toList()
          : todos.where((v) => v.lote == widget.lote).toList();

      // ✅ Ordenar por código natural
      filtrados.sort((a, b) {
        final codA = a.codigo ?? '';
        final codB = b.codigo ?? '';

        final regex = RegExp(r'^([A-Z0-9]+)-(\d+)$');
        final mA = regex.firstMatch(codA);
        final mB = regex.firstMatch(codB);

        if (mA == null && mB == null) return codA.compareTo(codB);
        if (mA == null) return 1;
        if (mB == null) return -1;

        final prefA = mA.group(1)!;
        final prefB = mB.group(1)!;

        final cmpPref = prefA.compareTo(prefB);
        if (cmpPref != 0) return cmpPref;

        final numA = int.tryParse(mA.group(2)!) ?? 0;
        final numB = int.tryParse(mB.group(2)!) ?? 0;
        return numA.compareTo(numB);
      });

      if (!mounted) return;
      setState(() {
        _vehiculos = filtrados;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('❌ Error: $e');
    }
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
        Expanded(child: Container(height: 1, color: HudTheme.hudLine)),
      ],
    );
  }

  // ============================================================
  // ELIMINAR VEHÍCULO
  // ============================================================
  Future<void> _eliminarVehiculo(Vehiculo vehiculo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: HudTheme.hudPanel,
            border: Border.all(
              color: HudTheme.hudMagenta.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: HudTheme.hudLine, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HudTheme.hudMagenta.withValues(alpha: 0.12),
                        border: Border.all(
                          color: HudTheme.hudMagenta.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: HudTheme.hudMagenta, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ELIMINAR VEHÍCULO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '¿Eliminar "${vehiculo.modelo}"?',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: HudTheme.hudLine, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('CANCELAR',
                          style: TextStyle(
                              color: HudTheme.chromeSilver,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete,
                          size: 16, color: Colors.white),
                      label: const Text('ELIMINAR',
                          style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w900,
                              fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HudTheme.hudMagenta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && vehiculo.idVehiculo != null) {
      await _db.deleteVehiculo(vehiculo.idVehiculo!);
      await _cargar();
      if (mounted) {
        _showSnack('Vehículo eliminado');
      }
    }
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

  void _navegarACalculos(Vehiculo vehiculo) {
    if (vehiculo.idVehiculo == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoCalculoScreen(
          idVehiculo: vehiculo.idVehiculo!,
          nombreVehiculo: vehiculo.modelo,
          codigoVehiculo: vehiculo.codigo,
        ),
      ),
    ).then((_) => _cargar());
  }

  String _formatDate(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} · $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.lote ?? 'Sin lote';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 2.5,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${_vehiculos.length} ${_vehiculos.length == 1 ? 'VEHÍCULO' : 'VEHÍCULOS'}',
              style: TextStyle(
                fontSize: 10,
                color: HudTheme.hudCyan.withValues(alpha: 0.8),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: HudTheme.hudCyan),
              )
            : _vehiculos.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: HudTheme.hudCyan,
                    backgroundColor: HudTheme.hudPanel,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      children: [
                        // Panel header con resumen
                        _buildHudPanel(
                          accent: HudTheme.hudCyan,
                          cornerLabel: 'SYS::LOTE',
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      HudTheme.hudCyan.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color:
                                        HudTheme.hudCyan.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: HudTheme.hudCyan,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_vehiculos.length} ${_vehiculos.length == 1 ? 'unidad' : 'unidades'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: HudTheme.chromeSilver,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHudHeader('UNIDADES'),
                        const SizedBox(height: 12),
                        ...List.generate(_vehiculos.length, (i) {
                          return _buildCard(_vehiculos[i], i);
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
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
                Icons.inbox_outlined,
                size: 60,
                color: HudTheme.hudCyan,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '// NO HAY VEHÍCULOS EN ESTE LOTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Vehiculo vehiculo, int index) {
    // Rotamos entre los colores HUD
    final acentos = [
      HudTheme.hudCyan,
      HudTheme.hudLime,
      HudTheme.hudMagenta,
      const Color(0xFFFFB800),
      const Color(0xFF7C4DFF),
    ];
    final color = acentos[index % acentos.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _navegarACalculos(vehiculo),
        child: _buildHudPanel(
          accent: color,
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
                      color: color.withValues(alpha: 0.12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.directions_car_filled,
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_2, size: 11, color: color),
                              const SizedBox(width: 4),
                              Text(
                                vehiculo.codigo ?? 'SIN-COD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          vehiculo.modelo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 0.3,
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
                      color: HudTheme.hudMagenta,
                    ),
                    onPressed: () => _eliminarVehiculo(vehiculo),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
              if (vehiculo.createdAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(color: HudTheme.hudLine, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 11,
                        color: HudTheme.chromeSilver,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REGISTRADO: ${_formatDate(vehiculo.createdAt!)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: HudTheme.chromeSilver,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navegarACalculos(vehiculo),
                  icon: const Icon(Icons.assessment_outlined, size: 16),
                  label: const Text(
                    'VER CÁLCULOS',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.15),
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                      side: BorderSide(
                          color: color.withValues(alpha: 0.5), width: 1),
                    ),
                    elevation: 0,
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
