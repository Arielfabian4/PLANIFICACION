import 'package:flutter/material.dart';

class CiautoColors {
  static const Color red = Color(0xFFD32F2F);
  static const Color redDark = Color(0xFFB71C1C);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color dark = Color(0xFF1A1F36);
  static const Color gray = Color(0xFF5A6477);
  static const Color light = Color(0xFFF5F7FA);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color border = Color(0xFFE4E7EC);

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1F36), Color(0xFF2C3450)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class CiautoTheme {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: CiautoColors.red,
        primary: CiautoColors.red,
        secondary: CiautoColors.dark,
        surface: Colors.white,
        background: CiautoColors.light,
      ),
      scaffoldBackgroundColor: CiautoColors.light,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: CiautoColors.red,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CiautoColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CiautoColors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CiautoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CiautoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CiautoColors.red, width: 2),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: CiautoColors.gray,
        ),
      ),
    );
  }
}
