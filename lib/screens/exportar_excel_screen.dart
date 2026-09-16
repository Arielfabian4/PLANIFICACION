import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/exportar_excel_helper.dart';

class ExportarExcelScreen extends StatefulWidget {
  const ExportarExcelScreen({super.key});

  @override
  State<ExportarExcelScreen> createState() => _ExportarExcelScreenState();
}

class _ExportarExcelScreenState extends State<ExportarExcelScreen> {
  final helper = ExportarExcelHelper();
  bool _procesando = false;
  String _mensaje = '';

  Future<void> _exportar(String tipo) async {
    setState(() {
      _procesando = true;
      _mensaje = '';
    });

    try {
      File? archivo;

      switch (tipo) {
        case 'inventario':
          archivo = await helper.exportarInventario();
          break;
        case 'vehiculos':
          archivo = await helper.exportarVehiculos();
          break;
        case 'calculos':
          archivo = await helper.exportarCalculos();
          break;
        case 'consumo':
          archivo = await helper.exportarConsumoPorComponente();
          break;
        case 'todo':
          archivo = await helper.exportarTodo();
          break;
      }

      if (archivo == null) {
        setState(() {
          _procesando = false;
          _mensaje = '❌ No hay datos para exportar';
        });
        return;
      }

      setState(() {
        _procesando = false;
        _mensaje = '✅ Archivo generado:\n${archivo!.path.split('/').last}';
      });

      // Compartir el archivo automáticamente
      await helper.compartirExcel(archivo);
    } catch (e) {
      setState(() {
        _procesando = false;
        _mensaje = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Exportar a Excel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona qué información exportar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Se generará un archivo .xlsx que podrás compartir por WhatsApp, correo o guardar en tu dispositivo.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildOpcionCard(
                titulo: 'Inventario',
                subtitulo: 'Lista de productos con su stock actual',
                icono: Icons.inventory_2_outlined,
                color: Colors.blue,
                onTap: () => _exportar('inventario'),
              ),
              _buildOpcionCard(
                titulo: 'Vehículos',
                subtitulo: 'Lista de todos los vehículos registrados',
                icono: Icons.directions_car_outlined,
                color: Colors.green,
                onTap: () => _exportar('vehiculos'),
              ),
              _buildOpcionCard(
                titulo: 'Cálculos',
                subtitulo: 'Historial completo con detalle por componente',
                icono: Icons.calculate_outlined,
                color: Colors.orange,
                onTap: () => _exportar('calculos'),
              ),
              _buildOpcionCard(
                titulo: 'Consumo por Componente',
                subtitulo: 'Totales acumulados por cada componente',
                icono: Icons.analytics_outlined,
                color: Colors.purple,
                onTap: () => _exportar('consumo'),
              ),
              _buildOpcionCard(
                titulo: 'Reporte Completo',
                subtitulo: 'Todo en un solo archivo con múltiples hojas',
                icono: Icons.description_outlined,
                color: Colors.red,
                onTap: () => _exportar('todo'),
                destacado: true,
              ),
              if (_procesando) ...[
                const SizedBox(height: 30),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Generando archivo...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
              if (_mensaje.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: _mensaje.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _mensaje,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _mensaje.startsWith('✅')
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionCard({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
    bool destacado = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              destacado ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: destacado ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _procesando ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_outlined,
                color: color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
