// lib/theme/automotive_theme.dart
import 'package:flutter/material.dart';

class AutomotiveTheme {
  static const Color carbonDark = Color(0xFF0D1117);
  static const Color carbonLight = Color(0xFF161B22);
  static const Color carbonSurface = Color(0xFF1A1F26);
  static const Color racingRed = Color(0xFFE63946);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color electricBlue = Color(0xFF1E90FF);
  static const Color chromeSilver = Color(0xFFB0BEC5);
  static const Color asphaltGray = Color(0xFF2A2F36);
  static const Color dashGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color purpleAccent = Color(0xFF9C27B0);

  static const LinearGradient racingGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient carbonGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF1F2630)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient speedGradient = LinearGradient(
    colors: [Color(0xFF1E90FF), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
