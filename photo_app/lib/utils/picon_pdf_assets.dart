import 'package:flutter/services.dart' show rootBundle;

import 'picon_pdf.dart';

PiconPdfAssets? _cache;

/// Charge (une fois) la police Inter et le logo PICON depuis les assets.
Future<PiconPdfAssets> loadPiconPdfAssets() async {
  if (_cache != null) return _cache!;
  final r = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
  final b = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
  final l = await rootBundle.load('assets/logos/image.png');
  return _cache = PiconPdfAssets(regular: r.buffer.asUint8List(), bold: b.buffer.asUint8List(), logo: l.buffer.asUint8List());
}
