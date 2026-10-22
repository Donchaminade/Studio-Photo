import 'package:flutter/material.dart';

/// Palette PICON « Bleu nuit » : deux couleurs primaires (bleu nuit + blanc)
/// et leurs dérivés. Aucune autre teinte d'accent.
class AppColors {
  // --- Primaires ---
  static const Color primary = Color(0xFF0B1A3A); // bleu nuit (contraste 16,9:1 sur blanc)
  static const Color white = Color(0xFFFFFFFF);

  // --- Dérivés du bleu nuit ---
  static const Color navyDeep = Color(0xFF040A1A); // fonds immersifs, splash
  static const Color primaryDark = Color(0xFF07122B); // dégradés, états pressés
  static const Color accent = Color(0xFF2C3F6B); // secondaire (10,6:1)
  static const Color primaryLight = Color(0xFF4A5E8C); // teinte claire (6,3:1)
  static const Color navyMuted = Color(0xFF8A93A8); // icônes décoratives
  static const Color navyMist = Color(0xFFB9C1D3); // bordures marquées
  static const Color surfaceTint = Color(0xFFE9EDF5); // pastilles, badges
  static const Color line = Color(0xFFDCE1EB);
  static const Color fieldFill = Color(0xFFF6F8FB);
  static const Color background = Color(0xFFF3F5F9);
  static const Color cardShadow = Color(0x140B1A3A);

  // --- Texte ---
  static const Color textPrimary = Color(0xFF0E1730); // 17,6:1
  static const Color textSecondary = Color(0xFF586179); // 6,2:1
  static const Color textOnPrimary = Colors.white;

  // --- Surfaces / états ---
  static const Color card = Colors.white;
  static const Color success = Color(0xFF1C2E5A); // état positif en bleu nuit
  static const Color warning = Color(0xFF4A5E8C); // état en attente, teinte du bleu
  static const Color error = Color(0xFFB42318); // seule exception sémantique (6,6:1)
  static const Color errorTint = Color(0xFFFDECEA);

  // Alias historiques, redirigés vers la palette bleu nuit
  static const Color orangeLight = surfaceTint;
  static const Color greenAir = surfaceTint;
}
