import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Ligne d'article d'un document PDF PICON.
class PiconPdfItem {
  final String format;
  final int quantity;
  final double unitPrice;
  const PiconPdfItem(this.format, this.quantity, this.unitPrice);
  double get total => unitPrice * quantity;
}

/// Ton du badge de statut.
enum PiconPdfTone { review, rejected, paid }

/// Données d'un document (bon de commande, reçu de paiement, reçu de commande).
class PiconPdfData {
  final String title;
  final String status;
  final PiconPdfTone tone;
  final List<MapEntry<String, String>> info;
  final List<PiconPdfItem> items;
  final List<MapEntry<String, String>> extraTotals;
  final double total;
  final String? note;
  final String? barcodeData;
  final String? thanks;
  const PiconPdfData({
    required this.title,
    required this.status,
    required this.tone,
    required this.info,
    required this.items,
    required this.total,
    this.extraTotals = const [],
    this.note,
    this.barcodeData,
    this.thanks,
  });
}

/// Ressources embarquées : police Inter (accents français) et logo.
class PiconPdfAssets {
  final Uint8List regular;
  final Uint8List bold;
  final Uint8List? logo;
  const PiconPdfAssets({required this.regular, required this.bold, this.logo});
}

const _navy = PdfColor.fromInt(0xFF0B1A3A);
const _navyDeep = PdfColor.fromInt(0xFF07122B);
const _accent = PdfColor.fromInt(0xFF2C3F6B);
const _muted = PdfColor.fromInt(0xFF586179);
const _text = PdfColor.fromInt(0xFF0E1730);
const _line = PdfColor.fromInt(0xFFDCE1EB);
const _tint = PdfColor.fromInt(0xFFE9EDF5);
const _zebra = PdfColor.fromInt(0xFFF6F8FB);
const _error = PdfColor.fromInt(0xFFB42318);
const _errorTint = PdfColor.fromInt(0xFFFDECEA);

String piconFcfa(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('\u00A0');
    b.write(s[i]);
  }
  return '$b FCFA';
}

/// Construit le PDF. La page suit [format] (A4 par défaut) : en paysage, la
/// mise en page s'étire sur toute la largeur.
Future<Uint8List> buildPiconPdf(PiconPdfData d, PiconPdfAssets a, {PdfPageFormat? format}) async {
  final base = format ?? PdfPageFormat.a4;
  final page = PdfPageFormat(base.width, base.height, marginAll: 0);
  final theme = pw.ThemeData.withFont(base: pw.Font.ttf(a.regular.buffer.asByteData()), bold: pw.Font.ttf(a.bold.buffer.asByteData()));
  final logo = a.logo == null ? null : pw.MemoryImage(a.logo!);
  const m = 40.0;
  final compact = page.width > page.height; // paysage : espacements resserrés
  final st = pw.TextStyle(fontSize: 10.5, color: _text);
  final bold = pw.TextStyle(fontSize: 10.5, color: _text, fontWeight: pw.FontWeight.bold);
  final label = pw.TextStyle(fontSize: 8.5, color: _muted, letterSpacing: 0.6);

  final (badgeFg, badgeBg) = switch (d.tone) {
    PiconPdfTone.rejected => (_error, _errorTint),
    PiconPdfTone.paid => (PdfColors.white, _accent),
    PiconPdfTone.review => (_navy, _tint),
  };

  pw.Widget header() => pw.Container(
        color: _navy,
        padding: pw.EdgeInsets.fromLTRB(m, compact ? 16 : 26, m, compact ? 16 : 26),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(
            width: 46,
            height: 46,
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
            child: logo == null ? pw.SizedBox() : pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('PICON', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 4)),
            pw.Text('Studio photo • Lomé', style: const pw.TextStyle(color: PdfColor(1, 1, 1, 0.75), fontSize: 9.5)),
          ]),
          pw.Spacer(),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(d.title, style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: d.tone == PiconPdfTone.paid ? PdfColors.white : badgeBg,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(d.status.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2,
                      color: d.tone == PiconPdfTone.paid ? _navy : badgeFg)),
            ),
          ]),
        ]),
      );

  pw.Widget infoGrid() {
    final cells = d.info
        .map((e) => pw.Container(
              padding: pw.EdgeInsets.fromLTRB(12, compact ? 6 : 9, 12, compact ? 6 : 9),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(e.key.toUpperCase(), style: label),
                pw.SizedBox(height: 3),
                pw.Text(e.value, style: bold.copyWith(fontSize: 11)),
              ]),
            ))
        .toList();
    final rows = <pw.TableRow>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(pw.TableRow(children: [cells[i], i + 1 < cells.length ? cells[i + 1] : pw.SizedBox()]));
    }
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Table(
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.6), verticalInside: pw.BorderSide(color: _line, width: 0.6)),
        children: rows,
      ),
    );
  }

  pw.Widget itemsTable() {
    pw.Widget cell(String t, pw.TextStyle s, {bool right = false}) => pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 5 : 8),
          child: pw.Text(t, style: s, textAlign: right ? pw.TextAlign.right : pw.TextAlign.left),
        );
    final head = pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8);
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.2), 2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(2)},
      border: const pw.TableBorder(bottom: pw.BorderSide(color: _line)),
      children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: _navy), children: [
          cell('FORMAT', head), cell('QTÉ', head, right: true), cell('PRIX UNITAIRE', head, right: true), cell('TOTAL', head, right: true),
        ]),
        for (var i = 0; i < d.items.length; i++)
          pw.TableRow(decoration: pw.BoxDecoration(color: i.isOdd ? _zebra : PdfColors.white), children: [
            cell(d.items[i].format, st),
            cell('${d.items[i].quantity}', st, right: true),
            cell(piconFcfa(d.items[i].unitPrice), st, right: true),
            cell(piconFcfa(d.items[i].total), bold, right: true),
          ]),
      ],
    );
  }

  pw.Widget totals() => pw.Row(children: [
        pw.Spacer(),
        pw.SizedBox(
          width: 240,
          child: pw.Column(children: [
            for (final e in d.extraTotals)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(e.key, style: st), pw.Text(e.value, style: bold)]),
              ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
                pw.Text(piconFcfa(d.total), style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ]),
        ),
      ]);

  pw.Widget note(String n) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: d.tone == PiconPdfTone.rejected ? _errorTint : _tint,
          border: pw.Border(left: pw.BorderSide(color: d.tone == PiconPdfTone.rejected ? _error : _navy, width: 3)),
        ),
        child: pw.Text(n, style: bold.copyWith(fontSize: 10.5, color: d.tone == PiconPdfTone.rejected ? _error : _navy)),
      );

  final doc = pw.Document(theme: theme, title: 'PICON - ${d.title}', author: 'PICON');
  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(pageFormat: page, margin: pw.EdgeInsets.zero, theme: theme),
    header: (c) => c.pageNumber == 1 ? header() : pw.SizedBox(height: m),
    footer: (c) => pw.Container(
      margin: pw.EdgeInsets.fromLTRB(m, 0, m, compact ? 14 : 24),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('PICON Studio photo • Lomé, Togo • Document généré depuis l\'application PICON', style: pw.TextStyle(fontSize: 8.5, color: _muted)),
        pw.Text('Page ${c.pageNumber} / ${c.pagesCount}', style: pw.TextStyle(fontSize: 8.5, color: _muted)),
      ]),
    ),
    build: (c) => [
      pw.Padding(
        padding: pw.EdgeInsets.fromLTRB(m, compact ? 14 : 24, m, 12),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          infoGrid(),
          pw.SizedBox(height: compact ? 12 : 22),
          pw.Text('ARTICLES', style: label.copyWith(fontWeight: pw.FontWeight.bold, color: _navyDeep)),
          pw.SizedBox(height: 8),
          itemsTable(),
          pw.SizedBox(height: 16),
          totals(),
          if (d.note != null) ...[pw.SizedBox(height: compact ? 12 : 22), note(d.note!)],
          if (d.barcodeData != null) ...[
            pw.SizedBox(height: 24),
            pw.Center(child: pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: d.barcodeData!, width: 220, height: 48, drawText: false, color: _text)),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text(d.barcodeData!, style: label.copyWith(letterSpacing: 2))),
          ],
          if (d.thanks != null) ...[pw.SizedBox(height: 14), pw.Center(child: pw.Text(d.thanks!, style: st.copyWith(color: _muted)))],
        ]),
      ),
    ],
  ));
  return doc.save();
}
