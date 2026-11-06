import 'package:flutter/material.dart';

/// 클럽 네온 테마 — 어두운 배경 + 네온 액센트.
/// 작명별의 파스텔 톤과 달리, 클럽 게임은 어둡고 강렬한 쪽이 맞는다.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF171724);
  static const Color surfaceLight = Color(0xFF23233A);
  static const Color neonPink = Color(0xFFFF2E88);
  static const Color neonCyan = Color(0xFF22D3EE);
  static const Color neonYellow = Color(0xFFFFC53D);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color textPrimary = Color(0xFFF4F4F8);
  static const Color textMuted = Color(0xFF9A9AB0);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: neonPink,
          secondary: neonCyan,
          surface: surface,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(fontSize: 15, color: textPrimary),
          bodySmall: TextStyle(fontSize: 13, color: textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: neonPink,
          inactiveTrackColor: surfaceLight,
          thumbColor: neonPink,
        ),
      );
}
