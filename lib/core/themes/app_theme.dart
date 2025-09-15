import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkGlass {
    const Color primary = Color(0xFF0A2540);
    const Color surface = Color(0xFF0F2D4A);
    const Color accent = Color(0xFF3BA7FF);

    const ColorScheme scheme = ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF071A2C),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

