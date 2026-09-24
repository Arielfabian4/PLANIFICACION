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

  // ============================================================
  // 🎯 UNIDADES DE MEDIDA (U.M):
  //   LT    → Litros
  //   GR    → Gramos
  //   KG    → Kilogramos
  //   GL    → Galones
  //   MT    → Metros
  //   UND   → Unidades
  //   ROLLO → 🧵 Rollos (CINTA BUTILO GRIS)
  //
  // 🛢️ mideTanque: true  → Se mide INICIO y FINAL del tanque
  //    (Consumo real = Inicio − Final)
  //    Componentes: POLIURETANOS, SELLANTES, CERA ANTICORROSIVA
  // ============================================================

  static const Map<String, List<Map<String, dynamic>>> datosPorModelo = {
    // ========== SWM G01 ==========
    'SWM G01': [
      {
        'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL',
        'reseta': 2.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30',
        'reseta': 4.00,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADOR 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.28,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.52,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.52, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 1.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.50,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== SWM G01F ==========
    'SWM G01F': [
      {
        'nombre': 'ACEITE CAJA SYNGear AT 75W90 GL4 - VEEDOL',
        'reseta': 2.60,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30',
        'reseta': 4.00,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADOR 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.28,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.65,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.92,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.50,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== SWM G01F AC 1.5 TA ==========
    'SWM G01F AC 1.5 TA': [
      {
        'nombre': 'ACEITE CAJA AUTOMATICA WOLVER DSG - G01',
        'reseta': 5.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR ENI SINT 5W-30',
        'reseta': 4.00,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADOR 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.28,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 7.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.65,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.92,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 5.40,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 9.00,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== SHINERAY X30L ==========
    'SHINERAY X30L': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 1.50,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 1.60, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 4.40,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 650.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 1.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 2.00, 'unidad': 'ROLLO'},
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.65,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 1.09,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.20,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 5.71,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== V3 VAN AC 1.5 4P 4X2 TM ==========
    'V3 VAN AC 1.5 4P 4X2 TM': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 1.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DIFERENCIAL 80W90 GL5',
        'reseta': 2.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 3.00,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 650.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 1.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.50,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.59,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 6.25,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== V7 VAN AC 1.6 4P 4X2 TM ==========
    'V7 VAN AC 1.6 4P 4X2 TM': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 1.80,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DIFERENCIAL 80W90 GL5',
        'reseta': 2.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 3.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 660.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 1.80,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.50,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 1.32,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 6.25,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== KYC_V7_CARGO_1.6_4X2 ==========
    'KYC_V7_CARGO_1.6_4X2': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 1.80,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DIFERENCIAL 80W90 GL5',
        'reseta': 2.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 3.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 650.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 1.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'GASOLINA SUPER', 'reseta': 4.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.50,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.59, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS DRUM 24K (57302N)',
        'reseta': 1.09,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 6.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 6.25,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== F3 AC 1.6 CD 4X2 TM GAS ==========
    'F3 AC 1.6 CD 4X2 TM GAS': [
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.00, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL 80W90 GL5',
        'reseta': 2.65,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 3.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 420.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75, 'unidad': 'ROLLO'},
      {'nombre': 'GASOLINA SUPER', 'reseta': 6.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.60,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.46, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.60,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 7.30,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 8.00,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== F3 AC 2.0 CD 4X2 TM DIE ==========
    'F3 AC 2.0 CD 4X2 TM DIE': [
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.30, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL 80W90 GL5',
        'reseta': 2.65,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR DIESEL 15W40',
        'reseta': 4.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE DE MOTOR GASOLINA 10W40',
        'reseta': 3.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 415.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 13.90, 'unidad': 'ROLLO'},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.60,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.46, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.60,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 7.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.86,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== POER AC 2.0 CD 4X4 TM DIE ==========
    'POER AC 2.0 CD 4X4 TM DIE': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 3.20,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.20, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90',
        'reseta': 2.70,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
        'reseta': 5.80,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 7.50, 'unidad': 'ROLLO'},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE DIRECCION ATF III',
        'reseta': 1.05,
        'unidad': 'LT'
      },
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.84,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.34, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 7.80,
        'unidad': 'LT'
      },
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.20, 'unidad': 'LT'},
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.14,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== POER AC 2.0 CD 4X2 TM DIE ==========
    'POER AC 2.0 CD 4X2 TM DIE': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 3.20,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 3.20, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90',
        'reseta': 4.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
        'reseta': 5.80,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 7.50, 'unidad': 'ROLLO'},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE DIRECCION ATF III',
        'reseta': 1.05,
        'unidad': 'LT'
      },
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.84,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.70,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'REFRIGERANTE CELTA COOL - CRIOSOLUCIONES',
        'reseta': 8.20,
        'unidad': 'LT'
      },
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.20, 'unidad': 'LT'},
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.50,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.10,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== WINGLE 7 DIESEL 4X2 ==========
    'WINGLE 7 DIESEL 4X2': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 2.70,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.70, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90',
        'reseta': 2.70,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
        'reseta': 5.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 420.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.55,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75, 'unidad': 'ROLLO'},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE DIRECCION ATF III',
        'reseta': 0.78,
        'unidad': 'LT'
      },
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.78,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.80,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.50, 'unidad': 'LT'},
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.20,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.50,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== WINGLE 7 DIESEL 4X4 ==========
    'WINGLE 7 DIESEL 4X4': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 2.70,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.70, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90',
        'reseta': 4.50,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
        'reseta': 5.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 420.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.55,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 8.75, 'unidad': 'ROLLO'},
      {'nombre': 'COMBUSTIBLE DIESEL', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE DIRECCION ATF III',
        'reseta': 0.78,
        'unidad': 'LT'
      },
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.76,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.28, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.80,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'REFRIGERANTE L210', 'reseta': 8.50, 'unidad': 'LT'},
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.20,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.30,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],

    // ========== WINGLE STEED AC 2.4 ==========
    'WINGLE STEED AC 2.4': [
      {
        'nombre': 'ACEITE CAJA TRAXIUM GEAR 75W80',
        'reseta': 2.60,
        'unidad': 'LT'
      },
      {'nombre': 'ACEITE DE CAJA 80W90 GL4', 'reseta': 2.60, 'unidad': 'LT'},
      {
        'nombre': 'ACEITE DIFERENCIAL TRIUMAL DUAL FE 75W90',
        'reseta': 2.70,
        'unidad': 'LT'
      },
      {
        'nombre': 'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
        'reseta': 4.50,
        'unidad': 'LT'
      },
      {'nombre': 'AIRE ACONDICIONADO 134A', 'reseta': 480.00, 'unidad': 'GR'},
      {
        'nombre': 'CERA ANTICORROSIVA TOGOTEC PP 159',
        'reseta': 0.55,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'CINTA BUTILO GRIS', 'reseta': 10.00, 'unidad': 'ROLLO'},
      {'nombre': 'GASOLINA SUPER', 'reseta': 5.00, 'unidad': 'LT'},
      {
        'nombre': 'LIQUIDO DE DIRECCION ATF III',
        'reseta': 1.00,
        'unidad': 'LT'
      },
      {
        'nombre': 'LIQUIDO DE EMBRAGUE Y FRENOS DOT 4',
        'reseta': 0.70,
        'unidad': 'LT'
      },
      {'nombre': 'LIQUIDO LIMPIA PARABRISAS', 'reseta': 0.29, 'unidad': 'LT'},
      {
        'nombre': 'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
        'reseta': 0.60,
        'unidad': 'KG',
        'mideTanque': true
      },
      {'nombre': 'REFRIGERANTE L210', 'reseta': 7.80, 'unidad': 'LT'},
      {
        'nombre': 'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
        'reseta': 2.00,
        'unidad': 'KG',
        'mideTanque': true
      },
      {
        'nombre': 'SELLANTE PARA PVC (TOGOPLAST A-140) - PINTURA',
        'reseta': 7.50,
        'unidad': 'KG',
        'mideTanque': true
      },
    ],
  };

  // ============================================================
  // MÉTODOS
  // ============================================================

  static List<Map<String, dynamic>> getComponentesPorModelo(String modelo) {
    return datosPorModelo[modelo] ?? [];
  }

  static Future<List<Map<String, dynamic>>> getComponentesPorModeloAsync(
    String modelo,
  ) async {
    final predefinidos = datosPorModelo[modelo];
    if (predefinidos != null && predefinidos.isNotEmpty) {
      return predefinidos;
    }
    return await RecetasService.obtenerReceta(modelo);
  }

  static Future<List<String>> obtenerTodosLosModelos() async {
    final personalizadas = await RecetasService.obtenerTodas();
    final List<String> todos = List.from(modelos);
    for (final key in personalizadas.keys) {
      if (!todos.contains(key)) todos.add(key);
    }
    return todos;
  }

  static bool esPersonalizado(String modelo) {
    return !modelos.contains(modelo);
  }

  static Future<bool> tieneRecetaPersonalizada(String modelo) async {
    final receta = await RecetasService.obtenerReceta(modelo);
    return receta.isNotEmpty;
  }

  static Future<void> eliminarRecetaPersonalizada(String modelo) async {
    await RecetasService.eliminarReceta(modelo);
  }
}
