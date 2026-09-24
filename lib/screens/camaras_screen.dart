import 'package:flutter/material.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/models/vehiculo.dart';

class CamarasScreen extends StatefulWidget {
  const CamarasScreen({super.key});

  @override
  State<CamarasScreen> createState() => _CamarasScreenState();
}

class _CamarasScreenState extends State<CamarasScreen> {
  final db = DatabaseHelper();

  String _areaSeleccionada = 'CHASIS';
  List<Map<String, dynamic>> _wip = [];
  Map<String, dynamic> _resumenPlanta = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final wip = await db.obtenerWipPorCamara();
      final resumen = await db.obtenerResumenPlanta();
      if (!mounted) return;
      setState(() {
        _wip = wip;
        _resumenPlanta = resumen;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _showSnack('Error al cargar: $e', esError: true);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _wipEnCamara(int camara) {
    return _wip
        .where((w) => w['area'] == _areaSeleccionada && w['camara'] == camara)
        .fold<int>(
          0,
          (sum, w) => sum + ((w['total_vehiculos'] as num?)?.toInt() ?? 0),
        );
  }

  int _wipEnArea(String area) {
    return _wip.where((w) => w['area'] == area).fold<int>(
          0,
          (sum, w) => sum + ((w['total_vehiculos'] as num?)?.toInt() ?? 0),
        );
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
          backgroundColor:
              esError ? Colors.red.shade700 : Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.precision_manufacturing, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Planta de ensamble',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargar,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildResumenPlanta(primary),
                    const SizedBox(height: 16),
                    _buildSelectorArea(),
                    const SizedBox(height: 16),
                    _buildTituloArea(primary),
                    const SizedBox(height: 12),
                    _buildGridCamaras(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // RESUMEN GENERAL DE LA PLANTA
  // ============================================================

  Widget _buildResumenPlanta(Color primary) {
    final enProceso = _resumenPlanta['en_proceso'] ?? 0;
    final entregados = _resumenPlanta['entregados'] ?? 0;
    final sinUbicar = _resumenPlanta['sin_ubicar'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.factory_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'ESTADO DE LA PLANTA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricaPlanta(
                  'EN PROCESO',
                  '$enProceso',
                  Colors.white,
                  Icons.precision_manufacturing,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildMetricaPlanta(
                  'ENTREGADOS',
                  '$entregados',
                  Colors.greenAccent,
                  Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildMetricaPlanta(
                  'SIN UBICAR',
                  '$sinUbicar',
                  Colors.orangeAccent,
                  Icons.help_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaPlanta(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTOR DE ÁREA (CHASIS / COMPACTOS)
  // ============================================================

  Widget _buildSelectorArea() {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: Vehiculo.areasDisponibles.map((area) {
        final selected = _areaSeleccionada == area;
        final count = _wipEnArea(area);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: area == Vehiculo.areasDisponibles.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _areaSeleccionada = area),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? primary : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      area,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count en proceso',
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // TÍTULO DEL ÁREA ACTUAL
  // ============================================================

  Widget _buildTituloArea(Color primary) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: primary),
        const SizedBox(width: 8),
        Text(
          _areaSeleccionada,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_wipEnArea(_areaSeleccionada)} en proceso',
            style: TextStyle(
              fontSize: 11,
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GRID DE CÁMARAS (1 a 10)
  // ============================================================

  Widget _buildGridCamaras() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: Vehiculo.totalCamaras,
      itemBuilder: (context, i) => _buildCamaraCard(i + 1),
    );
  }

  Widget _buildCamaraCard(int camara) {
    final total = _wipEnCamara(camara);
    final activa = total > 0;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _abrirCamara(camara),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activa ? primary : Colors.grey.shade200,
            width: activa ? 2 : 1,
          ),
          boxShadow: activa
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (activa ? primary : Colors.grey)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_outlined,
                    color: activa ? primary : Colors.grey,
                    size: 16,
                  ),
                ),
                const Spacer(),
                if (activa)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              'C$camara',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: activa ? Colors.black87 : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              activa ? '$total vehículo${total == 1 ? '' : 's'}' : 'Vacía',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET: VEHÍCULOS EN CÁMARA
  // ============================================================

  Future<void> _abrirCamara(int camara) async {
    final vehiculos =
        await db.obtenerVehiculosEnCamara(_areaSeleccionada, camara);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_areaSeleccionada · C$camara',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehiculos.length} vehículo${vehiculos.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${vehiculos.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: vehiculos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin vehículos en esta cámara',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: vehiculos.length,
                      itemBuilder: (context, i) =>
                          _buildVehiculoTile(vehiculos[i]),
                    ),
            ),
          ],
        ),
      ),
    ).then((_) => _cargar());
  }

  Widget _buildVehiculoTile(Vehiculo v) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.directions_car, color: primary, size: 22),
      ),
      title: Text(
        v.modelo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.codigo ?? 'SIN-COD',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.access_time, size: 10, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'En esta cámara: ${v.tiempoEnCamara}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 14),
        onPressed: () => _moverVehiculo(v),
        tooltip: 'Mover a otra cámara',
      ),
    );
  }

  // ============================================================
  // MOVER VEHÍCULO A OTRA CÁMARA
  // ============================================================

  Future<void> _moverVehiculo(Vehiculo v) async {
    if (v.idVehiculo == null) return;

    String areaSel = v.areaActual ?? 'CHASIS';
    int camaraSel = v.camaraActual ?? 1;
    final notasController = TextEditingController();
    bool entregar = false;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Mover vehículo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del vehículo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.modelo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              v.codigo ?? 'SIN-COD',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de área
                const Text(
                  'Área:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: Vehiculo.areasDisponibles.map((area) {
                    final selected = areaSel == area;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right:
                                area == Vehiculo.areasDisponibles.last ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setStateDialog(() => areaSel = area),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                area,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selector de cámara
                const Text(
                  'Cámara (1-10):',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(Vehiculo.totalCamaras, (i) {
                    final num = i + 1;
                    final selected = camaraSel == num;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => camaraSel = num),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$num',
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Notas
                TextField(
                  controller: notasController,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Pasó a control de calidad',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Checkbox: entregar
                CheckboxListTile(
                  value: entregar,
                  onChanged: (val) =>
                      setStateDialog(() => entregar = val ?? false),
                  title: const Text(
                    'Marcar como ENTREGADO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'El vehículo sale del flujo de producción',
                    style: TextStyle(fontSize: 10),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, {
                'area': areaSel,
                'camara': camaraSel,
                'notas': notasController.text.trim(),
                'entregado': entregar,
              }),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Mover'),
            ),
          ],
        ),
      ),
    );

    if (resultado == null) return;

    try {
      await db.moverVehiculoACamara(
        v.idVehiculo!,
        area: resultado['area'] as String,
        camara: resultado['camara'] as int,
        notas: resultado['notas'] as String?,
        entregado: resultado['entregado'] as bool? ?? false,
      );

      await _cargar();

      if (mounted) {
        Navigator.pop(context); // Cierra el bottom sheet
        _showSnack(
          resultado['entregado'] == true
              ? '✅ Vehículo marcado como ENTREGADO'
              : '✅ Movido a ${resultado['area']} · C${resultado['camara']}',
        );
      }
    } catch (e) {
      _showSnack('Error al mover: $e', esError: true);
    }
  }
}
