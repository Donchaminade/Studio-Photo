import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_photo.dart';
import 'package:photo_app/widgets/picon_ui.dart';
import 'package:photo_app/widgets/receipt_card.dart';

Future<void> submitOrder(
    String userId,
    Map<String, Map<String, dynamic>> orderDetails,
    BuildContext context) async {
  const String apiUrl = 'http://10.0.2.2/studio/submit_order.php';

  String orderDetailsJson = jsonEncode(orderDetails);

  Map<String, String> headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Map<String, String> body = {
    'user_id': userId,
    'order_details': orderDetailsJson,
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );
    if (!context.mounted) return;

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande enregistrée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${responseData['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: impossible de contacter le serveur')),
      );
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Erreur lors de l\'enregistrement de la commande: $error')),
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final String paymentMethod;

  const ConfirmationScreen({
    super.key,
    required this.orderDetails,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final entries = orderDetails.entries.toList(growable: false);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: piconBar('Confirmation de la commande'),
      body: ReceiptBackdrop(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Unroll(
                  child: ReceiptCard(
                    title: 'REÇU OFFICIEL',
                    status: 'PAYÉ',
                    subtitle: 'Commande confirmée avec succès !',
                    lines: [
                      _line('Mode de paiement', paymentMethod),
                      for (var i = 0; i < entries.length; i++)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: PiconPhoto(source: entries[i].key, cachePixels: 140),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taille : ${entries[i].value['size']}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Quantité : ${entries[i].value['quantity']}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                    footer: Text(
                      entries.isEmpty ? 'Aucun article' : '${entries.length} article${entries.length > 1 ? 's' : ''}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PiconButton(
                  label: "Retour à l'accueil",
                  onPressed: () {
                    submitOrder('user_id_example', orderDetails, context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
