import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color.fromARGB(255, 106, 173, 215);
  static const secondaryColor = Color.fromARGB(255, 242, 151, 77);
  static const lightPrimaryColor = Color.fromARGB(255, 168, 214, 243);
  static const lightSecondaryColor = Color.fromARGB(255, 255, 212, 177);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: Colors.white,
      ),

      scaffoldBackgroundColor: const Color.fromARGB(255, 255, 239, 226),

      textTheme: GoogleFonts.montserratTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: lightSecondaryColor,
        unselectedItemColor: Colors.grey[300],
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Colors.orange[800],
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2.0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        labelStyle: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
