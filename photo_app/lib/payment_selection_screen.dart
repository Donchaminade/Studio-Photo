import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_app/confirmation_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/payment_ring.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> orderDetails;

  const PaymentSelectionScreen({super.key, required this.orderDetails});

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  static const _methods = [
    {'name': 'MasterCard / VISA', 'logo': 'assets/logos/mastercard.png'},
    {'name': 'Flooz', 'logo': 'assets/logos/flooz.webp'},
    {'name': 'Mix by Yass', 'logo': 'assets/logos/mixbyyass.jpg'},
  ];

  String? _pending;
  bool _navigated = false;

  void _complete(String method) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          orderDetails: widget.orderDetails,
          paymentMethod: method,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _navigated = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final paying = _pending != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navyDeep,
        appBar: piconBar('Choisir le mode de paiement', dark: true),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: reduceMotion(context) ? 120 : 360),
          child: paying
              ? Center(
                  key: const ValueKey('ring'),
                  child: PaymentRing(
                    method: _pending!,
                    onComplete: () => _complete(_pending!),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('methods'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    final name = method['name'] ?? 'Mode de paiement inconnu';
                    final logo = method['logo'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Reveal(
                        index: index,
                        child: TapScale(
                          onTap: () => setState(() => _pending = name),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ColoredBox(
                                    color: Colors.white,
                                    child: SizedBox(
                                      width: 56,
                                      height: 40,
                                      child: logo.isEmpty
                                          ? const Icon(Icons.error, size: 28)
                                          : Image.asset(
                                              logo,
                                              fit: BoxFit.contain,
                                              cacheWidth: 180,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.error),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Cliquez pour choisir ce mode de paiement',
                                        style: TextStyle(fontSize: 13, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
