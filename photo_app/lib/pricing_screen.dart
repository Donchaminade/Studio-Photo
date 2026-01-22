import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/api_service.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  // Fallback data in case the API call fails
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
    _pricesFuture = ApiService.getPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Prix des Tirages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _pricesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If error or no data, use fallback data
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  // Optional: Log the error for debugging
                  // if (snapshot.hasError) { print(snapshot.error); }
                  return _buildGridView(PricingScreen.fallbackPrintPrices, isOffline: true);
                }

                // If data is successfully fetched, use it
                final apiPrices = snapshot.data!;
                // The API is assumed to return the final prices. The division rule was for the fallback data.
                return _buildGridView(apiPrices);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> prices, {bool isOffline = false}) {
    final currencyFormatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Column(
      children: [
        if (isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Impossible de charger les tarifs en ligne. Affichage des tarifs hors ligne.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: prices.length,
            itemBuilder: (context, index) {
              final item = prices[index];
              return _PriceTile(
                dimension: item['dimension'],
                price: currencyFormatter.format(item['price']),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String dimension;
  final String price;

  const _PriceTile({required this.dimension, required this.price});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 1.0), // Blue primary fine border
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dimension,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
