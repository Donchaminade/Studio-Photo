import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/colors.dart';

// Fonction pour soumettre la commande via l'API
Future<void> submitOrder(
    String userId,
    Map<String, Map<String, dynamic>> orderDetails,
    BuildContext context) async {
  // L'URL de votre API PHP
  const String apiUrl = 'http://10.0.2.2/studio/submit_order.php';

  // Convertir les détails de la commande en format JSON
  String orderDetailsJson = jsonEncode(orderDetails);

  // Préparer les données à envoyer
  Map<String, String> headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  // Créer le corps de la requête
  Map<String, String> body = {
    'user_id': userId,
    'order_details': orderDetailsJson,
  };

  try {
    // Envoyer la requête POST
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    // Vérifier la réponse
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande enregistrée avec succès')),
        );
      } else {
        // Afficher le message d'erreur du serveur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${responseData['message']}')),
        );
      }
    } else {
      // Erreur de connexion au serveur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: impossible de contacter le serveur')),
      );
    }
  } catch (error) {
    // Afficher une erreur si l'envoi échoue
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
    Key? key,
    required this.orderDetails,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de la commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.accent, size: 100),
              const SizedBox(height: 30),
              const Text(
                'Commande confirmée avec succès !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Mode de paiement : $paymentMethod',
                style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Remplacer 'user_id_example' par l'ID de l'utilisateur réel.
                  submitOrder('user_id_example', orderDetails, context);

                  // Retourner à l'écran d'accueil après l'enregistrement
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
