import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Definisi typography menggunakan Google Fonts (Inter).
class AppTextStyles {
  AppTextStyles._();

  // Display
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // Headline
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Title
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Label
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Special — POS Price Display
  static TextStyle priceDisplay = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle priceTag = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}
