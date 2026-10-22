import 'dart:typed_data';

import 'package:Picon/api_service.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:Picon/utils/picon_pdf.dart';
import 'package:Picon/utils/picon_pdf_assets.dart';
import 'package:printing/printing.dart';

/// Variante du reçu, déduite uniquement du statut renvoyé par l'API.
enum ReceiptVariant {
  /// Reçu 1 « Bon de commande » : preuve envoyée, paiement en vérification.
  review,

  /// Reçu 1 « Bon de commande » : paiement refusé (jamais de reçu 2).
  rejected,

  /// Reçu 2 « Reçu de paiement » : paiement validé (PAID / PROCESSING / COMPLETED).
  paid,
}

const _rejectedPaymentStatuses = {'REJECTED', 'PAYMENT_REJECTED', 'FAILED', 'REFUSED', 'DECLINED'};

String _up(Object? v) => (v?.toString() ?? '').trim().toUpperCase();

bool _hasProof(Map<String, dynamic> o) =>
    ['paymentProofImageUrl', 'paymentProofText', 'paymentProofType']
        .any((k) => (o[k]?.toString().trim().isNotEmpty ?? false));

/// Même règle que l'historique : PAID, ou commande PROCESSING/COMPLETED → payé.
ReceiptVariant receiptVariantFor(Map<String, dynamic> order) {
  final pay = _up(order['paymentStatus']);
  final status = _up(order['status']);
  if (_rejectedPaymentStatuses.contains(pay)) return ReceiptVariant.rejected;
  if (pay == 'PAID' || status == 'PROCESSING' || status == 'COMPLETED') return ReceiptVariant.paid;
  // Annulée après envoi d'une preuve, sans remboursement : paiement refusé.
  if (status == 'CANCELLED' && _hasProof(order) && pay != 'REFUNDED' && _up(order['refundStatus']) != 'REFUNDED') {
    return ReceiptVariant.rejected;
  }
  return ReceiptVariant.review;
}

/// Un reçu (1 ou 2) n'existe qu'une fois la preuve envoyée ou le paiement validé.
bool hasReceipt(Map<String, dynamic> order) =>
    _hasProof(order) ||
    _up(order['paymentStatus']) == 'CUSTOMER_REPORTED_PAID' ||
    receiptVariantFor(order) == ReceiptVariant.paid;

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

/// Écran unique des reçus : recharge la commande depuis l'API puis affiche la bonne variante.
class OrderReceiptScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic>? initialOrder;
  /// Date d'envoi de la preuve connue localement (juste après l'envoi).
  final DateTime? proofSentAt;
  /// false pour les captures/tests hors ligne.
  final bool refresh;

  const OrderReceiptScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.proofSentAt,
    this.refresh = true,
  });

  @override
  State<OrderReceiptScreen> createState() => _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends State<OrderReceiptScreen> {
  Map<String, dynamic>? _order;
  Object? _error;
  int _run = 0;
  bool _printed = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    if (widget.refresh) _load();
  }

  Future<void> _load() async {
    try {
      final o = await ApiService.fetchOrderRaw(widget.orderId);
      if (mounted) setState(() {
        _order = o;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  ReceiptVariant get _variant => receiptVariantFor(_order!);

  String get _title => _variant == ReceiptVariant.paid ? 'Reçu de paiement' : 'Bon de commande';

  List<_Line> get _items {
    final list = (_order!['orderItems'] as List? ?? const []).whereType<Map>();
    return list.map((m) {
      final q = (m['quantity'] as num?)?.toInt() ?? 1;
      final pu = (m['pricePerUnit'] as num?)?.toDouble() ?? 0;
      return _Line('${q}x ${m['photoSize'] ?? ''}', pu * q);
    }).toList();
  }

  double get _total => (_order!['totalAmount'] as num?)?.toDouble() ?? _items.fold(0.0, (a, b) => a + b.amount);
  String get _method => (_order!['paymentMethod']?.toString() ?? '—').toUpperCase();
  DateTime? get _proofDate =>
      _date(_order!['paymentProofSubmittedAt']) ?? _date(_order!['paymentConfirmedAt']) ?? widget.proofSentAt;
  /// Date de validation ; à défaut updatedAt (l'API ne l'expose pas toujours).
  DateTime? get _validatedAt =>
      _date(_order!['paymentValidatedAt']) ?? _date(_order!['paidAt']) ?? _date(_order!['updatedAt']);
  String get _receiptNo => 'RP-${widget.orderId.toString().padLeft(6, '0')}';
  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  String _d(DateTime? d) => d == null ? '—' : _fmt.format(d.toLocal());

  Widget _banner() {
    final rejected = _variant == ReceiptVariant.rejected;
    final color = rejected ? AppColors.error : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(rejected ? Icons.block_rounded : Icons.hourglass_top_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(rejected ? 'PAIEMENT REFUSÉ' : 'EN VÉRIFICATION',
              style: kTicketMono.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
        ),
      ]),
    );
  }

  Widget _ticket() {
    TextStyle mono([double size = 13, FontWeight w = FontWeight.w500]) =>
        kTicketMono.copyWith(fontSize: size, fontWeight: w);
    Widget line(String a, String b, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(a, style: mono(bold ? 15 : 13, bold ? FontWeight.w800 : FontWeight.w500))),
            const SizedBox(width: 8),
            Flexible(
              child: Text(b,
                  textAlign: TextAlign.right, style: mono(bold ? 15 : 13, bold ? FontWeight.w800 : FontWeight.w600)),
            ),
          ]),
        );
    final paid = _variant == ReceiptVariant.paid;
    return ClipPath(
      clipper: const ZigZagClipper(tooth: 9),
      child: Container(
        width: double.infinity,
        color: AppColors.fieldFill,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: PiconWordmark(height: 34)),
          const SizedBox(height: 6),
          Center(child: Text('STUDIO PHOTO • LOMÉ', style: mono(11, FontWeight.w700).copyWith(letterSpacing: 2))),
          const SizedBox(height: 8),
          Center(child: Text(_title.toUpperCase(), style: mono(14, FontWeight.w900).copyWith(letterSpacing: 2))),
          if (!paid) _banner(),
          const TicketDashes(),
          if (paid) line('REÇU N°', _receiptNo),
          line('COMMANDE', '#${widget.orderId}'),
          line('DATE', _d(_date(_order!['createdAt']))),
          const TicketDashes(),
          for (final i in _items) line(i.label, '${i.amount.toStringAsFixed(0)} F'),
          const TicketDashes(),
          line('TOTAL', '${_total.toStringAsFixed(0)} FCFA', bold: true),
          line('MOYEN', _method),
          line('PREUVE ENVOYÉE', _d(_proofDate)),
          if (paid) line('VALIDÉ LE', _d(_validatedAt)),
          if (paid) line('STATUT', 'PAYÉ'),
          const TicketDashes(),
          if (paid) ...[
            Center(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: _receiptNo,
                width: 210,
                height: 54,
                drawText: false,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Center(child: Text(_receiptNo, style: mono(11, FontWeight.w700).copyWith(letterSpacing: 2))),
            const SizedBox(height: 10),
            Center(child: Text('Merci pour votre confiance !', style: mono(12, FontWeight.w600))),
          ] else
            Text(
              'Ce document n\'est pas une preuve de paiement validé.',
              textAlign: TextAlign.center,
              style: mono(12, FontWeight.w800).copyWith(
                  color: _variant == ReceiptVariant.rejected ? AppColors.error : AppColors.warning),
            ),
        ]),
      ),
    );
  }

  Future<Uint8List> _pdf(PdfPageFormat format) async {
    final paid = _variant == ReceiptVariant.paid;
    final rejected = _variant == ReceiptVariant.rejected;
    final o = _order!;
    final client = [o['customerName'], o['userName'], o['fullName']]
        .map((v) => v?.toString().trim() ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final items = (o['orderItems'] as List? ?? const []).whereType<Map>().map((m) => PiconPdfItem(
          (m['photoSize'] ?? '').toString(),
          (m['quantity'] as num?)?.toInt() ?? 1,
          (m['pricePerUnit'] as num?)?.toDouble() ?? 0,
        ));
    final data = PiconPdfData(
      title: _title,
      status: paid ? 'Payé' : (rejected ? 'Paiement refusé' : 'En vérification'),
      tone: paid ? PiconPdfTone.paid : (rejected ? PiconPdfTone.rejected : PiconPdfTone.review),
      info: [
        if (paid) MapEntry('Reçu n°', _receiptNo),
        MapEntry('Commande n°', '#${widget.orderId}'),
        MapEntry('Date', _d(_date(o['createdAt']))),
        if (client.isNotEmpty) MapEntry('Client', client),
        MapEntry('Moyen de paiement', _method),
        MapEntry('Preuve envoyée', _d(_proofDate)),
        if (paid) MapEntry('Validé le', _d(_validatedAt)),
      ],
      items: items.toList(),
      total: _total,
      note: paid ? null : "Ce document n'est pas une preuve de paiement validée.",
      barcodeData: paid ? _receiptNo : null,
      thanks: paid ? 'Merci pour votre confiance !' : null,
    );
    return buildPiconPdf(data, await loadPiconPdfAssets(), format: format);
  }

  ButtonStyle get _outline => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.navyDeep, AppColors.navyDeep],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 22, 6),
              child: Row(children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o == null ? 'Reçu' : _title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('Commande #${widget.orderId}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                ),
                const PiconLogoPill(height: 18),
              ]),
            ),
            Expanded(
              child: o == null
                  ? (_error != null
                      ? Padding(
                          padding: const EdgeInsets.all(18),
                          child: PiconCard(child: AppInlineError(error: _error!, onRetry: _load)),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: PrintedReceipt(
                              key: ValueKey('$_run-${_variant.name}'),
                              ticket: _ticket(),
                              showStamp: _variant == ReceiptVariant.paid,
                              onPrinted: () {
                                if (mounted) setState(() => _printed = true);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            if (o != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _printed ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _printed = false;
                          _run++;
                        }),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Réimprimer'),
                        style: _outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Printing.layoutPdf(onLayout: _pdf),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Imprimer / PDF'),
                        style: _outline,
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Line {
  final String label;
  final double amount;
  const _Line(this.label, this.amount);
}
