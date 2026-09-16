import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerQRScreen extends StatefulWidget {
  const EscanerQRScreen({super.key});

  @override
  State<EscanerQRScreen> createState() => _EscanerQRScreenState();
}

class _EscanerQRScreenState extends State<EscanerQRScreen> {
  final MobileScannerController controller = MobileScannerController();

  /// ✅ Bandera que evita procesar múltiples lecturas del mismo QR
  bool _yaEscaneado = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // 🔒 Si ya escaneamos, ignorar todo lo demás
    if (_yaEscaneado) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? valorEscaneado = barcodes.first.rawValue;
    if (valorEscaneado == null || valorEscaneado.isEmpty) return;

    // 🔒 Marcar como escaneado ANTES de hacer pop
    _yaEscaneado = true;

    // 🔒 Verificar que el widget siga montado
    if (!mounted) return;

    // ✅ Regresar SOLO a la pantalla anterior (NuevoCalculoScreen)
    Navigator.pop(context, valorEscaneado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Capa de guía visual
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Texto de ayuda
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.toggleTorch(),
        child: const Icon(Icons.flash_on),
      ),
    );
  }
}
