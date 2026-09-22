import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

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
      // Convertir el día seleccionado en rango desde/hasta
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
          backgroundColor: esError ? Colors.red.shade700 : null,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.schedule_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Unidades por hora',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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

  Widget _buildSelectorDia() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: _seleccionarDia,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Día seleccionado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(_diaSeleccionado),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenTotales() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Resumen del día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniMetrica(
                  'Unidades',
                  '$_totalUnidades',
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildMiniMetrica(
                  'Entradas',
                  '$_totalEntradas',
                  Colors.greenAccent,
                ),
              ),
              Expanded(
                child: _buildMiniMetrica(
                  'Salidas',
                  '$_totalSalidas',
                  Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (_datos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin movimientos este día',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona otro día para ver datos',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
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
    // ✅ Ahora la hora viene en formato "YYYY-MM-DD HH:00:00"
    final horaRaw = item['hora']?.toString() ?? '';
    String horaBonita = horaRaw;

    // Extraer solo "HH:00" del formato completo
    try {
      final dt = DateTime.parse(horaRaw);
      horaBonita = DateFormat('HH:00').format(dt);
    } catch (_) {
      // Si falla, intentar extraer los últimos caracteres
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

    // Color según dominancia
    Color colorHora;
    if (entradas > salidas) {
      colorHora = Colors.green.shade700;
    } else if (salidas > entradas) {
      colorHora = Colors.orange.shade700;
    } else {
      colorHora = Colors.blue.shade700;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Hora + contador unidades
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorHora.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorHora.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorHora,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        horaBonita,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorHora,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '$unidades unidades',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fila 2: Cálculos / Entradas / Salidas
            Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    Icons.calculate_outlined,
                    'Cálculos',
                    '$calculos',
                    Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.arrow_downward,
                    'Entradas',
                    '$entradas',
                    Colors.green.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.arrow_upward,
                    'Salidas',
                    '$salidas',
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Fila 3: Totales L
            Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    Icons.water_drop,
                    'Real',
                    totalReal.toStringAsFixed(2),
                    Colors.orange.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.science_outlined,
                    'Teórico',
                    totalTeorico.toStringAsFixed(2),
                    Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMiniInfo(
                    Icons.compare_arrows,
                    'Diferencia',
                    (totalReal - totalTeorico).toStringAsFixed(2),
                    (totalReal - totalTeorico) > 0
                        ? Colors.red.shade700
                        : Colors.green.shade700,
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
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
