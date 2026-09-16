import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class QRHelper {
  // ============================================================
  // GUARDAR EN GALERÍA
  // ============================================================

  /// ✅ Guarda una imagen PNG en la galería del dispositivo.
  Future<bool> guardarEnGaleria(Uint8List imageBytes, String nombre) async {
    try {
      // Pedir permiso (Android 13+ no lo requiere, iOS sí)
      final tieneAcceso = await Gal.hasAccess();
      if (!tieneAcceso) {
        await Gal.requestAccess();
      }

      // Guardar en galería
      await Gal.putImageBytes(
        imageBytes,
        name: '${nombre}_${DateTime.now().millisecondsSinceEpoch}',
        album: 'Ciauto Planificacion',
      );

      return true;
    } catch (e) {
      print('❌ Error al guardar en galería: $e');
      return false;
    }
  }

  // ============================================================
  // COMPARTIR IMAGEN
  // ============================================================

  /// ✅ Guarda la imagen en un archivo temporal y la comparte.
  Future<void> compartirImagen(Uint8List imageBytes, String nombre) async {
    try {
      final directorio = await getTemporaryDirectory();
      final archivo = File('${directorio.path}/$nombre.png');
      await archivo.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(archivo.path, mimeType: 'image/png')],
        subject: 'Código QR',
        text: 'Código QR generado desde Ciauto Planificación',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      );
    } catch (e) {
      print('❌ Error al compartir: $e');
    }
  }

  // ============================================================
  // GUARDAR EN DESCARGAS (Android)
  // ============================================================

  /// ✅ Guarda la imagen en la carpeta de Descargas (Android).
  Future<File?> guardarEnDescargas(Uint8List imageBytes, String nombre) async {
    try {
      Directory? directorio;
      if (Platform.isAndroid) {
        directorio = Directory('/storage/emulated/0/Download/CiautoQR');
        if (!await directorio.exists()) {
          await directorio.create(recursive: true);
        }
      } else {
        directorio = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final archivo = File('${directorio.path}/${nombre}_$timestamp.png');
      await archivo.writeAsBytes(imageBytes);

      print('✅ QR guardado en: ${archivo.path}');
      return archivo;
    } catch (e) {
      print('❌ Error al guardar en Descargas: $e');
      return null;
    }
  }
}
