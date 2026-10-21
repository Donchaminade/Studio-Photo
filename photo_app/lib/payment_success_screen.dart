import 'dart:ui';

import 'package:Picon/api_service.dart';
import 'package:Picon/history_screen.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/models/contact_info.dart';
import 'package:Picon/receipt_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
  });

  /// Navigue vers l'accueil puis vers l'historique pour éviter le bug de déconnexion.
  void _goToHistory(BuildContext context) {
    ApiService.clearPendingPayment();

    final navigator = Navigator.of(context);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: ApiService.userName ?? "Utilisateur",
          userLastName: ApiService.userLastName ?? "",
          userEmail: ApiService.userEmail ?? "",
          userId: ApiService.userId ?? 0,
        ),
      ),
      (route) => false,
    );

    navigator.push(
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _goToHome(BuildContext context) {
    ApiService.clearPendingPayment();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: {
        'userName': ApiService.userName,
        'userLastName': ApiService.userLastName,
        'userEmail': ApiService.userEmail,
        'userId': ApiService.userId,
      },
    );
  }

  Future<void> _sendWhatsAppSummary(BuildContext context) async {
    try {
      ContactInfo contact;
      try {
        contact = await ApiService.fetchContactInfo();
      } catch (_) {
        contact = ApiService.defaultContactInfo;
      }
      // On garde uniquement les chiffres pour WhatsApp (incluant le code pays)
      final raw = (contact.whatsappNumber?.trim().isNotEmpty == true)
          ? contact.whatsappNumber!
          : contact.phoneNumber;
      final phone = raw.replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty) return;

      final buffer = StringBuffer();
      buffer.writeln("🎉 *Nouvelle Commande Reçue * 🎉");
      buffer.writeln("---------------------------------");
      buffer.writeln("*Commande ID:* $orderId");
      buffer.writeln(
          "*Client:* ${ApiService.userName} ${ApiService.userLastName}");
      buffer.writeln(
          "*Contact:* ${ApiService.userPhone ?? ApiService.userEmail}");
      buffer.writeln(
          "*Mode de paiement:* ${ApiService.pendingPaymentMethod ?? 'Mix by Yass'}");
      buffer.writeln("---------------------------------");
      buffer.writeln("*Détails de la commande:*");

      if (ApiService.pendingOrderDetails != null) {
        ApiService.pendingOrderDetails!.forEach((imageUrl, details) {
          final fileName = imageUrl.split('/').last;
          buffer.writeln("- Photo: $fileName");
          buffer.writeln("  Taille: ${details['size']}");
          buffer.writeln("  Quantité: ${details['quantity']}");
        });
      }

      buffer.writeln("---------------------------------");
      buffer.writeln("Merci de traiter cette commande.");

      final message = Uri.encodeComponent(buffer.toString());

      final whatsappAppUrl =
          Uri.parse("whatsapp://send?phone=$phone&text=$message");
      final whatsappWebUrl =
          Uri.parse("https://api.whatsapp.com/send?phone=$phone&text=$message");

      if (await canLaunchUrl(whatsappAppUrl)) {
        await launchUrl(whatsappAppUrl, mode: LaunchMode.externalApplication);
      } else {
        // En Android 11+, canLaunchUrl peut échouer même si WhatsApp est installé (sans <queries>). On tente alors le fallback web.
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur WhatsApp : $e"),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = ApiService.pendingOrderDetails != null &&
        ApiService.pendingPrices != null &&
        ApiService.pendingPaymentMethod != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement confirmé'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: false, // Pas de retour arrière possible
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: GeometricBackground()),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Héro : Icône de succès avec glow
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ).animate().scale(
                                  duration: 800.ms, curve: Curves.easeOutBack),
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF388E3C),
                                      Color(0xFF4CAF50),
                                      Color(0xFF81C784)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 44),
                              ).animate().scale(
                                  duration: 600.ms,
                                  delay: 200.ms,
                                  curve: Curves.elasticOut),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Text(
                              'Paiement Réussi !',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Commande #$orderId',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 16),
                          const Text(
                            "Votre commande est enregistrée et est actuellement en cours de préparation.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 32),

                          // Bouton "Voir le reçu" (Premium Soft)
                          if (hasPending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.receipt_long_rounded,
                                      color: AppColors.primary),
                                  label: const Text(
                                    'Afficher mon reçu',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReceiptScreen(
                                          orderDetails:
                                              ApiService.pendingOrderDetails!,
                                          paymentMethod:
                                              ApiService.pendingPaymentMethod!,
                                          orderId: orderId,
                                          prices: ApiService.pendingPrices!,
                                          userName:
                                              ApiService.userName ?? "Client",
                                          userPhone: ApiService.userPhone ?? "",
                                        ),
                                      ),
                                    ); // Supprimé : .then((_) => _goToHistory(context))
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                          color: AppColors.primary
                                              .withOpacity(0.2),
                                          width: 1.5),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 400.ms),
                              ),
                            ),

                          // Bouton principal (Call to Action : WhatsApp + Historique)
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  _sendWhatsAppSummary(context);
                                  await Future.delayed(
                                      const Duration(milliseconds: 300));
                                  if (context.mounted) _goToHistory(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: const Text(
                                          'Poursuivre & Voir mes commandes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                          ),

                          const SizedBox(height: 12),

                          // Bouton Retour Accueil (Minimaliste)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => _goToHome(context),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Retour à l'accueil",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ).animate().fadeIn(delay: 600.ms),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
