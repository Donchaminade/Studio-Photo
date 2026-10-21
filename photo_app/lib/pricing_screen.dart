import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:Picon/api_service.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  static final List<Map<String, dynamic>> fallbackPrintPrices = [
    {'dimension': '9x13 cm', 'price': 75},
    {'dimension': '10x15 cm', 'price': 150},
    {'dimension': '13x18 cm', 'price': 125},
    {'dimension': '15x21 cm', 'price': 175},
    {'dimension': '20x25 cm', 'price': 375},
    {'dimension': '20x30 cm', 'price': 500},
    {'dimension': '24x30 cm', 'price': 750},
    {'dimension': '30x40 cm', 'price': 1250},
    {'dimension': '30x45 cm', 'price': 1500},
    {'dimension': '30x90 cm', 'price': 2000},
    {'dimension': '40x50 cm', 'price': 2500},
    {'dimension': '40x60 cm', 'price': 3250},
    {'dimension': '50x60 cm', 'price': 3750},
    {'dimension': '60x90 cm', 'price': 4500},
    {'dimension': '60x120 cm', 'price': 6250},
  ];

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  late Future<List<Map<String, dynamic>>> _pricesFuture;

  @override
  void initState() {
    super.initState();
    _pricesFuture = _loadPrices();
  }

  Future<List<Map<String, dynamic>>> _loadPrices() async {
    final dims = await ApiService.fetchDimensions();
    return [
      for (final dim in dims) {'dimension': dim.dimension, 'price': dim.price},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navyDeep,
        appBar: piconBar('Prix des Tirages', dark: true),
        body: SafeArea(
          top: false,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _pricesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError) {
                return AppInlineError(
                  error: snapshot.error!,
                  onRetry: () {
                    setState(() => _pricesFuture = _loadPrices());
                  },
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _OfferCarousel(prices: PricingScreen.fallbackPrintPrices, isOffline: true);
              }
              return _OfferCarousel(prices: snapshot.data!);
            },
          ),
        ),
      ),
    );
  }
}

class _OfferCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> prices;
  final bool isOffline;

  const _OfferCarousel({required this.prices, this.isOffline = false});

  @override
  State<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<_OfferCarousel> {
  final PageController _page = PageController(viewportFraction: 0.78);
  int _index = 0;
  final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (reduceMotion(context)) {
      _page.jumpToPage(index);
    } else {
      _page.animateToPage(index, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  String _priceLabel(dynamic raw) {
    final num value = raw is num ? raw : num.tryParse('$raw') ?? 0;
    return _currency.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.prices[_index];
    return Column(
      children: [
        if (widget.isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Impossible de charger les tarifs en ligne. Affichage des tarifs hors ligne.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choisissez un format',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _page,
            itemCount: widget.prices.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final item = widget.prices[index];
              final active = index == _index;
              final dimension = '${item['dimension']}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                child: TapScale(
                  onTap: () => setState(() => _index = index),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: reduceMotion(context) ? 1 : 220),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: active ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: active ? AppColors.accent : Colors.white24,
                        width: active ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Sélectionné',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          dimension,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _priceLabel(item['price']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Icon(
                          active ? Icons.check_circle : Icons.circle_outlined,
                          color: active ? AppColors.accent : Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Précédent',
                onPressed: _index == 0 ? null : () => _go(_index - 1),
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  '${selected['dimension']} · ${_priceLabel(selected['price'])}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Suivant',
                onPressed: _index == widget.prices.length - 1 ? null : () => _go(_index + 1),
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
