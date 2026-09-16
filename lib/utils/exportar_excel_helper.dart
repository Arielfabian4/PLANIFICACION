import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ✅ AGREGA ESTA LÍNEA
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExportarExcelHelper {
  final DatabaseHelper db = DatabaseHelper();

  // ============================================================
  // EXPORTAR INVENTARIO
  // ============================================================

  Future<File?> exportarInventario() async {
    try {
      final inventario = await db.getInventario();
      if (inventario.isEmpty) {
        debugPrint('⚠️ No hay inventario para exportar');
        return null;
      }

      final excel = Excel.createExcel();
      // ✅ Crear la hoja con nombre específico
      final hoja = excel['Inventario'];

      // Encabezados
      hoja.appendRow([
        TextCellValue('ID'),
        TextCellValue('Nombre'),
        TextCellValue('Stock Actual'),
        TextCellValue('Fecha'),
      ]);

      // Datos
      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      for (final item in inventario) {
        hoja.appendRow([
          IntCellValue((item['id'] as num?)?.toInt() ?? 0),
          TextCellValue(item['nombre']?.toString() ?? ''),
          DoubleCellValue((item['stock_actual'] as num?)?.toDouble() ?? 0.0),
          TextCellValue(fecha),
        ]);
      }

      // ✅ Eliminar hoja por defecto si existe
      _eliminarHojaPorDefecto(excel);

      return await _guardarExcel(excel, 'inventario');
    } catch (e, stack) {
      debugPrint('❌ Error al exportar inventario: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // EXPORTAR VEHÍCULOS
  // ============================================================

  Future<File?> exportarVehiculos() async {
    try {
      final vehiculos = await db.getAllVehiculos();
      if (vehiculos.isEmpty) {
        debugPrint('⚠️ No hay vehículos para exportar');
        return null;
      }

      final excel = Excel.createExcel();
      final hoja = excel['Vehículos'];

      hoja.appendRow([
        TextCellValue('ID'),
        TextCellValue('Modelo'),
        TextCellValue('Fecha Registro'),
      ]);

      for (final v in vehiculos) {
        hoja.appendRow([
          IntCellValue(v.idVehiculo ?? 0),
          TextCellValue(v.modelo),
          TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm')
                .format(v.createdAt ?? DateTime.now()),
          ),
        ]);
      }

      _eliminarHojaPorDefecto(excel);
      return await _guardarExcel(excel, 'vehiculos');
    } catch (e, stack) {
      debugPrint('❌ Error al exportar vehículos: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // EXPORTAR CÁLCULOS CON DETALLE
  // ============================================================

  Future<File?> exportarCalculos() async {
    try {
      final calculos = await db.obtenerCalculosConVehiculo();
      if (calculos.isEmpty) {
        debugPrint('⚠️ No hay cálculos para exportar');
        return null;
      }

      final excel = Excel.createExcel();
      final hoja = excel['Cálculos'];

      hoja.appendRow([
        TextCellValue('ID Cálculo'),
        TextCellValue('Vehículo'),
        TextCellValue('Componente'),
        TextCellValue('Reseta'),
        TextCellValue('Valor Real'),
        TextCellValue('Diferencia'),
        TextCellValue('Fecha'),
      ]);

      for (final c in calculos) {
        final idCalculo = (c['id_calculo'] as num?)?.toInt() ?? 0;
        final nombreVehiculo = c['nombreVehiculo']?.toString() ?? '';
        final fecha = c['created_at']?.toString() ?? '';

        final componentes = await db.obtenerComponentesPorCalculo(idCalculo);

        for (final comp in componentes) {
          final reseta = (comp['reseta'] as num?)?.toDouble() ?? 0.0;
          final valorReal = (comp['valor_real'] as num?)?.toDouble() ?? 0.0;

          hoja.appendRow([
            IntCellValue(idCalculo),
            TextCellValue(nombreVehiculo),
            TextCellValue(comp['nombre']?.toString() ?? ''),
            DoubleCellValue(reseta),
            DoubleCellValue(valorReal),
            DoubleCellValue(valorReal - reseta),
            TextCellValue(fecha),
          ]);
        }
      }

      _eliminarHojaPorDefecto(excel);
      return await _guardarExcel(excel, 'calculos');
    } catch (e, stack) {
      debugPrint('❌ Error al exportar cálculos: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // EXPORTAR CONSUMO POR COMPONENTE
  // ============================================================

  Future<File?> exportarConsumoPorComponente() async {
    try {
      final totales = await db.obtenerTotalesPorComponente();
      if (totales.isEmpty) {
        debugPrint('⚠️ No hay consumo para exportar');
        return null;
      }

      final excel = Excel.createExcel();
      final hoja = excel['Consumo por Componente'];

      hoja.appendRow([
        TextCellValue('Componente'),
        TextCellValue('Total Real (L)'),
        TextCellValue('Total Teórico (L)'),
        TextCellValue('Diferencia'),
        TextCellValue('Veces Usado'),
      ]);

      for (final item in totales) {
        hoja.appendRow([
          TextCellValue(item['nombre']?.toString() ?? ''),
          DoubleCellValue((item['total_real'] as num?)?.toDouble() ?? 0.0),
          DoubleCellValue((item['total_teorico'] as num?)?.toDouble() ?? 0.0),
          DoubleCellValue((item['diferencia'] as num?)?.toDouble() ?? 0.0),
          IntCellValue((item['veces_usado'] as num?)?.toInt() ?? 0),
        ]);
      }

      _eliminarHojaPorDefecto(excel);
      return await _guardarExcel(excel, 'consumo_por_componente');
    } catch (e, stack) {
      debugPrint('❌ Error al exportar consumo: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // EXPORTAR TODO (múltiples hojas)
  // ============================================================

  Future<File?> exportarTodo() async {
    try {
      final excel = Excel.createExcel();
      bool tieneDatos = false;

      // --- Hoja 1: Inventario ---
      final inventario = await db.getInventario();
      if (inventario.isNotEmpty) {
        tieneDatos = true;
        final hoja = excel['Inventario'];
        hoja.appendRow([
          TextCellValue('ID'),
          TextCellValue('Nombre'),
          TextCellValue('Stock Actual'),
        ]);
        for (final item in inventario) {
          hoja.appendRow([
            IntCellValue((item['id'] as num?)?.toInt() ?? 0),
            TextCellValue(item['nombre']?.toString() ?? ''),
            DoubleCellValue((item['stock_actual'] as num?)?.toDouble() ?? 0.0),
          ]);
        }
      }

      // --- Hoja 2: Vehículos ---
      final vehiculos = await db.getAllVehiculos();
      if (vehiculos.isNotEmpty) {
        tieneDatos = true;
        final hoja = excel['Vehículos'];
        hoja.appendRow([
          TextCellValue('ID'),
          TextCellValue('Modelo'),
          TextCellValue('Fecha'),
        ]);
        for (final v in vehiculos) {
          hoja.appendRow([
            IntCellValue(v.idVehiculo ?? 0),
            TextCellValue(v.modelo),
            TextCellValue(
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(v.createdAt ?? DateTime.now()),
            ),
          ]);
        }
      }

      // --- Hoja 3: Cálculos ---
      final calculos = await db.obtenerCalculosConVehiculo();
      if (calculos.isNotEmpty) {
        tieneDatos = true;
        final hoja = excel['Cálculos'];
        hoja.appendRow([
          TextCellValue('ID'),
          TextCellValue('Vehículo'),
          TextCellValue('Componente'),
          TextCellValue('Reseta'),
          TextCellValue('Valor Real'),
          TextCellValue('Diferencia'),
          TextCellValue('Fecha'),
        ]);
        for (final c in calculos) {
          final idCalculo = (c['id_calculo'] as num?)?.toInt() ?? 0;
          final nombreVehiculo = c['nombreVehiculo']?.toString() ?? '';
          final fecha = c['created_at']?.toString() ?? '';
          final componentes = await db.obtenerComponentesPorCalculo(idCalculo);

          for (final comp in componentes) {
            final reseta = (comp['reseta'] as num?)?.toDouble() ?? 0.0;
            final valorReal = (comp['valor_real'] as num?)?.toDouble() ?? 0.0;
            hoja.appendRow([
              IntCellValue(idCalculo),
              TextCellValue(nombreVehiculo),
              TextCellValue(comp['nombre']?.toString() ?? ''),
              DoubleCellValue(reseta),
              DoubleCellValue(valorReal),
              DoubleCellValue(valorReal - reseta),
              TextCellValue(fecha),
            ]);
          }
        }
      }

      // --- Hoja 4: Totales por componente ---
      final totales = await db.obtenerTotalesPorComponente();
      if (totales.isNotEmpty) {
        tieneDatos = true;
        final hoja = excel['Totales'];
        hoja.appendRow([
          TextCellValue('Componente'),
          TextCellValue('Total Real'),
          TextCellValue('Total Teórico'),
          TextCellValue('Diferencia'),
          TextCellValue('Veces Usado'),
        ]);
        for (final item in totales) {
          hoja.appendRow([
            TextCellValue(item['nombre']?.toString() ?? ''),
            DoubleCellValue((item['total_real'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((item['total_teorico'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((item['diferencia'] as num?)?.toDouble() ?? 0.0),
            IntCellValue((item['veces_usado'] as num?)?.toInt() ?? 0),
          ]);
        }
      }

      if (!tieneDatos) {
        debugPrint('⚠️ No hay datos para exportar');
        return null;
      }

      _eliminarHojaPorDefecto(excel);
      return await _guardarExcel(excel, 'reporte_completo');
    } catch (e, stack) {
      debugPrint('❌ Error al exportar todo: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// ✅ Elimina la hoja por defecto "Sheet1" si existe.
  /// Las versiones nuevas de `excel` crean una hoja vacía por defecto.
  void _eliminarHojaPorDefecto(Excel excel) {
    final nombres = excel.tables.keys.toList();
    // Si hay más de 1 hoja, eliminar "Sheet1" o la primera si está vacía
    if (nombres.length > 1) {
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
    } else if (nombres.length == 1 && nombres.first == 'Sheet1') {
      // Si solo existe Sheet1, renombrarla no es posible, pero al menos
      // evitamos que quede vacía si ya agregamos datos a otra hoja
      debugPrint('ℹ️ Solo existe Sheet1');
    }
  }

  // ============================================================
  // GUARDAR ARCHIVO
  // ============================================================

  Future<File?> _guardarExcel(Excel excel, String nombreBase) async {
    try {
      // ✅ Codificar el Excel a bytes
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        debugPrint('❌ Excel.encode() devolvió null o vacío');
        return null;
      }

      // Obtener directorio de documentos
      final directorio = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = '${nombreBase}_$timestamp.xlsx';
      final rutaCompleta = '${directorio.path}/$nombreArchivo';

      // ✅ Escribir bytes al archivo
      final archivo = File(rutaCompleta);
      await archivo.writeAsBytes(bytes, flush: true);

      debugPrint('✅ Excel guardado en: $rutaCompleta');
      debugPrint('📦 Tamaño: ${bytes.length} bytes');
      return archivo;
    } catch (e, stack) {
      debugPrint('❌ Error al guardar Excel: $e');
      debugPrint('$stack');
      return null;
    }
  }

  // ============================================================
  // COMPARTIR ARCHIVO
  // ============================================================

  Future<void> compartirExcel(File archivo) async {
    try {
      if (!await archivo.exists()) {
        debugPrint('❌ El archivo no existe: ${archivo.path}');
        return;
      }

      final xFile = XFile(
        archivo.path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'Reporte de Vehículos',
        text: 'Reporte generado desde la app de vehículos',
        // ✅ Requerido en iPad para mostrar el popover
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
      );
      debugPrint('✅ Archivo compartido');
    } catch (e, stack) {
      debugPrint('❌ Error al compartir: $e');
      debugPrint('$stack');
    }
  }

  // ============================================================
  // COMPARTIR MÚLTIPLES ARCHIVOS
  // ============================================================

  Future<void> compartirMultiplesExcel(List<File> archivos) async {
    try {
      final xFiles = archivos
          .where((f) => f.existsSync())
          .map((f) => XFile(
                f.path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ))
          .toList();

      if (xFiles.isEmpty) {
        debugPrint('⚠️ No hay archivos para compartir');
        return;
      }

      await Share.shareXFiles(
        xFiles,
        subject: 'Reportes de Vehículos',
        text: 'Reportes generados desde la app',
        sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
      );
      debugPrint('✅ ${xFiles.length} archivos compartidos');
    } catch (e, stack) {
      debugPrint('❌ Error al compartir múltiples: $e');
      debugPrint('$stack');
    }
  }
}
