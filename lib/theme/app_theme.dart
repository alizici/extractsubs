// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // macOS benzeri temalar oluşturmak için metotlar
  static ThemeData lightTheme() {
    const primaryColor = Color(0xFF007AFF); // macOS mavi

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF5AC8FA),
        surface: Colors.white.withAlpha(229), // 0.9 * 255 = 229
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white.withAlpha(178), // 0.7 * 255 = 178
        shadowColor: Colors.black.withAlpha(26), // 0.1 * 255 = 26
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white.withAlpha(204), // 0.8 * 255 = 204
        foregroundColor: Colors.black,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        toolbarHeight: 48,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        color: Color(0xFFD1D1D6),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8E8E93),
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(40, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(128), // 0.5 * 255 = 128
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withAlpha(26), // 0.1 * 255 = 26
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return const Color(0xFFD1D1D6);
          },
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return const Color(0xFF8E8E93);
          },
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2C2C2E).withAlpha(242), // 0.95 * 255 = 242
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white.withAlpha(242), // 0.95 * 255 = 242
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    const primaryColor = Color(0xFF0A84FF); // macOS koyu mavi

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF5AC8FA),
        surface: const Color(0xFF2C2C2E).withAlpha(229), // 0.9 * 255 = 229
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2C2C2E).withAlpha(178), // 0.7 * 255 = 178
        shadowColor: Colors.black.withAlpha(77), // 0.3 * 255 = 77
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor:
            const Color(0xFF1C1C1E).withAlpha(204), // 0.8 * 255 = 204
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        toolbarHeight: 48,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        color: Color(0xFF38383A),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8E8E93),
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(40, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E).withAlpha(128), // 0.5 * 255 = 128
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withAlpha(51), // 0.2 * 255 = 51
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return const Color(0xFF636366);
          },
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return const Color(0xFF8E8E93);
          },
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2C2C2E).withAlpha(242), // 0.95 * 255 = 242
      ),
      dialogTheme: DialogTheme(
        backgroundColor:
            const Color(0xFF2C2C2E).withAlpha(242), // 0.95 * 255 = 242
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF2C2C2E).withAlpha(242), // 0.95 * 255 = 242
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
