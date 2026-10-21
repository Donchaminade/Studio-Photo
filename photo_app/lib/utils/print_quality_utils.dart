import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  Qualité d'impression : orientation auto + DPI mode cover
// ─────────────────────────────────────────────────────────────

/// Niveaux de qualité pour l'impression photo.
enum PrintQuality { perfect, correct, tooSmall }

/// Conversion : 1 pouce = 2.54 cm
const double kInchToCm = 2.54;

/// Seuils DPI (tirage photo labo)
const double kDpiPerfect = 250;
const double kDpiCorrect = 150;

/// Seuils de pixels conservés (mode cover, comme l'aperçu / l'impression)
const double kKeepPerfect = 0.85;
const double kKeepCorrect = 0.75;

/// Résultat d'analyse pour un couple image + format catalogue.
class PrintFitAnalysis {
  final double widthCm;
  final double heightCm;
  final bool orientationSwapped;
  final double displayAspect;
  final double keepFraction;
  final double dpi;
  final PrintQuality quality;

  const PrintFitAnalysis({
    required this.widthCm,
    required this.heightCm,
    required this.orientationSwapped,
    required this.displayAspect,
    required this.keepFraction,
    required this.dpi,
    required this.quality,
  });

  int get keepPercent => (keepFraction * 100).round();

  String get effectiveSizeLabel {
    final w = _fmt(widthCm);
    final h = _fmt(heightCm);
    return '${w}x$h cm';
  }

  static String _fmt(double v) {
    return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  }
}

class ResolvedFormatOrientation {
  final double widthCm;
  final double heightCm;
  final bool swapped;

  const ResolvedFormatOrientation({
    required this.widthCm,
    required this.heightCm,
    required this.swapped,
  });

  double get aspect => heightCm == 0 ? 1 : widthCm / heightCm;
}

// ─────────────────────────────────────────────────────────────
//  Parsing formats
// ─────────────────────────────────────────────────────────────

/// Parse une dimension (ex: "10x15 cm") → (largeur, hauteur) en cm (libellé catalogue).
(double w, double h) parseDimensionCm(String dimension) {
  final matches = RegExp(r'(\d+([.,]\d+)?)').allMatches(dimension).toList();
  if (matches.length >= 2) {
    final w = double.tryParse(matches[0].group(1)!.replaceAll(',', '.')) ?? 1;
    final h = double.tryParse(matches[1].group(1)!.replaceAll(',', '.')) ?? 1;
    return (w, h);
  }
  return (10, 15);
}

/// Ratio catalogue brut (sans tenir compte de la photo).
double dimensionAspect(String dimension) {
  final (w, h) = parseDimensionCm(dimension);
  return h == 0 ? 1 : w / h;
}

/// Choisit 10×15 ou 15×10 selon la photo (portrait / paysage).
ResolvedFormatOrientation resolveFormatOrientation(
  String dimension,
  Size imageSize,
) {
  final (w, h) = parseDimensionCm(dimension);
  if (imageSize.width <= 0 || imageSize.height <= 0) {
    return ResolvedFormatOrientation(widthCm: w, heightCm: h, swapped: false);
  }

  final imgAspect = imageSize.width / imageSize.height;
  final normalAspect = w / h;
  final swappedAspect = h / w;

  final normalDiff = (imgAspect - normalAspect).abs();
  final swappedDiff = (imgAspect - swappedAspect).abs();

  if (swappedDiff < normalDiff - 0.001) {
    return ResolvedFormatOrientation(widthCm: h, heightCm: w, swapped: true);
  }
  return ResolvedFormatOrientation(widthCm: w, heightCm: h, swapped: false);
}

/// Ratio du cadre d'aperçu (aligné sur l'impression cover).
double displayAspectForFormat(String dimension, Size imageSize) {
  return resolveFormatOrientation(dimension, imageSize).aspect;
}

// ─────────────────────────────────────────────────────────────
//  DPI & rognage (mode cover, comme l'aperçu)
// ─────────────────────────────────────────────────────────────

/// Fraction de pixels conservés après rognage centré (cover).
double computeKeepFraction(Size imageSize, double targetAspect) {
  if (imageSize.width <= 0 || imageSize.height <= 0) return 0;
  final imageAspect = imageSize.width / imageSize.height;
  if (imageAspect > targetAspect) return targetAspect / imageAspect;
  return imageAspect / targetAspect;
}

double computeKeepFractionForFormat(Size imageSize, String dimension) {
  final orient = resolveFormatOrientation(dimension, imageSize);
  return computeKeepFraction(imageSize, orient.aspect);
}

/// DPI effectif en mode cover (ce qui est réellement imprimé).
double computeDpiCover(Size imageSize, double paperWidthCm, double paperHeightCm) {
  if (imageSize.width <= 0 ||
      imageSize.height <= 0 ||
      paperWidthCm <= 0 ||
      paperHeightCm <= 0) {
    return 0;
  }

  final paperWIn = paperWidthCm / kInchToCm;
  final paperHIn = paperHeightCm / kInchToCm;
  final imageAspect = imageSize.width / imageSize.height;
  final paperAspect = paperWidthCm / paperHeightCm;

  if (imageAspect > paperAspect) {
    return imageSize.height / paperHIn;
  }
  return imageSize.width / paperWIn;
}

/// Analyse complète image + format (orientation auto incluse).
PrintFitAnalysis analyzePrintFit(Size imageSize, String dimension) {
  final orient = resolveFormatOrientation(dimension, imageSize);
  final keep = computeKeepFraction(imageSize, orient.aspect);
  final dpi = computeDpiCover(imageSize, orient.widthCm, orient.heightCm);
  return PrintFitAnalysis(
    widthCm: orient.widthCm,
    heightCm: orient.heightCm,
    orientationSwapped: orient.swapped,
    displayAspect: orient.aspect,
    keepFraction: keep,
    dpi: dpi,
    quality: combinedPrintQuality(dpi, keep),
  );
}

/// DPI pour un format (orientation auto + cover).
double computeDpi(Size imageSize, String dimension) {
  return analyzePrintFit(imageSize, dimension).dpi;
}

/// Score interne : privilégie le cadrage puis le DPI (parmi formats déjà filtrés).
double scorePrintFit(PrintFitAnalysis a) => a.keepFraction * 10000 + a.dpi;

/// Meilleur format : DPI imprimable d'abord (≥ 150), puis max cadrage + DPI.
String findBestFormatForImage(Size imageSize, Iterable<String> formatNames) {
  final names = formatNames.toList();
  if (names.isEmpty) return '10x15 cm';

  final analyses =
      names.map((d) => MapEntry(d, analyzePrintFit(imageSize, d))).toList();

  final printable =
      analyses.where((e) => e.value.dpi >= kDpiCorrect).toList();
  final pool = printable.isNotEmpty ? printable : analyses;

  var best = pool.first.key;
  var bestScore = scorePrintFit(pool.first.value);
  for (final e in pool.skip(1)) {
    final score = scorePrintFit(e.value);
    if (score > bestScore) {
      bestScore = score;
      best = e.key;
    }
  }
  return best;
}

// ─────────────────────────────────────────────────────────────
//  Qualité (affichage)
// ─────────────────────────────────────────────────────────────

/// Qualité combinée : résolution ET cadrage (alignée sur l'aperçu cover).
PrintQuality combinedPrintQuality(double dpi, double keepFraction) {
  if (dpi < kDpiCorrect) return PrintQuality.tooSmall;
  if (dpi >= kDpiPerfect && keepFraction >= kKeepPerfect) {
    return PrintQuality.perfect;
  }
  return PrintQuality.correct;
}

PrintQuality qualityFromDpi(double dpi) => combinedPrintQuality(dpi, 1);

PrintQuality qualityFromKeepFraction(double keepFraction) =>
    combinedPrintQuality(kDpiPerfect, keepFraction);

/// Libellé contextuel selon DPI + % conservé.
String qualityLabelForAnalysis(PrintFitAnalysis a) {
  switch (a.quality) {
    case PrintQuality.perfect:
      return 'Qualité parfaite';
    case PrintQuality.correct:
      if (a.dpi >= kDpiPerfect && a.keepFraction < kKeepPerfect) {
        return 'Net à l\'impression, cadrage serré';
      }
      if (a.dpi < kDpiPerfect && a.keepFraction >= kKeepPerfect) {
        return 'Bon cadrage, résolution limite';
      }
      return 'Qualité correcte';
    case PrintQuality.tooSmall:
      return 'Image trop petite';
  }
}

/// Conseil court sous le bandeau qualité.
String? qualityAdviceForAnalysis(PrintFitAnalysis a) {
  if (a.quality == PrintQuality.tooSmall) {
    return 'Choisissez un format plus petit pour cette photo.';
  }
  if (a.quality == PrintQuality.correct &&
      a.dpi >= kDpiPerfect &&
      a.keepFraction < kKeepPerfect) {
    return 'L\'impression sera nette, mais une partie de l\'image sera rognée (comme l\'aperçu). Essayez un format au ratio plus proche.';
  }
  if (a.quality == PrintQuality.correct && a.dpi < kDpiPerfect) {
    return 'Résolution acceptable ; un format un peu plus petit améliorerait la netteté.';
  }
  return null;
}

IconData qualityIcon(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return Icons.check_circle;
    case PrintQuality.correct:
      return Icons.warning_amber_rounded;
    case PrintQuality.tooSmall:
      return Icons.cancel;
  }
}

Color qualityColor(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return const Color(0xFF2E7D32);
    case PrintQuality.correct:
      return const Color(0xFFE65100);
    case PrintQuality.tooSmall:
      return const Color(0xFFC62828);
  }
}

Color qualityLightColor(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return const Color(0xFFE8F5E9);
    case PrintQuality.correct:
      return const Color(0xFFFFF3E0);
    case PrintQuality.tooSmall:
      return const Color(0xFFFFEBEE);
  }
}

String qualityLabel(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return 'Qualité parfaite';
    case PrintQuality.correct:
      return 'Qualité correcte';
    case PrintQuality.tooSmall:
      return 'Image trop petite';
  }
}

/// Rappel : l'aperçu = le tirage (cover centré).
String printPreviewHint(PrintFitAnalysis a) {
  if (a.quality == PrintQuality.perfect) {
    return 'L\'impression correspond à cet aperçu (même cadrage, sans perte notable).';
  }
  return 'L\'impression correspond à cet aperçu : parties rognées = non imprimées.';
}

String qualityEmoji(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return '🟢';
    case PrintQuality.correct:
      return '🟡';
    case PrintQuality.tooSmall:
      return '🔴';
  }
}

String cropSummary(PrintFitAnalysis a) {
  if (a.keepPercent >= 98) {
    return 'Cadrage optimal — quasi aucune perte';
  }
  if (a.keepPercent >= 85) {
    return '${a.keepPercent} % de l\'image imprimée (léger rognage)';
  }
  return '${a.keepPercent} % de l\'image imprimée (rognage sur les bords)';
}
