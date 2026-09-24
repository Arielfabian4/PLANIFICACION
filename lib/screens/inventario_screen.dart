import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vehiculos_app/models/inventario.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/screens/generar_qr_screen.dart';

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
  static const Color warningAmber = Color(0xFFFFC107);
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

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final db = DatabaseHelper();
  List<Inventario> _inventario = [];
  List<Inventario> _inventarioFiltrado = [];
  bool _isLoading = true;

  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _loadInventario();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // ==================== CARGA DE DATOS ====================

  Future<void> _loadInventario({bool mostrarLoading = true}) async {
    if (!mounted) return;

    if (mostrarLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final data = await db.getInventario();
      if (!mounted) return;

      final nuevoInventario = data.map((e) => Inventario.fromMap(e)).toList();

      setState(() {
        _inventario = nuevoInventario;
        _inventarioFiltrado = _filtrar(nuevoInventario, _busqueda);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar inventario: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error al cargar: $e', esError: true);
    }
  }

  List<Inventario> _filtrar(List<Inventario> lista, String query) {
    if (query.isEmpty) return lista;
    final q = query.toLowerCase();
    return lista.where((i) => i.nombre.toLowerCase().contains(q)).toList();
  }

  void _onBuscar(String value) {
    setState(() {
      _busqueda = value;
      _inventarioFiltrado = _filtrar(_inventario, value);
    });
  }

  // ==================== OPERACIONES DE STOCK ====================

  Future<bool> _sumarStock(Inventario item, String texto) async {
    if (item.id == null) return false;

    final cantidad = double.tryParse(texto.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      _showSnack('Ingresa una cantidad válida mayor a 0', esError: true);
      return false;
    }

    final nuevoStock = item.stockActual + cantidad;

    try {
      await db.updateStock(item.id!, nuevoStock);
      await _loadInventario(mostrarLoading: false);
      if (mounted) {
        _showSnack(
          '✅ Sumado ${cantidad.toStringAsFixed(2)} → Total: ${nuevoStock.toStringAsFixed(2)}',
        );
      }
      return true;
    } catch (e) {
      if (mounted) _showSnack('Error al sumar: $e', esError: true);
      return false;
    }
  }

  Future<bool> _restarStock(Inventario item, String texto) async {
    if (item.id == null) return false;

    final cantidad = double.tryParse(texto.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      _showSnack('Ingresa una cantidad válida mayor a 0', esError: true);
      return false;
    }

    if (cantidad > item.stockActual) {
      _showSnack(
        'No puedes restar más de lo que hay (${item.stockActual.toStringAsFixed(2)})',
        esError: true,
      );
      return false;
    }

    final nuevoStock = item.stockActual - cantidad;

    try {
      await db.updateStock(item.id!, nuevoStock);
      await _loadInventario(mostrarLoading: false);
      if (mounted) {
        _showSnack(
          '✅ Restado ${cantidad.toStringAsFixed(2)} → Total: ${nuevoStock.toStringAsFixed(2)}',
        );
      }
      return true;
    } catch (e) {
      if (mounted) _showSnack('Error al restar: $e', esError: true);
      return false;
    }
  }

  Future<void> _agregarProducto() async {
    final nombre = await _showDialogAgregarProducto();
    if (nombre == null || nombre.trim().isEmpty) return;

    try {
      await db.insertProductoStock(nombre.trim(), 0);
      await _loadInventario(mostrarLoading: false);
      if (mounted) _showSnack('Producto agregado con éxito');
    } catch (e) {
      if (mounted) _showSnack('Error: $e', esError: true);
    }
  }

  // ==================== ELIMINAR PRODUCTO ====================

  Future<void> _eliminarProducto(Inventario item) async {
    if (item.id == null) {
      _showSnack('Producto sin ID válido', esError: true);
      return;
    }

    final confirmar = await _showDialogConfirmarEliminar(item);
    if (confirmar != true) return;

    try {
      await db.eliminarProducto(item.id!);
      await _loadInventario(mostrarLoading: false);
      if (mounted) {
        _showSnack('✅ "${item.nombre}" eliminado del inventario');
      }
    } catch (e) {
      if (mounted) _showSnack('Error al eliminar: $e', esError: true);
    }
  }

  Future<bool?> _showDialogConfirmarEliminar(Inventario item) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: HudTheme.hudPanel,
            border: Border.all(
              color: HudTheme.hudMagenta.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
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
                      child: const Icon(Icons.warning_amber_rounded,
                          color: HudTheme.hudMagenta, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ELIMINAR PRODUCTO',
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
              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vas a eliminar este producto del inventario:',
                      style: TextStyle(
                        color: HudTheme.chromeSilver,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(color: HudTheme.hudLine, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Stock actual: ',
                                style: TextStyle(
                                  color: HudTheme.chromeSilver,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                item.stockActual.toStringAsFixed(2),
                                style: TextStyle(
                                  color: item.stockActual > 0
                                      ? HudTheme.hudLime
                                      : HudTheme.hudMagenta,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '⚠️ Esta acción no se puede deshacer.',
                      style: TextStyle(
                        color: HudTheme.hudMagenta,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Acciones
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: HudTheme.hudLine, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: HudTheme.chromeSilver,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.delete_forever,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'ELIMINAR',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
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
  }

  // ==================== UTILIDADES ====================

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

  Future<String?> _showDialogAgregarProducto() async {
    final controller = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: HudTheme.hudPanel,
            border: Border.all(
              color: HudTheme.hudCyan.withValues(alpha: 0.6),
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
                        color: HudTheme.hudCyan.withValues(alpha: 0.12),
                        border: Border.all(
                          color: HudTheme.hudCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(Icons.add_box_outlined,
                          color: HudTheme.hudCyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NUEVO PRODUCTO',
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
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  cursorColor: HudTheme.hudCyan,
                  decoration: InputDecoration(
                    hintText: 'NOMBRE DEL ARTÍCULO',
                    hintStyle: const TextStyle(
                      color: HudTheme.chromeSilver,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: const BorderSide(color: HudTheme.hudLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: const BorderSide(color: HudTheme.hudLine),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                      borderSide:
                          BorderSide(color: HudTheme.hudCyan, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, value);
                    }
                  },
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
                      onPressed: () => Navigator.pop(dialogContext, null),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: HudTheme.chromeSilver,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final texto = controller.text.trim();
                        if (texto.isEmpty) return;
                        Navigator.pop(dialogContext, texto);
                      },
                      icon: const Icon(Icons.check,
                          size: 16, color: Colors.black),
                      label: const Text(
                        'GUARDAR',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HudTheme.hudCyan,
                        foregroundColor: Colors.black,
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
    return resultado;
  }

  // ==================== BUILD ====================

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
              child: const Icon(Icons.inventory_2_outlined,
                  color: HudTheme.hudCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'INVENTARIO',
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
            onPressed: () => _loadInventario(mostrarLoading: true),
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
                  _buildResumenCard(),
                  _buildBuscador(),
                  Expanded(child: _buildLista()),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarProducto,
        icon: const Icon(Icons.add),
        label: const Text(
          'AGREGAR',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        backgroundColor: HudTheme.hudCyan,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildResumenCard() {
    final totalProductos = _inventario.length;
    final totalStock =
        _inventario.fold<double>(0.0, (sum, i) => sum + i.stockActual);
    final productosSinStock =
        _inventario.where((i) => i.stockActual <= 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CustomPaint(
        painter: _HudPanelPainter(accent: HudTheme.hudCyan),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HudTheme.hudCyan.withValues(alpha: 0.12),
                          border: Border.all(
                            color: HudTheme.hudCyan.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.warehouse_outlined,
                          color: HudTheme.hudCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'RESUMEN DE INVENTARIO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResumenItem(
                        'TOTAL ITEMS',
                        totalProductos.toString(),
                        HudTheme.hudCyan,
                        Icons.list_alt,
                      ),
                      Container(width: 1, height: 40, color: HudTheme.hudLine),
                      _buildResumenItem(
                        'STOCK TOTAL',
                        totalStock.toStringAsFixed(1),
                        HudTheme.hudLime,
                        Icons.inventory,
                      ),
                      Container(width: 1, height: 40, color: HudTheme.hudLine),
                      _buildResumenItem(
                        'AGOTADOS',
                        productosSinStock.toString(),
                        HudTheme.hudMagenta,
                        Icons.warning_amber,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: -4,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: HudTheme.hudBg,
                  child: const Text(
                    'SYS::INV',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: HudTheme.hudCyan,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenItem(
      String label, String value, Color color, IconData icono) {
    return Column(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: HudTheme.chromeSilver,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: HudTheme.hudLine, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: HudTheme.hudCyan),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _busquedaController,
                onChanged: _onBuscar,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: HudTheme.hudCyan,
                decoration: const InputDecoration(
                  hintText: 'BUSCAR PRODUCTO...',
                  hintStyle: TextStyle(
                    color: HudTheme.chromeSilver,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_busqueda.isNotEmpty)
              IconButton(
                icon:
                    const Icon(Icons.close, size: 18, color: HudTheme.hudCyan),
                onPressed: () {
                  _busquedaController.clear();
                  _onBuscar('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_inventarioFiltrado.isEmpty) {
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
                  Icons.inventory_2_outlined,
                  size: 60,
                  color: HudTheme.hudCyan,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _busqueda.isEmpty
                    ? '// SIN PRODUCTOS EN INVENTARIO'
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _inventarioFiltrado.length,
      itemBuilder: (context, index) {
        final item = _inventarioFiltrado[index];

        return ItemInventarioCard(
          key: ValueKey('inventario_${item.id ?? item.nombre}_$index'),
          item: item,
          onSumar: (cant) => _sumarStock(item, cant),
          onRestar: (cant) => _restarStock(item, cant),
          onEliminar: () => _eliminarProducto(item),
        );
      },
    );
  }
}

// ============================================================================
// WIDGET: Tarjeta de un producto del inventario
// ============================================================================

class ItemInventarioCard extends StatefulWidget {
  final Inventario item;
  final Future<bool> Function(String cantidad) onSumar;
  final Future<bool> Function(String cantidad) onRestar;
  final VoidCallback onEliminar;

  const ItemInventarioCard({
    super.key,
    required this.item,
    required this.onSumar,
    required this.onRestar,
    required this.onEliminar,
  });

  @override
  State<ItemInventarioCard> createState() => _ItemInventarioCardState();
}

class _ItemInventarioCardState extends State<ItemInventarioCard> {
  final TextEditingController _cantidadController = TextEditingController();
  final FocusNode _cantidadFocusNode = FocusNode();
  bool _procesando = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _cantidadFocusNode.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<bool> Function(String) accion) async {
    if (_procesando) return;
    final texto = _cantidadController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _procesando = true);

    final ok = await accion(texto);
    if (!mounted) return;

    setState(() => _procesando = false);

    if (ok) {
      _cantidadController.clear();
      _cantidadFocusNode.requestFocus();
    }
  }

  void _abrirQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerarQRScreen(
          contenido: widget.item.nombre,
          titulo: 'QR: ${widget.item.nombre}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final sinStock = item.stockActual <= 0;
    final accent = sinStock ? HudTheme.hudMagenta : HudTheme.hudCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: CustomPaint(
        painter: _HudPanelPainter(accent: accent),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'STOCK: ',
                              style: TextStyle(
                                fontSize: 10,
                                color: HudTheme.chromeSilver
                                    .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              item.stockActual.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 13,
                                color: accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_2,
                      color: HudTheme.hudCyan,
                      size: 26,
                    ),
                    tooltip: 'Generar código QR',
                    onPressed: _abrirQR,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: HudTheme.hudMagenta,
                      size: 24,
                    ),
                    tooltip: 'Eliminar producto',
                    onPressed: _procesando ? null : widget.onEliminar,
                  ),
                  if (sinStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HudTheme.hudMagenta.withValues(alpha: 0.15),
                        border: Border.all(
                          color: HudTheme.hudMagenta.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'AGOTADO',
                        style: TextStyle(
                          color: HudTheme.hudMagenta,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: HudTheme.hudLine),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(color: HudTheme.hudLine, width: 1),
                      ),
                      child: TextField(
                        controller: _cantidadController,
                        focusNode: _cantidadFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900),
                        cursorColor: HudTheme.hudCyan,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'CANTIDAD',
                          hintStyle: TextStyle(
                            color: HudTheme.chromeSilver,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _botonAccion(
                    icon: Icons.remove,
                    color: HudTheme.hudMagenta,
                    enabled: !_procesando,
                    onTap: () => _ejecutar(widget.onRestar),
                  ),
                  const SizedBox(width: 6),
                  _botonAccion(
                    icon: Icons.add,
                    color: HudTheme.hudLime,
                    enabled: !_procesando,
                    onTap: () => _ejecutar(widget.onSumar),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonAccion({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colorFinal = enabled ? color : HudTheme.chromeSilver;
    return Material(
      color: colorFinal.withValues(alpha: 0.12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorFinal.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: colorFinal, size: 22),
        ),
      ),
    );
  }
}
