import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/ciauto_theme.dart';

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
      backgroundColor: CiautoColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CiautoColors.red,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Resumen de flota',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort),
            initialValue: _orden,
            onSelected: (v) => setState(() => _orden = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'unidades',
                child: Row(children: [
                  Icon(Icons.trending_up, size: 18),
                  SizedBox(width: 8),
                  Text('Por unidades'),
                ]),
              ),
              PopupMenuItem(
                value: 'alfabetico',
                child: Row(children: [
                  Icon(Icons.sort_by_alpha, size: 18),
                  SizedBox(width: 8),
                  Text('Alfabético'),
                ]),
              ),
              PopupMenuItem(
                value: 'reciente',
                child: Row(children: [
                  Icon(Icons.access_time, size: 18),
                  SizedBox(width: 8),
                  Text('Más reciente'),
                ]),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: CiautoColors.red),
              )
            : RefreshIndicator(
                onRefresh: _cargar,
                color: CiautoColors.red,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header CIAUTO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: CiautoColors.redGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: CiautoColors.red.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.garage_outlined,
                              color: Colors.white,
                              size: 30,
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
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalUnidades ${totalUnidades == 1 ? 'unidad' : 'unidades'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_datos.length} ${_datos.length == 1 ? 'modelo distinto' : 'modelos distintos'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Buscador
                    TextField(
                      onChanged: (v) => setState(() => _busqueda = v.trim()),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Buscar modelo...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _busqueda = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Lista de modelos
                    if (filtrados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off,
                                  size: 70, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _busqueda.isEmpty
                                    ? 'Sin vehículos registrados'
                                    : 'Sin resultados para "$_busqueda"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtrados.map((d) {
                        final modelo = d['modelo']?.toString() ?? '';
                        final unidades = (d['unidades'] as num?)?.toInt() ?? 0;
                        final fechaTxt = _formatearFecha(d['ultimo_registro']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: CiautoColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  gradient: CiautoColors.redGradient,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                ),
                                child: Icon(
                                  _iconoDe(modelo),
                                  color: Colors.white,
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
                                        fontWeight: FontWeight.bold,
                                        color: CiautoColors.dark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 11,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            fechaTxt,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: CiautoColors.redLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: CiautoColors.red
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$unidades',
                                      style: const TextStyle(
                                        color: CiautoColors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      unidades == 1 ? 'unidad' : 'unidades',
                                      style: const TextStyle(
                                        color: CiautoColors.redDark,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
