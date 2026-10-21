import 'dart:ui';
import 'package:Picon/api_service.dart';
import 'package:Picon/confirmation_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/utils/image_helper.dart';
import 'package:Picon/utils/mobile_operator_utils.dart';
import 'package:Picon/utils/studio_print_advice.dart';
import 'package:Picon/widgets/music_wave_loader.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final double totalAmount;
  final bool isExpress;
  final String? customerFirstname;
  final String? customerLastname;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerCountry;
  final String? deliveryAddress;

  const PaymentSelectionScreen({
    super.key,
    required this.orderDetails,
    required this.totalAmount,
    required this.isExpress,
    this.customerFirstname,
    this.customerLastname,
    this.customerEmail,
    this.customerPhone,
    this.customerCountry,
    this.deliveryAddress,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  static const String _mixxName = 'Mixx by Yas';
  static const String _floozName = 'Flooz / Moov Money';

  String? _selectedMethodName;
  Map<String, double>? _prices;
  bool _isLoadingPrices = true;
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final dimensions = await ApiService.fetchDimensions();
      if (mounted) {
        setState(() {
          _prices = {for (var dim in dimensions) dim.dimension: dim.price};
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        await showAppError(context, e);
        setState(() {
          _isLoadingPrices = false;
        });
      }
    }
  }

  Future<bool> _showPaymentInstructionsDialog() async {
    const highlight = TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.deepOrange,
    );

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Avant de payer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Après le paiement USSD, revenez dans l\'application pour confirmer :',
                    style: TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  _PaymentInstructionStep(
                    number: 1,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(height: 1.35),
                        children: [
                          const TextSpan(text: 'Faites une '),
                          TextSpan(text: 'capture d\'écran', style: highlight),
                          const TextSpan(text: ' de votre paiement'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentInstructionStep(
                    number: 2,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(height: 1.35),
                        children: [
                          const TextSpan(text: 'Chargez la '),
                          TextSpan(text: 'capture', style: highlight),
                          const TextSpan(text: ' pour confirmer'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentInstructionStep(
                    number: 3,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(height: 1.35),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK, passer au paiement'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(child: MusicWaveLoader()),
        ),
      ),
    );
  }

  PaymentOperatorMismatch? _paymentMismatch() {
    return MobileOperatorUtils.checkPaymentMatch(
      phone: widget.customerPhone,
      paymentMethod: _selectedMethodName ?? '',
      country: widget.customerCountry ?? 'TG',
    );
  }

  Future<bool> _showOperatorMismatchDialog(PaymentOperatorMismatch mismatch) async {
    final detected = MobileOperatorUtils.operatorLabel(mismatch.detected);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(child: Text('Numéro et paiement')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mismatch.message),
                const SizedBox(height: 12),
                Text(
                  'Numéro détecté : $detected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  mismatch.suggestedAction,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Modifier'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continuer quand même'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onPaymentMethodSelected(String name) {
    setState(() => _selectedMethodName = name);
    final mismatch = MobileOperatorUtils.checkPaymentMatch(
      phone: widget.customerPhone,
      paymentMethod: name,
      country: widget.customerCountry ?? 'TG',
    );
    if (mismatch != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mismatch.message),
          backgroundColor: const Color(0xFFE65100),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _onConfirmPressed() async {
    if (_selectedMethodName == null || _prices == null || _isSubmittingOrder) {
      return;
    }

    final mismatch = _paymentMismatch();
    if (mismatch != null) {
      final force = await _showOperatorMismatchDialog(mismatch);
      if (!force || !mounted) return;
    }

    final proceed = await _showPaymentInstructionsDialog();
    if (!proceed || !mounted) return;

    await _processPayment();
  }

  Future<void> _processPayment() async {
    if (_selectedMethodName == null || _prices == null || _isSubmittingOrder) {
      return;
    }

    setState(() => _isSubmittingOrder = true);
    _showLoadingDialog();

    try {
      final formatNames = _prices!.keys.toList();
      final items = <Map<String, dynamic>>[];

      for (final entry in widget.orderDetails.entries) {
        final details = entry.value;
        final chosenSize = details['size'] as String;
        final imageSize = await getImageDimensions(entry.key);
        final advice = buildStudioPrintAdvice(
          imageSize,
          chosenSize,
          formatNames,
        );

        items.add({
          'imageUrl': entry.key,
          'size': chosenSize,
          'quantity': details['quantity'],
          'price': _prices![chosenSize],
          'withFrame': details['withFrame'] == true,
          if (details['withFrame'] == true) 'frameId': details['frameId'],
          ...advice.toOrderItemFields(),
        });
      }

      if (ApiService.userId == null) {
        throw Exception('Veuillez vous reconnecter pour continuer le paiement.');
      }

      final createdOrder = await ApiService.createOrder({
        'isExpress': widget.isExpress,
        'paymentMethod': _selectedMethodName!,
        'items': items,
        'deliveryAddress': widget.deliveryAddress,
      });

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              orderDetails: widget.orderDetails,
              paymentMethod: _selectedMethodName!,
              totalAmount: widget.totalAmount,
              orderId: createdOrder.id,
              launchUssdOnOpen: true,
              isExpress: widget.isExpress,
              paymentPhone: widget.customerPhone,
              customerCountry: widget.customerCountry ?? 'TG',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        await showAppError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedMethodName != null && !_isSubmittingOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation finale'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: _isLoadingPrices
          ? const PiconSkeletonList(count: 3)
          : Stack(
              children: [
                GeometricBackground(),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total à payer',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${widget.totalAmount.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              title: 'Informations de livraison',
                              icon: Icons.local_shipping_outlined,
                              children: [
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'Destinataire',
                                  [widget.customerFirstname, widget.customerLastname]
                                          .where((v) => v != null && '$v'.trim().isNotEmpty && '$v' != 'null')
                                          .join(' ')
                                          .ifEmpty('Non renseigné'),
                                ),
                                _buildInfoRow(
                                  Icons.phone_outlined,
                                  'Mobile Money',
                                  _formatPaymentPhoneLine(),
                                ),
                                _buildInfoRow(
                                  Icons.map_outlined,
                                  'Adresse de livraison',
                                  widget.deliveryAddress ?? 'Non spécifiée',
                                ),
                                _buildInfoRow(
                                  Icons.speed_outlined,
                                  'Mode de retrait',
                                  widget.isExpress ? 'Express (Prioritaire)' : 'Standard',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildPaymentMethodSelector(),
                          ],
                        ),
                      ),
                    ),
                    _buildConfirmButton(canConfirm),
                  ],
                ),
              ],
            ),
    );
  }

  String _formatPaymentPhoneLine() {
    final phone = widget.customerPhone ?? 'Non spécifié';
    if (phone == 'Non spécifié') return phone;
    final op = MobileOperatorUtils.detectOperator(
      phone,
      country: widget.customerCountry ?? 'TG',
    );
    if (op == MobileOperator.unknown) return phone;
    return '$phone (${MobileOperatorUtils.operatorLabel(op)})';
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choisissez votre moyen de paiement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sélectionnez Yas ou Flooz pour continuer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildMethodButton(
            name: _mixxName,
            logo: 'assets/logos/mixbyyass.jpg',
            label: 'Yas (Mixx)',
          ),
          const SizedBox(height: 12),
          _buildMethodButton(
            name: _floozName,
            logo: 'assets/logos/flooz.webp',
            label: 'Flooz / Moov',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required String name,
    required String logo,
    required String label,
  }) {
    final selected = _selectedMethodName == name;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onPaymentMethodSelected(name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(logo, width: 48, height: 36, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool canConfirm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.textOnPrimary,
          backgroundColor: canConfirm ? AppColors.primary : Colors.grey,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor: Colors.grey.shade400,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: canConfirm ? _onConfirmPressed : null,
        child: Text(
          _isSubmittingOrder
              ? 'Création de la commande...'
              : canConfirm
                  ? 'Confirmer et payer ${widget.totalAmount.toStringAsFixed(0)} FCFA'
                  : 'Choisissez Yas ou Flooz pour continuer',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Colors.white24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructionStep extends StatelessWidget {
  final int number;
  final Widget child;

  const _PaymentInstructionStep({
    required this.number,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
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
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

extension _EmptyText on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
