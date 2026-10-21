import 'dart:ui';

import 'package:Picon/utils/print_quality_utils.dart';

/// Conseil d'impression pour le studio (envoyé avec la commande, non affiché au client).
class StudioPrintAdvice {
  final String chosenFormat;
  final String chosenPrintQuality;
  final String? suggestedFormat;
  final String? suggestedPrintQuality;
  final String studioPrintAdvice;

  const StudioPrintAdvice({
    required this.chosenFormat,
    required this.chosenPrintQuality,
    this.suggestedFormat,
    this.suggestedPrintQuality,
    required this.studioPrintAdvice,
  });

  Map<String, dynamic> toOrderItemFields() => {
        'studioPrintAdvice': studioPrintAdvice,
        'chosenPrintQuality': chosenPrintQuality,
        if (suggestedFormat != null) 'suggestedPhotoSize': suggestedFormat,
        if (suggestedPrintQuality != null)
          'suggestedPrintQuality': suggestedPrintQuality,
      };
}

String _qualityCode(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return 'PERFECT';
    case PrintQuality.correct:
      return 'CORRECT';
    case PrintQuality.tooSmall:
      return 'TOO_SMALL';
  }
}

String _qualityLabelFr(PrintQuality q) {
  switch (q) {
    case PrintQuality.perfect:
      return 'qualité parfaite';
    case PrintQuality.correct:
      return 'qualité correcte';
    case PrintQuality.tooSmall:
      return 'qualité insuffisante';
  }
}

String? _findBestFormatForQuality(
  Size imageSize,
  Iterable<String> formats,
  PrintQuality target,
) {
  String? best;
  var bestScore = -1.0;
  for (final dim in formats) {
    final a = analyzePrintFit(imageSize, dim);
    if (a.quality != target) continue;
    final score = scorePrintFit(a);
    if (score > bestScore) {
      bestScore = score;
      best = dim;
    }
  }
  return best;
}

String _formatLine(PrintFitAnalysis a, String catalogFormat) {
  final orient = a.orientationSwapped
      ? ' (tirage ${a.effectiveSizeLabel})'
      : '';
  return '$catalogFormat$orient — ${_qualityLabelFr(a.quality)}, '
      '${a.dpi.round()} DPI, ${a.keepPercent} % conservé';
}

/// Calcule le conseil studio pour une photo et le format choisi par le client.
StudioPrintAdvice buildStudioPrintAdvice(
  Size imageSize,
  String chosenFormat,
  Iterable<String> catalogFormats,
) {
  final formats = catalogFormats.toList();
  final chosen = analyzePrintFit(imageSize, chosenFormat);
  final chosenCode = _qualityCode(chosen.quality);

  String? suggestedFormat;
  PrintQuality? suggestedQuality;

  if (chosen.quality == PrintQuality.tooSmall) {
    suggestedFormat = _findBestFormatForQuality(
          imageSize,
          formats,
          PrintQuality.perfect,
        ) ??
        _findBestFormatForQuality(
          imageSize,
          formats,
          PrintQuality.correct,
        ) ??
        findBestFormatForImage(imageSize, formats);
    if (suggestedFormat == chosenFormat) suggestedFormat = null;
  } else if (chosen.quality == PrintQuality.correct) {
    suggestedFormat =
        _findBestFormatForQuality(imageSize, formats, PrintQuality.perfect);
    if (suggestedFormat == chosenFormat) suggestedFormat = null;
  }

  if (suggestedFormat != null) {
    suggestedQuality = analyzePrintFit(imageSize, suggestedFormat).quality;
  }

  final buffer = StringBuffer();
  buffer.writeln(
    'Format choisi par le client : ${_formatLine(chosen, chosenFormat)}.',
  );

  if (suggestedFormat != null && suggestedQuality != null) {
    final sug = analyzePrintFit(imageSize, suggestedFormat);
    buffer.writeln(
      'Conseil studio : privilégier ${_formatLine(sug, suggestedFormat!)} '
      'si le client accepte un changement de format.',
    );
  } else if (chosen.quality == PrintQuality.perfect) {
    buffer.write(
      'Aucun changement de format conseillé — tirage optimal pour cette photo.',
    );
  } else {
    buffer.write(
      'Aucun format catalogue n\'offre une qualité supérieure ; '
      'valider avec le client ou refuser le tirage à cette taille.',
    );
  }

  return StudioPrintAdvice(
    chosenFormat: chosenFormat,
    chosenPrintQuality: chosenCode,
    suggestedFormat: suggestedFormat,
    suggestedPrintQuality:
        suggestedQuality != null ? _qualityCode(suggestedQuality) : null,
    studioPrintAdvice: buffer.toString().trim(),
  );
}
