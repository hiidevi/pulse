import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Emotional Palette
  static const Color primaryPink = Color(0xFFFFB6C1);
  static const Color softPeach = Color(0xFFFFDAB9);
  static const Color lavender = Color(0xFFE6E6FA);
  static const Color warmBeige = Color(0xFFF5F5DC);
  static const Color deepPurple = Color(0xFF6750A4);
  
  static LinearGradient mainGradient = const LinearGradient(
    colors: [primaryPink, softPeach, lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepPurple,
      brightness: Brightness.light,
      primary: deepPurple,
      secondary: primaryPink,
      tertiary: softPeach,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: deepPurple,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 18,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.8),
        foregroundColor: deepPurple,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );

  static ThemeData darkTheme = lightTheme; // For now

  static BoxDecoration glassBox = BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.3)),
  );

  // Emotional Themes Mapping
  static Map<String, dynamic> getEmojiTheme(String emoji) {
    // Warm Love / Hearts
    if (['❤️', '💖', '🌹', '🫂', '💓', '💗', '💌', '🥰', '💝', '🫶'].contains(emoji)) {
      return {
        'color': const Color(0xFFFF6B6B),
        'gradient': const LinearGradient(colors: [Color(0xFFFFB6C1), Color(0xFFFF6B6B)]),
        'shadow': const Color(0xFFFF6B6B).withOpacity(0.3),
        'name': 'Warm Love',
      };
    }
    // High Energy / Celebration
    if (['🔥', '✨', '⚡', '💥', '🚀', '🎉', '🏆', '🤩', '🎯', '👑'].contains(emoji)) {
      return {
        'color': const Color(0xFFFFD93D),
        'gradient': const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF8E31)]),
        'shadow': const Color(0xFFFF8E31).withOpacity(0.3),
        'name': 'Radiant Energy',
      };
    }
    // Calm / Balance / Nature
    if (['🌿', '🕊️', '🧘', '🍃', '🍀', '🌲', '🍵', '☀️', '🌻'].contains(emoji)) {
      return {
        'color': const Color(0xFF6BCB77),
        'gradient': const LinearGradient(colors: [Color(0xFFB4FF9F), Color(0xFF6BCB77)]),
        'shadow': const Color(0xFF6BCB77).withOpacity(0.3),
        'name': 'Inner Peace',
      };
    }
    // Deep / Mystical / Midnight
    if (['🌌', '🌚', '🔮', '💤', '🪐', '🌙', '💜', '🦄', '🎭'].contains(emoji)) {
      return {
        'color': const Color(0xFF7A1CAC),
        'gradient': const LinearGradient(colors: [Color(0xFFE6E6FA), Color(0xFF7A1CAC)]),
        'shadow': const Color(0xFF7A1CAC).withOpacity(0.3),
        'name': 'Deep Dream',
      };
    }
    // Soft / Emotional / Flow
    if (['🥺', '😭', '🌊', '💧', '☁️', '❄️', '🧊', '⚓', '🎐'].contains(emoji)) {
      return {
        'color': const Color(0xFF4D96FF),
        'gradient': const LinearGradient(colors: [Color(0xFFB4E4FF), Color(0xFF4D96FF)]),
        'shadow': const Color(0xFF4D96FF).withOpacity(0.3),
        'name': 'Soft Flow',
      };
    }
    // Default Fallback
    return {
      'color': deepPurple,
      'gradient': mainGradient,
      'shadow': deepPurple.withOpacity(0.2),
      'name': 'Pulse',
    };
  }
}
