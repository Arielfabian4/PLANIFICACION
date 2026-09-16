import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../utils/qr_helper.dart';

class GenerarQRScreen extends StatefulWidget {
  /// Contenido del QR (puede ser nombre, id, JSON, etc.)
  final String contenido;

  /// Título opcional para mostrar en pantalla
  final String? titulo;

  const GenerarQRScreen({
    super.key,
    required this.contenido,
    this.titulo,
  });

  @override
  State<GenerarQRScreen> createState() => _GenerarQRScreenState();
}

class _GenerarQRScreenState extends State<GenerarQRScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final QRHelper _qrHelper = QRHelper();

  bool _guardando = false;

  // ============================================================
  // GUARDAR EN GALERÍA
  // ============================================================

  Future<void> _guardarEnGaleria() async {
    setState(() => _guardando = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        _mostrarMensaje('❌ Error al capturar la imagen');
        return;
      }

      final ok = await _qrHelper.guardarEnGaleria(
        imageBytes,
        'qr_${widget.contenido.hashCode}',
      );

      if (ok) {
        _mostrarMensaje('✅ QR guardado en la galería');
      } else {
        _mostrarMensaje('❌ No se pudo guardar en la galería');
      }
    } catch (e) {
      _mostrarMensaje('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ============================================================
  // COMPARTIR
  // ============================================================

  Future<void> _compartir() async {
    setState(() => _guardando = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        _mostrarMensaje('❌ Error al capturar la imagen');
        return;
      }

      await _qrHelper.compartirImagen(
        imageBytes,
        'qr_${widget.contenido.hashCode}',
      );
    } catch (e) {
      _mostrarMensaje('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ============================================================
  // GUARDAR EN DESCARGAS
  // ============================================================

  Future<void> _guardarEnDescargas() async {
    setState(() => _guardando = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        _mostrarMensaje('❌ Error al capturar la imagen');
        return;
      }

      final archivo = await _qrHelper.guardarEnDescargas(
        imageBytes,
        'qr_${widget.contenido.hashCode}',
      );

      if (archivo != null) {
        _mostrarMensaje('✅ Guardado en Descargas:\n${archivo.path}');
      } else {
        _mostrarMensaje('❌ No se pudo guardar en Descargas');
      }
    } catch (e) {
      _mostrarMensaje('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.titulo ?? 'Código QR',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Vista previa capturable
              Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: widget.contenido,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.contenido,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ciauto Planificación',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Botones
              if (_guardando)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardarEnGaleria,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Guardar en galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _compartir,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _guardarEnDescargas,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Guardar en Descargas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
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
}
