import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'history_screen.dart';
import 'api_service.dart';
import 'payment_success_screen.dart';
import 'services/ussd_launch_service.dart';
import 'utils/colors.dart';
import 'utils/geometric_background.dart';
import 'utils/google_play_tester.dart';
import 'utils/mobile_operator_utils.dart';
import 'utils/phone_payment_permissions.dart';
import 'widgets/app_error_feedback.dart';

class ConfirmationScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final String paymentMethod;
  final double totalAmount;
  final int orderId;
  final bool launchUssdOnOpen;
  final bool isExpress;
  final String? paymentPhone;
  final String customerCountry;

  const ConfirmationScreen({
    super.key,
    required this.orderDetails,
    required this.paymentMethod,
    required this.totalAmount,
    required this.orderId,
    this.launchUssdOnOpen = false,
    this.isExpress = false,
    this.paymentPhone,
    this.customerCountry = 'TG',
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _isConfirmingPayment = false;
  bool _isUploadingProof = false;
  bool _autoUssdLaunched = false;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  File? _proofImage;

  String get _amount => widget.totalAmount.toStringAsFixed(0);

  @override
  void initState() {
    super.initState();
    // Pas d'USSD auto pour le testeur Google Play (parcours sans paiement réel).
    if (widget.launchUssdOnOpen && !isGooglePlayTester()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_autoUssdLaunched) {
          _autoUssdLaunched = true;
          _launchUssd();
        }
      });
    }
  }

  /// Termine le parcours commande pour le testeur Play Store uniquement.
  /// Tente d'abord [ApiService.confirmOrderPayment] sans preuve USSD ;
  /// en échec, simule la réussite côté UI uniquement.
  Future<void> _continueGooglePlayTest() async {
    if (!isGooglePlayTester() || _isConfirmingPayment) return;

    setState(() => _isConfirmingPayment = true);
    var backendConfirmed = false;

    try {
      await ApiService.confirmOrderPayment(
        widget.orderId,
        paymentReference: 'GOOGLE_PLAY_TEST',
        paymentProofType: 'GOOGLE_PLAY_TEST',
        paymentProofText:
            'Parcours test Google Play — sans USSD réel ($kGooglePlayTesterEmail)',
      );
      backendConfirmed = true;
    } catch (_) {
      // Endpoints inchangés : si confirm échoue sans preuve, on continue en UI.
    }

    if (!mounted) return;

    ApiService.clearPendingPayment();
    ApiService.shouldClearCart = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          backendConfirmed
              ? 'Mode test Google : confirmation enregistrée (sans USSD réel).'
              : 'Mode test Google : parcours simulé côté app (sans USSD réel). '
                  'La commande peut rester en attente côté serveur.',
        ),
        backgroundColor: backendConfirmed ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 6),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          orderId: widget.orderId.toString(),
        ),
      ),
      (route) => false,
    );

    if (mounted) {
      setState(() => _isConfirmingPayment = false);
    }
  }

  Future<void> _launchUssd() async {

    final phone = widget.paymentPhone?.trim().isNotEmpty == true
        ? widget.paymentPhone!
        : (ApiService.userPhone ?? '');
    final detected = MobileOperatorUtils.detectOperator(
      phone,
      country: widget.customerCountry,
    );
    final operatorHint = detected != MobileOperator.unknown
        ? MobileOperatorUtils.operatorHintForUssd(detected)
        : MobileOperatorUtils.operatorHintFromPaymentMethod(
            widget.paymentMethod,
          );

    // Le code USSD marchand est résolu côté serveur (jamais embarqué dans l'app).
    String ussdCode;
    try {
      ussdCode = await ApiService.fetchOrderUssdCode(widget.orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de récupérer le code de paiement. Vérifiez votre connexion et réessayez.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!mounted) return;

    final result = await UssdLaunchService.launchPaymentUssd(
      ussdCode: ussdCode,
      paymentPhone: phone,
      operatorHint: operatorHint,
    );

    if (!mounted) return;

    if (result.permissionDenied && !result.success) {
      final retry = await PhonePaymentPermissions.showDeniedDialog(context);
      if (retry && mounted) {
        await _launchUssd();
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? (result.permissionDenied
                ? const Color(0xFFE65100)
                : const Color(0xFF2E7D32))
            : Colors.red,
        duration: Duration(seconds: result.permissionDenied ? 6 : 4),
        action: result.permissionDenied && !result.success
            ? SnackBarAction(
                label: 'Paramètres',
                textColor: Colors.white,
                onPressed: PhonePaymentPermissions.openSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _notifyPaymentDone() async {
    if (_isConfirmingPayment) return;

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La capture d\'écran est obligatoire pour confirmer le paiement.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isConfirmingPayment = true);
    try {
      setState(() => _isUploadingProof = true);
      final paymentProofImageUrl =
          await ApiService.uploadPaymentProof(widget.orderId, _proofImage!);

      String? paymentProofText;
      if (_messageController.text.trim().isNotEmpty) {
        paymentProofText = _messageController.text.trim();
      }

      await ApiService.confirmOrderPayment(
        widget.orderId,
        paymentReference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        paymentProofType: 'SCREENSHOT',
        paymentProofText: paymentProofText,
        paymentProofImageUrl: paymentProofImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirmation reçue. Paiement en cours de validation par nos équipes.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Redirige vers WhatsApp avec le récapitulatif complet de la commande.
      await _sendWhatsAppRecap();
      if (!mounted) return;

      _goToHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de confirmer le paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProof = false;
          _isConfirmingPayment = false;
        });
      }
    }
  }

  /// Construit le récapitulatif de la commande et ouvre WhatsApp (redirection)
  /// avec un message pré-rempli destiné au studio.
  Future<void> _sendWhatsAppRecap() async {
    // Numéro WhatsApp par défaut de Picon si rien n'est configuré côté admin.
    const defaultWhatsapp = '+228 98 52 62 26';

    try {
      String rawWhatsapp = defaultWhatsapp;
      try {
        final contact = await ApiService.fetchContactInfo();
        final configured = contact.whatsappNumber?.trim();
        if (configured != null && configured.isNotEmpty) {
          rawWhatsapp = configured;
        } else if (contact.phoneNumber.trim().isNotEmpty) {
          // Repli secondaire : numéro de téléphone du studio.
          rawWhatsapp = contact.phoneNumber;
        }
      } catch (_) {
        // En cas d'échec de récupération, on garde le numéro par défaut.
      }

      // Numéro WhatsApp du studio : on ne garde que les chiffres (code pays inclus).
      final studioPhone = rawWhatsapp.replaceAll(RegExp(r'\D'), '');

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final dateStr =
          '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}';

      final clientName =
          '${ApiService.userName ?? ''} ${ApiService.userLastName ?? ''}'.trim();
      final clientPhone = (widget.paymentPhone?.trim().isNotEmpty == true)
          ? widget.paymentPhone!.trim()
          : (ApiService.userPhone ?? ApiService.userEmail ?? 'Non renseigné');

      int totalQuantity = 0;

      final buffer = StringBuffer();
      buffer.writeln('🎉 *Nouvelle commande - Picon* 🎉');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('*Commande:* #${widget.orderId}');
      buffer.writeln('*Date:* $dateStr');
      buffer.writeln('*Client:* ${clientName.isEmpty ? 'Client' : clientName}');
      buffer.writeln('*Téléphone:* $clientPhone');
      buffer.writeln('*Type:* ${widget.isExpress ? 'Express (prioritaire)' : 'Standard'}');
      buffer.writeln('*Moyen de paiement:* ${widget.paymentMethod}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('*Détails de la commande:*');

      widget.orderDetails.forEach((imageUrl, details) {
        final size = details['size'] ?? '-';
        final quantity = (details['quantity'] as num?)?.toInt() ?? 1;
        totalQuantity += quantity;
        final withFrame = details['withFrame'] == true;
        final frameName = details['frameName'];
        final frameInfo = withFrame
            ? ' + cadre${frameName != null ? ' ($frameName)' : ''}'
            : '';
        buffer.writeln('• $size x$quantity$frameInfo');
      });

      buffer.writeln('━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('*Quantité totale:* $totalQuantity photo(s)');
      buffer.writeln('*Coût total:* ${widget.totalAmount.toStringAsFixed(0)} FCFA');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('Merci de traiter cette commande. 🙏');

      final message = Uri.encodeComponent(buffer.toString());

      final whatsappAppUrl =
          Uri.parse('whatsapp://send?phone=$studioPhone&text=$message');
      final whatsappWebUrl =
          Uri.parse('https://wa.me/$studioPhone?text=$message');

      if (await canLaunchUrl(whatsappAppUrl)) {
        await launchUrl(whatsappAppUrl, mode: LaunchMode.externalApplication);
      } else {
        // Android 11+ peut bloquer canLaunchUrl sans <queries> : fallback web.
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        await showAppError(context, e);
      }
    }
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _proofImage = File(picked.path));
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const highlight = TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finaliser le paiement'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const GeometricBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Commande enregistrée',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paiement via ${widget.paymentMethod} — $_amount FCFA',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
              if (widget.paymentPhone != null &&
                  widget.paymentPhone!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Ligne Mobile Money : ${widget.paymentPhone}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Une fenêtre USSD va s\'ouvrir sur cette ligne : confirmez le paiement marchand et saisissez votre code secret Mobile Money (comme sur 1xBet).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étapes après paiement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PaymentStepRow(
                      number: 1,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Validez le '),
                            TextSpan(text: 'pop-up USSD', style: highlight),
                            const TextSpan(
                              text: ' avec votre code Mobile Money, puis capturez l\'écran de confirmation',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentStepRow(
                      number: 2,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Chargez la '),
                            TextSpan(text: 'capture', style: highlight),
                            const TextSpan(text: ' ci-dessous'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentStepRow(
                      number: 3,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Validez et '),
                            TextSpan(text: 'attendez', style: highlight),
                            const TextSpan(text: ' notre confirmation'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _launchUssd,
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Relancer le paiement USSD'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (isGooglePlayTester()) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: const Text(
                    'Compte testeur Google Play détecté. '
                    'Vous pouvez terminer la commande sans paiement USSD réel.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE65100),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _isConfirmingPayment ? null : _continueGooglePlayTest,
                  icon: _isConfirmingPayment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.science_outlined),
                  label: const Text('Continuer (mode test Google)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    side: const BorderSide(color: Color(0xFFE65100)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Capture d\'écran *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Obligatoire — faites une '),
                    TextSpan(text: 'capture', style: highlight),
                    const TextSpan(text: ' après le paiement USSD'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickProofImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _proofImage == null
                      ? 'Choisir la capture'
                      : 'Changer la capture',
                ),
              ),
              if (_proofImage != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _proofImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Référence transaction (optionnel)',
                  hintText: 'Ex: TX123456789',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Coller un message (optionnel)',
                  hintText: 'SMS ou message reçu après paiement',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isConfirmingPayment ? null : _notifyPaymentDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isConfirmingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isUploadingProof
                      ? 'Envoi de la capture...'
                      : 'J\'ai effectué le paiement',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goToHistory,
                child: const Text('Retour à l\'accueil'),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToHistory() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
      (route) => route.isFirst,
    );
  }
}

class _PaymentStepRow extends StatelessWidget {
  final int number;
  final Widget child;

  const _PaymentStepRow({
    required this.number,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.primary,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}
