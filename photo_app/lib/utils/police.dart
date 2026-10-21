import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Définition de la famille de police principale
final TextStyle primaryFont = GoogleFonts.poppins();

// Définition du TextTheme global basé sur Poppins
TextTheme buildPoppinsTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: primaryFont.copyWith(fontSize: 57, fontWeight: FontWeight.normal),
    displayMedium: primaryFont.copyWith(fontSize: 45, fontWeight: FontWeight.normal),
    displaySmall: primaryFont.copyWith(fontSize: 36, fontWeight: FontWeight.normal),
    headlineLarge: primaryFont.copyWith(fontSize: 32, fontWeight: FontWeight.normal),
    headlineMedium: primaryFont.copyWith(fontSize: 28, fontWeight: FontWeight.normal),
    headlineSmall: primaryFont.copyWith(fontSize: 24, fontWeight: FontWeight.normal),
    titleLarge: primaryFont.copyWith(fontSize: 22, fontWeight: FontWeight.normal),
    titleMedium: primaryFont.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: primaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    labelLarge: primaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: primaryFont.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: primaryFont.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    bodyLarge: primaryFont.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: primaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: primaryFont.copyWith(fontSize: 12, fontWeight: FontWeight.normal),
  );
}
