import 'package:flutter/material.dart';

class AppColors {
  // Dark theme
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF151B2E);
  static const Color darkCard = Color(0xFF1E2640);
  static const Color darkPrimary = Color(0xFF1A6CF5);
  static const Color gymAccent = Color(0xFFFF6B35);
  static const Color swimAccent = Color(0xFF00D4FF);
  static const Color cardioAccent = Color(0xFF34D399);
  static const Color darkText = Color(0xFFE8EEFF);
  static const Color darkTextSecondary = Color(0xFF8B9CC8);

  // Light theme
  static const Color lightBackground = Color(0xFFF0F4F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightText = Color(0xFF1A1E2E);
  static const Color lightTextSecondary = Color(0xFF6B7DB3);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.gymAccent,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: AppColors.darkText,
            fontSize: 28,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: AppColors.darkText,
            fontSize: 22,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 16),
        bodyMedium:
            TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        labelLarge: TextStyle(
            color: AppColors.darkPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.gymAccent,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha:0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: AppColors.lightText,
            fontSize: 28,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: AppColors.lightText,
            fontSize: 22,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 16),
        bodyMedium:
            TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
        labelLarge: TextStyle(
            color: AppColors.lightPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
