import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../branding/school_branding.dart';

/// Beautiful, modern theme for students and parents
final appThemeProvider = Provider<ThemeData>((ref) {
  final branding = ref.watch(schoolBrandingProvider);
  
  // Use school's primary color if available, otherwise use vibrant blue
  final primaryColor = branding.primaryColor ?? const Color(0xFF6366F1); // Indigo
  final secondaryColor = branding.secondaryColor ?? const Color(0xFF8B5CF6); // Purple
  
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: const Color(0xFFEC4899), // Pink accent
    surface: Colors.white,
    surfaceContainerHighest: const Color(0xFFF8FAFC),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF1E293B),
    onSurfaceVariant: const Color(0xFF64748B),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.05),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 1,
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white,
      selectedTileColor: primaryColor.withOpacity(0.1),
    ),

    // Icon Theme
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
      size: 24,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    ),
  );
});
