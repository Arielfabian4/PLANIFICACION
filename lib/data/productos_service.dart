// lib/data/productos_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductosService {
  static const String _key = 'productos_personalizados';

  /// Lista base de productos predefinidos (los que ya tienes hardcodeados)
  static const List<String> productosBase = [
    'ACEITE CAJA SYNGEAR AT 75W90 GL4 - VEEDOL',
    'ACEITE DE CAJA 80W90 GL4',
    'ACEITE DE CAJA AUTOMÁTICA WOLVER DSG - G01',
    'ACEITE DE DIFERENCIAL 80W90 GL5',
    'ACEITE DE MOTOR DIESEL 15W40',
    'ACEITE DE MOTOR ENI I-SINT 5W-30',
    'ACEITE DE MOTOR GASOLINA 10W40',
    'ACEITE DIFERENCIAL TRAXIUM DUAL FE 9 75W90',
    'ACEITE MOTOR DIESEL QUARTZ INEO MC-3 5W-30',
    'ACEITE MOTOR DIESEL/GAS QUARTZ INEO MC-3 5W-30',
    'AIRE ACONDICIONADO GLOBAL -134A',
    'AIRE ACONDICIONADO IZETROM -134A',
    'CERA ANTICORROSIVA TOGOTEC PP 159',
    'CINTA BUTILO GRIS',
    'COMBUSTIBLE DIESEL',
    'GASOLINA SUPER',
    'LÍQUIDO DE DIRECCIÓN ATF III',
    'LÍQUIDO DE EMBRAGUE Y FRENOS DOT 4',
    'LIQUIDO LIMPIA PARABRISAS',
    'POLIURETANO PARA PARABRISAS TOGOCOLL DA 280',
    'POLIURETANO PARABRISAS DRUM 246 KL (57302N)',
    'REFRIGERANTE CELTA COOL - CRYOSOLUCIONES',
    'REFRIGERANTE L210',
    'SELLANTE DE JUNTA (ESFEAL 8701) - PINTURA',
    'SELLANTE PARA PVC  (TOGOPLAST A-140) - PINTURA',
  ];

  /// Obtiene todos los productos (base + personalizados)
  static Future<List<String>> obtenerTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    final List<String> personalizados =
        data != null ? List<String>.from(jsonDecode(data)) : [];

    final Set<String> combinados = {...productosBase, ...personalizados};
    final lista = combinados.toList()..sort();
    return lista;
  }

  /// Obtiene solo los productos personalizados
  static Future<List<String>> obtenerPersonalizados() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  /// Agrega un nuevo producto personalizado
  static Future<bool> agregarProducto(String nombre) async {
    final normalizado = nombre.trim().toUpperCase();
    if (normalizado.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    final List<String> actuales =
        data != null ? List<String>.from(jsonDecode(data)) : [];

    if (productosBase.contains(normalizado) || actuales.contains(normalizado)) {
      return false;
    }

    actuales.add(normalizado);
    await prefs.setString(_key, jsonEncode(actuales));
    return true;
  }

  /// Elimina un producto personalizado
  static Future<void> eliminarProducto(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;

    final List<String> actuales = List<String>.from(jsonDecode(data));
    actuales.remove(nombre);
    await prefs.setString(_key, jsonEncode(actuales));
  }

  /// Verifica si un producto es personalizado
  static bool esPersonalizado(String nombre) {
    return !productosBase.contains(nombre);
  }
}
