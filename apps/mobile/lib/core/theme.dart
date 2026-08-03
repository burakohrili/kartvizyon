import 'package:flutter/material.dart';

abstract final class KartVizyonTheme {
  static const navy = Color(0xFF1B1F3B);
  static const yellow = Color(0xFFF4B400);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: yellow,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: Color(0xFFFFE8A0),
    ),
  );
}
