import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vehiculos_app/models/inventario.dart';
import 'package:vehiculos_app/database/database_helper.dart';
import 'package:vehiculos_app/screens/generar_qr_screen.dart'; // ✅ NUEVO

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

  // ==================== UTILIDADES ====================

  void _showSnack(String msg, {bool esError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                esError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              esError ? Colors.red.shade700 : Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<String?> _showDialogAgregarProducto() async {
    final controller = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar Nuevo Producto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Nombre del artículo',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(dialogContext, texto);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    return resultado;
  }

  // ==================== BUILD ====================

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
            Icon(Icons.inventory_2_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Inventario / Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInventario(mostrarLoading: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
        label: const Text('Agregar'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
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

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            primary.withValues(alpha: 0.8),
          ],
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warehouse_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Resumen de inventario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenItem('Total Items', totalProductos.toString()),
              _buildResumenItem('Stock Total', totalStock.toStringAsFixed(1)),
              _buildResumenItem('Agotados', productosSinStock.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _busquedaController,
        onChanged: _onBuscar,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar producto...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_inventarioFiltrado.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron productos',
          style: TextStyle(color: Colors.grey, fontSize: 16),
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

  const ItemInventarioCard({
    super.key,
    required this.item,
    required this.onSumar,
    required this.onRestar,
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

  // ✅ NUEVO: Abrir pantalla de QR con el nombre del producto
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
    final colorScheme = Theme.of(context).colorScheme;
    final sinStock = item.stockActual <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (sinStock ? Colors.red : colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: sinStock ? Colors.red : colorScheme.primary,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stock: ${item.stockActual.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: sinStock
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ NUEVO: Botón QR
                IconButton(
                  icon: Icon(
                    Icons.qr_code_2,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                  tooltip: 'Generar código QR',
                  onPressed: _abrirQR,
                ),
                if (sinStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AGOTADO',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    focusNode: _cantidadFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Cantidad',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _botonAccion(
                  icon: Icons.remove,
                  color: Colors.red,
                  enabled: !_procesando,
                  onTap: () => _ejecutar(widget.onRestar),
                ),
                const SizedBox(width: 6),
                _botonAccion(
                  icon: Icons.add,
                  color: Colors.green,
                  enabled: !_procesando,
                  onTap: () => _ejecutar(widget.onSumar),
                ),
              ],
            ),
          ],
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
    final colorFinal = enabled ? color : Colors.grey;
    return Material(
      color: colorFinal.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: colorFinal, size: 22),
        ),
      ),
    );
  }
}
