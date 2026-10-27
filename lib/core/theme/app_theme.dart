import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF6750A4);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
    );
  }

  static ThemeData amoled() {
    final base = dark();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: base.colorScheme.copyWith(surface: Colors.black),
    );
  }
}
