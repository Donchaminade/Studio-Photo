import 'package:flutter/material.dart';
import 'package:photo_app/payment_selection_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_photo.dart';
import 'package:photo_app/widgets/picon_ui.dart';
import 'package:photo_app/widgets/receipt_card.dart';

class OrderSummaryScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> orderDetails;

  const OrderSummaryScreen({super.key, required this.orderDetails});

  @override
  Widget build(BuildContext context) {
    final entries = orderDetails.entries.toList(growable: false);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: piconBar('Récapitulatif de la commande'),
      body: ReceiptBackdrop(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Unroll(
                        child: ReceiptCard(
                          title: 'REÇU DE COMMANDE',
                          status: 'EN ATTENTE',
                          statusColor: AppColors.accent,
                          subtitle: entries.isEmpty
                              ? 'Aucune ligne pour le moment'
                              : '${entries.length} article${entries.length > 1 ? 's' : ''}',
                          lines: const [],
                        ),
                      ),
                    );
                  }
                  final entry = entries[index - 1];
                  final details = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Reveal(
                      index: index,
                      child: PiconCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: PiconPhoto(source: entry.key, cachePixels: 240),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taille : ${details['size']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantité : ${details['quantity']}',
                                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PiconButton(
                  label: 'Confirmer et choisir le paiement',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentSelectionScreen(orderDetails: orderDetails),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
