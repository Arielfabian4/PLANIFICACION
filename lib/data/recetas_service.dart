// lib/data/recetas_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecetasService {
  static const String _key = 'recetas_personalizadas';

  /// Guarda la receta de un modelo personalizado
  static Future<void> guardarReceta(
    String modelo,
    List<Map<String, dynamic>> receta,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    final Map<String, dynamic> recetas =
        data != null ? Map<String, dynamic>.from(jsonDecode(data)) : {};

    recetas[modelo] = receta;
    await prefs.setString(_key, jsonEncode(recetas));
  }

  /// Obtiene la receta de un modelo personalizado
  static Future<List<Map<String, dynamic>>> obtenerReceta(String modelo) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    final Map<String, dynamic> recetas =
        Map<String, dynamic>.from(jsonDecode(data));
    final receta = recetas[modelo];
    if (receta == null) return [];

    return List<Map<String, dynamic>>.from(
      (receta as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  /// Obtiene todas las recetas personalizadas
  static Future<Map<String, dynamic>> obtenerTodas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  /// Elimina la receta de un modelo
  static Future<void> eliminarReceta(String modelo) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;

    final Map<String, dynamic> recetas =
        Map<String, dynamic>.from(jsonDecode(data));
    recetas.remove(modelo);
    await prefs.setString(_key, jsonEncode(recetas));
  }
}
