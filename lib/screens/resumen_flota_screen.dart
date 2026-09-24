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

class ResumenFlotaScreen extends StatefulWidget {
  const ResumenFlotaScreen({super.key});

  @override
  State<ResumenFlotaScreen> createState() => _ResumenFlotaScreenState();
}

class _ResumenFlotaScreenState extends State<ResumenFlotaScreen> {
  final DatabaseHelper db = DatabaseHelper();
  List<Map<String, dynamic>> _datos = [];
  bool _cargando = true;
  String _busqueda = '';
  String _orden = 'unidades';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final data = await db.obtenerConteoPorModelo();
      if (!mounted) return;
      setState(() {
        _datos = data;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  String _formatearFecha(dynamic raw) {
    if (raw == null) return 'Sin fecha';
    try {
      final t = raw.toString().replaceFirst(' ', 'T');
      final f = DateTime.parse(t.endsWith('Z') ? t : '${t}Z').toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(f);
    } catch (_) {
      return raw.toString();
    }
  }

  IconData _iconoDe(String modelo) {
    final m = modelo.toUpperCase();
    if (m.contains('POER')) return Icons.local_shipping;
    if (m.contains('WINGLE')) return Icons.agriculture;
    if (m.contains('VAN') || m.contains('V7') || m.contains('V3')) {
      return Icons.airport_shuttle;
    }
    if (m.contains('G01')) return Icons.directions_car_filled;
    return Icons.directions_car;
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

  @override
  Widget build(BuildContext context) {
    final filtrados = _datos.where((d) {
      if (_busqueda.isEmpty) return true;
      final m = d['modelo']?.toString().toUpperCase() ?? '';
      return m.contains(_busqueda.toUpperCase());
    }).toList();

    switch (_orden) {
      case 'alfabetico':
        filtrados.sort(
            (a, b) => (a['modelo'] as String).compareTo(b['modelo'] as String));
        break;
      case 'reciente':
        filtrados.sort((a, b) {
          final fa = a['ultimo_registro']?.toString() ?? '';
          final fb = b['ultimo_registro']?.toString() ?? '';
          return fb.compareTo(fa);
        });
        break;
      default:
        filtrados.sort((a, b) => ((b['unidades'] as num?)?.toInt() ?? 0)
            .compareTo((a['unidades'] as num?)?.toInt() ?? 0));
    }

    final totalUnidades = _datos.fold<int>(
      0,
      (sum, d) => sum + ((d['unidades'] as num?)?.toInt() ?? 0),
    );

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
              child: const Icon(Icons.bar_chart,
                  color: HudTheme.hudCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'RESUMEN FLOTA',
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
          PopupMenuButton<String>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort, color: HudTheme.hudCyan),
            initialValue: _orden,
            color: HudTheme.hudPanel,
            onSelected: (v) => setState(() => _orden = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'unidades',
                child: Row(children: [
                  Icon(Icons.trending_up, size: 18, color: HudTheme.hudCyan),
                  SizedBox(width: 8),
                  Text('Por unidades', style: TextStyle(color: Colors.white)),
                ]),
              ),
              PopupMenuItem(
                value: 'alfabetico',
                child: Row(children: [
                  Icon(Icons.sort_by_alpha, size: 18, color: HudTheme.hudCyan),
                  SizedBox(width: 8),
                  Text('Alfabético', style: TextStyle(color: Colors.white)),
                ]),
              ),
              PopupMenuItem(
                value: 'reciente',
                child: Row(children: [
                  Icon(Icons.access_time, size: 18, color: HudTheme.hudCyan),
                  SizedBox(width: 8),
                  Text('Más reciente', style: TextStyle(color: Colors.white)),
                ]),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh, color: HudTheme.hudCyan),
            onPressed: _cargar,
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: HudTheme.hudCyan),
              )
            : RefreshIndicator(
                onRefresh: _cargar,
                color: HudTheme.hudCyan,
                backgroundColor: HudTheme.hudPanel,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header HUD
                    _buildHudPanel(
                      accent: HudTheme.hudCyan,
                      cornerLabel: 'SYS::FLEET',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color:
                                      HudTheme.hudCyan.withValues(alpha: 0.12),
                                  border: Border.all(
                                      color: HudTheme.hudCyan
                                          .withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.garage_outlined,
                                  color: HudTheme.hudCyan,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL EN FLOTA',
                                      style: TextStyle(
                                        color: HudTheme.chromeSilver,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '$totalUnidades',
                                          style: const TextStyle(
                                            color: HudTheme.hudCyan,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          totalUnidades == 1
                                              ? 'unidad'
                                              : 'unidades',
                                          style: TextStyle(
                                            color: HudTheme.hudCyan
                                                .withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_datos.length} ${_datos.length == 1 ? 'modelo distinto' : 'modelos distintos'}',
                                      style: const TextStyle(
                                        color: HudTheme.chromeSilver,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              border:
                                  Border.all(color: HudTheme.hudLine, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMiniMetrica(
                                  Icons.directions_car,
                                  '$totalUnidades',
                                  'UNIDADES',
                                  HudTheme.hudCyan,
                                ),
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: HudTheme.hudLine),
                                _buildMiniMetrica(
                                  Icons.list_alt,
                                  '${_datos.length}',
                                  'MODELOS',
                                  HudTheme.hudLime,
                                ),
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: HudTheme.hudLine),
                                _buildMiniMetrica(
                                  Icons.filter_alt_outlined,
                                  '${filtrados.length}',
                                  'VISIBLES',
                                  HudTheme.hudMagenta,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Buscador HUD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(color: HudTheme.hudLine, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: HudTheme.hudCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _busqueda = v.trim()),
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              cursorColor: HudTheme.hudCyan,
                              decoration: const InputDecoration(
                                hintText: 'BUSCAR MODELO...',
                                hintStyle: TextStyle(
                                  color: HudTheme.chromeSilver,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          if (_busqueda.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: HudTheme.hudCyan),
                              onPressed: () => setState(() => _busqueda = ''),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Lista
                    if (filtrados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color:
                                      HudTheme.hudCyan.withValues(alpha: 0.05),
                                  border: Border.all(
                                      color: HudTheme.hudLine, width: 1),
                                ),
                                child: const Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: HudTheme.hudCyan,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _busqueda.isEmpty
                                    ? '// SIN VEHÍCULOS REGISTRADOS'
                                    : '// SIN RESULTADOS PARA "$_busqueda"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtrados.map((d) => _buildModeloCard(d)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModeloCard(Map<String, dynamic> d) {
    final modelo = d['modelo']?.toString() ?? '';
    final unidades = (d['unidades'] as num?)?.toInt() ?? 0;
    final fechaTxt = _formatearFecha(d['ultimo_registro']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildHudPanel(
        accent: HudTheme.hudCyan,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: HudTheme.hudCyan.withValues(alpha: 0.12),
                border:
                    Border.all(color: HudTheme.hudCyan.withValues(alpha: 0.5)),
              ),
              child: Icon(
                _iconoDe(modelo),
                color: HudTheme.hudCyan,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 10, color: HudTheme.chromeSilver),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fechaTxt,
                          style: const TextStyle(
                            fontSize: 10,
                            color: HudTheme.chromeSilver,
                            letterSpacing: 0.3,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: HudTheme.hudCyan.withValues(alpha: 0.10),
                border:
                    Border.all(color: HudTheme.hudCyan.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    '$unidades',
                    style: const TextStyle(
                      color: HudTheme.hudCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unidades == 1 ? 'UNIDAD' : 'UNIDADES',
                    style: const TextStyle(
                      color: HudTheme.chromeSilver,
                      fontSize: 8,
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

  Widget _buildMiniMetrica(
      IconData icono, String valor, String label, Color color) {
    return Column(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
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
}
