// lib/data/datos_modelos.dart

import 'recetas_service.dart';

class DatosModelos {
  static const List<String> modelos = [
    'SWM G01',
    'SWM G01F',
    'SWM G01F AC 1.5 TA',
    'SHINERAY X30L',
    'V3 VAN AC 1.5 4P 4X2 TM',
    'V7 VAN AC 1.6 4P 4X2 TM',
    'KYC_V7_CARGO_1.6_4X2',
    'F3 AC 1.6 CD 4X2 TM GAS',
    'F3 AC 2.0 CD 4X2 TM DIE',
    'POER AC 2.0 CD 4X4 TM DIE',
    'POER AC 2.0 CD 4X2 TM DIE',
    'WINGLE 7 DIESEL 4X2',
    'WINGLE 7 DIESEL 4X4',
    'WINGLE STEED AC 2.4',
  ];

  static const Map<String, List<Map<String, dynamic>>> datosPorModelo = {
    // ========== SWM G01 ==========
    'SWM G01': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 2.00},
      {'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30', 'reseta': 4.00},
      {'nombre': 'AIRE ACONDICIONADOR IZETROL 134A', 'reseta': 480.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.28},
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.52},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.62},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 1.00},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 6.00},
      {'nombre': 'SELLANTE DE JUNTA (3700) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARA PVC (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.50
      },
    ],

    // ========== SWM G01F ==========
    'SWM G01F': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 2.60},
      {'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30', 'reseta': 4.00},
      {'nombre': 'AIRE ACONDICIONADOR IZEPETROL 134A', 'reseta': 480.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.28},
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.65},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.92},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 6.00},
      {'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.50
      },
    ],

    // ========== SWM G01F AC 1.5 TA ==========
    'SWM G01F AC 1.5 TA': [
      {'nombre': 'ACEITE CAJA AUTOMATICA WOLVER DSG - G01', 'reseta': 5.50},
      {'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30', 'reseta': 4.00},
      {'nombre': 'AIRE ACONDICIONADOR IZEPETROL 134A', 'reseta': 480.00},
      {'nombre': 'CERA AMTICORROSIVA TOGOTEC PP 159', 'reseta': 0.28},
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.65},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28},
      {'nombre': 'POLIURETANO PARA PARABRISAS TOGODAC DA 280', 'reseta': 0.92},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 5.40},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 9
      },
    ],

    // ========== SHINERAY X30L ==========
    'SHINERAY X30L': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.50},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 1.60},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 4.40},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 650.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 1.00},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 2.00},
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.65},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 1.09},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 6.20},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.5},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 5.71
      },
    ],

    // ========== V3 VAN AC 1.5 4P 4X2 TM ==========
    'V3 VAN AC 1.5 4P 4X2 TM': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GLS - VEEDOL', 'reseta': 1.50},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL4', 'reseta': 2.50},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 3.00},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 650.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 1.00},
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.50},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 6},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 6.25
      },
    ],

    // ========== V7 VAN AC 1.6 4P 4X2 TM ==========
    'V7 VAN AC 1.6 4P 4X2 TM': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.80},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 2.50},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 3.50},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 660.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 1.00},
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.50},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 6},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 6.25
      },
    ],

    // ========== KYC_V7_CARGO_1.6_4X2 ==========
    'KYC_V7_CARGO_1.6_4X2': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 1.80},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 2.50},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 3.50},
      {'nombre': 'AIRE ACONDICIONADOR GLOBAL 134A', 'reseta': 650.00},
      {'nombre': 'CERA ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 1.00},
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.50},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 246 KL (57302N)', 'reseta': 0.59},
      {'nombre': 'REFRIGERANTE C0ELTA COOL - CRIOSOLUCIONES', 'reseta': 6.00},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 6.25
      },
    ],

    // ========== F3 AC 1.6 CD 4X2 TM GAS ==========
    'F3 AC 1.6 CD 4X2 TM GAS': [
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.00},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 2.65},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 3.50},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 420.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.70},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75},
      {'nombre': 'GASOLINA SUPER', 'reseta': 6.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.60},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.46},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.60},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 7.30},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.00},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 8.00
      },
    ],

    // ========== F3 AC 2.0 CD 4X2 TM DIE ==========
    'F3 AC 2.0 CD 4X2 TM DIE': [
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.30},
      {'nombre': 'ACEITE DIFERENCIAL 80W90 GL5', 'reseta': 2.65},
      {'nombre': 'ACEITE DE MOTOR DIESEL 15W40', 'reseta': 4.50},
      {'nombre': 'ACEITE DE MOTOR GASOLINA 10W40', 'reseta': 3.50},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 415.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.70},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 13.90},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.60},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.46},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.60},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 7.50},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.86
      },
    ],

    // ========== POER AC 2.0 CD 4X4 TM DIE ==========
    'POER AC 2.0 CD 4X4 TM DIE': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 3.20},
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.20},
      {'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90', 'reseta': 2.70},
      {'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30', 'reseta': 5.80},
      {'nombre': 'AIRE ACONDICIONADOR IZEPETROL 134A', 'reseta': 480.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.70},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 7.50},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE DIRECCION ATF III', 'reseta': 1.05},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.84},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.34},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.70},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 7.80},
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.20},
      {'nombre': 'SELLANTE DE JUNTA (3700) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARA PVC (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.14
      },
    ],

    // ========== POER AC 2.0 CD 4X2 TM DIE ==========
    'POER AC 2.0 CD 4X2 TM DIE': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 3.20},
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.20},
      {'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90', 'reseta': 4.50},
      {'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30', 'reseta': 5.80},
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 480.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.70},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 7.50},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE DIRECCION ATF III', 'reseta': 1.05},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.84},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.70},
      {'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES', 'reseta': 8.20},
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.20},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.50},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.10
      },
    ],

    // ========== WINGLE 7 DIESEL 4X2 ==========
    'WINGLE 7 DIESEL 4X2': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 2.70},
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.70},
      {'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90', 'reseta': 2.70},
      {'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30', 'reseta': 5.50},
      {'nombre': 'AIRE ACONDICIONADOR IZEPETROL 134A', 'reseta': 420.00},
      {'nombre': 'CERA ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.55},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE DIRECCION ATF III', 'reseta': 0.78},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.78},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.80},
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.50},
      {'nombre': 'SELLANTE DE JUNTA (3700) - PINTURA', 'reseta': 2.20},
      {
        'nombre': 'SELLANTE PARA PVC (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.50
      },
    ],

    // ========== WINGLE 7 DIESEL 4X4 ==========
    'WINGLE 7 DIESEL 4X4': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 2.70},
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.70},
      {'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90', 'reseta': 4.50},
      {'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30', 'reseta': 5.50},
      {'nombre': 'AIRE ACONDICIONADOR IZEPETROL 134A', 'reseta': 420.00},
      {'nombre': 'ACEITE ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.65},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE DIRECCION ATF III', 'reseta': 0.78},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.76},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.80},
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.50},
      {'nombre': 'SELLANTE DE JUNTA (3700) - PINTURA', 'reseta': 2.20},
      {
        'nombre': 'SELLANTE PARA PVC (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.30
      },
    ],

    // ========== WINGLE STEED AC 2.4 ==========
    'WINGLE STEED AC 2.4': [
      {'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL', 'reseta': 2.60},
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.60},
      {'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90', 'reseta': 2.70},
      {
        'nombre': 'ACEITE MOTOR DIESEL R5 QUARTZ INEO MC-3 5W-30',
        'reseta': 4.50
      },
      {'nombre': 'AIRE ACONDICIONADOR PETROL 134A', 'reseta': 480.00},
      {'nombre': 'CERA ANTICONGELANTE TOGOTEC PP 1S9', 'reseta': 0.55},
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 10.00},
      {'nombre': 'GASOLINA SUPER', 'reseta': 5.00},
      {'nombre': 'LIQUIDO DE DIRECCION ATF III', 'reseta': 1},
      {'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4', 'reseta': 0.70},
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.29},
      {'nombre': 'POLIURETANO PARABRISAS DRUM 24K (67302N)', 'reseta': 0.60},
      {'nombre': 'REFRIGERANTE L210', 'reseta': 7.80},
      {'nombre': 'SELLANTE DE CINTA (3700) - PINTURA', 'reseta': 2.00},
      {
        'nombre': 'SELLANTE PARAFRICA (TOGOCELASTIC 990) - PINTURA',
        'reseta': 7.50
      },
    ],
  };

  // ============================================================
  // MÉTODOS
  // ============================================================

  /// Obtiene los componentes de un modelo (solo predefinidos, síncrono)
  /// Se mantiene por compatibilidad con código existente.
  static List<Map<String, dynamic>> getComponentesPorModelo(String modelo) {
    return datosPorModelo[modelo] ?? [];
  }

  /// Obtiene los componentes de un modelo combinando:
  /// 1. Modelos predefinidos (datosPorModelo)
  /// 2. Modelos personalizados (SharedPreferences vía RecetasService)
  static Future<List<Map<String, dynamic>>> getComponentesPorModeloAsync(
    String modelo,
  ) async {
    // 1. Buscar en modelos predefinidos
    final predefinidos = datosPorModelo[modelo];
    if (predefinidos != null && predefinidos.isNotEmpty) {
      return predefinidos;
    }

    // 2. Buscar en recetas personalizadas
    return await RecetasService.obtenerReceta(modelo);
  }

  /// Lista completa de modelos (predefinidos + personalizados)
  static Future<List<String>> obtenerTodosLosModelos() async {
    final personalizadas = await RecetasService.obtenerTodas();
    final List<String> todos = List.from(modelos);
    for (final key in personalizadas.keys) {
      if (!todos.contains(key)) todos.add(key);
    }
    return todos;
  }

  /// Verifica si un modelo es personalizado (no está en la lista predefinida)
  static bool esPersonalizado(String modelo) {
    return !modelos.contains(modelo);
  }

  /// Verifica si un modelo tiene receta personalizada guardada
  static Future<bool> tieneRecetaPersonalizada(String modelo) async {
    final receta = await RecetasService.obtenerReceta(modelo);
    return receta.isNotEmpty;
  }

  /// Elimina la receta personalizada de un modelo
  static Future<void> eliminarRecetaPersonalizada(String modelo) async {
    await RecetasService.eliminarReceta(modelo);
  }
}
