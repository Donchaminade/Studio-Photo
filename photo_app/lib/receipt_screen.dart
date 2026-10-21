import 'dart:typed_data';
import 'package:Picon/utils/colors.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final String paymentMethod;
  final String orderId;
  final String userName;
  final String userPhone;
  final Map<String, double> prices;

  const ReceiptScreen({
    super.key,
    required this.orderDetails,
    required this.paymentMethod,
    required this.orderId,
    this.userName = "Client",
    this.userPhone = "+XXX XXXXXXXX",
    required this.prices,
  });

  double _calculateTotalPrice(Map<String, Map<String, dynamic>> details, String paymentMethod) {
    double subtotal = 0;
    details.forEach((key, item) {
      final price = prices[item['size']] ?? 0;
      subtotal += price * (item['quantity'] as int);
    });
    bool isExpress = paymentMethod.contains("Xpress") || paymentMethod.contains("Express");
    if (isExpress && details.keys.length <= 10) {
      subtotal += 1500;
    }
    return subtotal;
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final totalPrice = _calculateTotalPrice(orderDetails, paymentMethod);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reçu de Commande', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Commande ID:', style: pw.TextStyle(fontSize: 16)),
                  pw.Expanded(
                    child: pw.Text(
                      orderId,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              pw.Text('Date: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Client: $userName'),
              pw.Text('Contact: $userPhone'),
              pw.SizedBox(height: 20),
              pw.Text('Articles Commandés:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.ListView.separated(
                itemCount: orderDetails.length,
                itemBuilder: (context, index) {
                  final entry = orderDetails.entries.elementAt(index);
                  final item = entry.value;
                  final itemPrice = prices[item['size']] ?? 0;
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${item['quantity']}x ${item['size']}')),
                      pw.Text('${(itemPrice * (item['quantity'] as int)).toStringAsFixed(0)} FCFA'),
                    ],
                  );
                },
                separatorBuilder: (context, index) => pw.Divider(height: 10, borderStyle: pw.BorderStyle.dashed),
              ),
              pw.Divider(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode de paiement:'),
                  pw.Text(paymentMethod),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text('${totalPrice.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: orderId,
                  width: 100,
                  height: 100,
                ),
              ),
              pw.Center(child: pw.Text('Merci pour votre confiance !')),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commande Terminée'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              ClipPath(
                clipper: TicketClipper(),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildInfoSection(),
                      const SizedBox(height: 20),
                      const DashedSeparator(),
                      const SizedBox(height: 20),
                      _buildItemsSection(),
                      const SizedBox(height: 20),
                      const DashedSeparator(),
                      const SizedBox(height: 20),
                      _buildTotalsSection(),
                      const SizedBox(height: 30),
                      _buildQrCode(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white, size: 40),
        ),
        SizedBox(height: 16),
        Text(
          'Commande Réussie',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          'Votre commande a bien été transmise.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoRow('Commande ID:', orderId),
        const SizedBox(height: 8),
        _buildInfoRow('Date:', DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())),
        const SizedBox(height: 8),
        _buildInfoRow('Client:', userName),
      ],
    );
  }

  Widget _buildItemsSection() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orderDetails.length,
      itemBuilder: (context, index) {
        final entry = orderDetails.entries.elementAt(index);
        final item = entry.value;
        final itemPrice = prices[item['size']] ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${item['quantity']}x ${item['size']}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              '${(itemPrice * (item['quantity'] as int)).toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }

  Widget _buildTotalsSection() {
    final totalPrice = _calculateTotalPrice(orderDetails, paymentMethod);
    return Column(
      children: [
        _buildInfoRow('Paiement:', paymentMethod),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${totalPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCode() {
    return Center(
      child: Column(
        children: [
          BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: orderId,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 8),
          const Text('Merci de votre confiance !', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Printing.layoutPdf(onLayout: (format) => _generatePdf()),
            icon: const Icon(Icons.print),
            label: FittedBox(fit: BoxFit.scaleDown, child: const Text('Imprimer')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: FittedBox(fit: BoxFit.scaleDown, child: const Text('Fermer')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          Expanded(
            flex: 2, // Give more space to the value
            child: Text(
              value,
              textAlign: TextAlign.right, // Align the ID to the right
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis, // Add ellipsis if still too long
            ),
          ),
        ],
      ),
    );
  }
}

class DashedSeparator extends StatelessWidget {
  const DashedSeparator({super.key, this.height = 1, this.color = Colors.grey});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double notchRadius = 15.0;
    
    path.lineTo(0, size.height * 0.3 - notchRadius);
    path.arcToPoint(Offset(0, size.height * 0.3 + notchRadius), radius: const Radius.circular(notchRadius), clockwise: false);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.3 + notchRadius);
    path.arcToPoint(Offset(size.width, size.height * 0.3 - notchRadius), radius: const Radius.circular(notchRadius), clockwise: false);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}