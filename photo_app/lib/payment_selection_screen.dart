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
  String? _selected;
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
                  child: RepaintBoundary(
                    child: PaymentRing(
                      method: _pending!,
                      onComplete: () => _complete(_pending!),
                    ),
                  ),
                )
              : Column(
                  key: const ValueKey('methods'),
                  children: [
                    const _CheckoutSteps(step: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _CheckoutStage(articles: _articleCount),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: _methods.length,
                        itemBuilder: (context, index) {
                          final method = _methods[index];
                          final name =
                              method['name'] ?? 'Mode de paiement inconnu';
                          final logo = method['logo'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Reveal(
                              index: index,
                              child: TapScale(
                                onTap: () => setState(() => _selected = name),
                                child: AnimatedContainer(
                                  duration: Duration(
                                      milliseconds:
                                          reduceMotion(context) ? 1 : 220),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                        alpha: _selected == name ? 0.16 : 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selected == name
                                          ? AppColors.accent
                                          : Colors.white
                                              .withValues(alpha: 0.14),
                                      width: _selected == name ? 1.6 : 1,
                                    ),
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
                                                ? const Icon(Icons.error,
                                                    size: 28)
                                                : Image.asset(
                                                    logo,
                                                    fit: BoxFit.contain,
                                                    cacheWidth: 180,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const Icon(Icons.error),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            Text(
                                              _selected == name
                                                  ? 'Mode de paiement sélectionné'
                                                  : 'Cliquez pour choisir ce mode de paiement',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _selected == name
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked,
                                        color: _selected == name
                                            ? AppColors.accent
                                            : Colors.white54,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 0, 16, 16 + MediaQuery.paddingOf(context).bottom),
                      child: PiconButton(
                        label: _selected == null
                            ? 'Choisissez un moyen'
                            : 'Payer maintenant',
                        icon: Icons.lock_outline_rounded,
                        onPressed: _selected == null
                            ? null
                            : () => setState(() => _pending = _selected),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  int get _articleCount => widget.orderDetails.values
      .fold<int>(0, (sum, d) => sum + ((d['quantity'] as num?)?.toInt() ?? 1));
}

/// Étapes du paiement : Panier → Paiement → Confirmation.
class _CheckoutSteps extends StatelessWidget {
  final int step;
  const _CheckoutSteps({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Panier', 'Paiement', 'Confirmation'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: i <= step ? AppColors.accent : Colors.white24,
                ),
              ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        i <= step ? AppColors.accent : Colors.white12,
                    child: i < step
                        ? const Icon(Icons.check_rounded,
                            size: 15, color: Colors.white)
                        : Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: i <= step ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scène de paiement : résumé de la commande avant le choix du moyen.
class _CheckoutStage extends StatelessWidget {
  final int articles;
  const _CheckoutStage({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0B3FA8)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Votre commande PICON',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  articles <= 1 ? '$articles tirage' : '$articles tirages',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 4),
              Text('Sécurisé',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
