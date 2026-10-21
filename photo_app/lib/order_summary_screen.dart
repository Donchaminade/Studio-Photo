import 'dart:ui';
import 'package:Picon/api_service.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';

import 'payment_customer_info_screen.dart';
import 'utils/colors.dart';
import 'utils/geometric_background.dart';
import 'utils/order_line_pricing.dart';
import 'widgets/auth_network_image.dart';
import 'widgets/safe_photo_thumbnail.dart';
import 'widgets/app_error_feedback.dart';

class OrderSummaryScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final bool isExpress;

  const OrderSummaryScreen({
    super.key,
    required this.orderDetails,
    required this.isExpress,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  late Map<String, Map<String, dynamic>> _editableOrderDetails;
  double _subtotal = 0;
  double _deliveryFee = 0;
  double _totalPrice = 0;

  Map<String, double>? _prices;
  Map<String, double?>? _framePrices;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _editableOrderDetails = Map<String, Map<String, dynamic>>.from(
      widget.orderDetails.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
    );
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final dimensions = await ApiService.fetchDimensions();
      if (mounted) {
        setState(() {
          _prices = {for (var dim in dimensions) dim.dimension: dim.price};
          _framePrices = {
            for (var dim in dimensions) dim.dimension: dim.framePrice
          };
          _calculatePrices();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        await showAppError(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculatePrices() {
    if (_prices == null) return;

    double newSubtotal = 0;
    int photoCount = _editableOrderDetails.keys.length;

    _editableOrderDetails.forEach((key, details) {
      newSubtotal += OrderLinePricing.lineTotal(
        details,
        _prices!,
        _framePrices ?? const {},
      );
    });

    double newDeliveryFee = 0;
    if (widget.isExpress) {
      if (photoCount <= 10) {
        newDeliveryFee = 1500;
      }
    }

    setState(() {
      _subtotal = newSubtotal;
      _deliveryFee = newDeliveryFee;
      _totalPrice = _subtotal + _deliveryFee;
    });
  }

  void _updateQuantity(String imageUrl, int change) {
    setState(() {
      final currentQuantity =
          _editableOrderDetails[imageUrl]!['quantity'] as int;
      if (currentQuantity + change > 0) {
        _editableOrderDetails[imageUrl]!['quantity'] = currentQuantity + change;
        _calculatePrices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GeometricBackground(),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 70), // Leave space for the custom appbar
            child: _isLoading
                ? const PiconSkeletonList(count: 4)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: _editableOrderDetails.length,
                          itemBuilder: (context, index) {
                            final entry = _editableOrderDetails.entries.elementAt(index);
                            final imageUrl = entry.key;
                            final details = entry.value;
                            return _buildCartItem(imageUrl, details);
                          },
                        ),
                      ),
                      _buildPriceSummary(),
                    ],
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFixedTopBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedTopBar(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(16.0, MediaQuery.of(context).padding.top + 4, 16.0, 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Image.asset(
                        'assets/images/pro.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              // Dummy icon to balance the back button on the right (keeps logo centered)
              const IconButton(
                onPressed: null,
                icon: Icon(Icons.notifications_none, color: Colors.transparent, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(String imageUrl, Map<String, dynamic> details) {
    final size = details['size'] as String? ?? '';
    final printPrice = _prices?[size] ?? 0;
    final withFrame = details['withFrame'] == true;
    final framePrice = withFrame ? (_framePrices?[size] ?? 0) : 0;
    final unitTotal = OrderLinePricing.unitTotal(
      printPrice: printPrice,
      framePrice: _framePrices?[size],
      withFrame: withFrame,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SafePhotoThumbnail(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Format ${details['size']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unitTotal.toStringAsFixed(0)} FCFA / u.',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      if (withFrame) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (details['frameImageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AuthNetworkImage(
                                  details['frameImageUrl'] as String,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (details['frameImageUrl'] != null)
                              const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cadre: ${details['frameName'] ?? 'Oui'} (+${framePrice.toStringAsFixed(0)} F)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () => _updateQuantity(imageUrl, -1),
                        color: AppColors.textPrimary,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      Text('${details['quantity']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => _updateQuantity(imageUrl, 1),
                        color: AppColors.primary,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSummaryRow('Sous-total', '${_subtotal.toStringAsFixed(0)} FCFA'),
            _buildSummaryRow('Livraison', widget.isExpress ? 'Xpress' : 'Standard'),
            if (widget.isExpress)
              _buildSummaryRow(
                  'Frais de livraison', '+ ${_deliveryFee.toStringAsFixed(0)} FCFA'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            _buildSummaryRow(
              'TOTAL À PAYER',
              '${_totalPrice.toStringAsFixed(0)} FCFA',
              isTotal: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentCustomerInfoScreen(
                      orderDetails: _editableOrderDetails,
                      totalAmount: _totalPrice,
                      isExpress: widget.isExpress,
                    ),
                  ),
                );
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'CONFIRMER ET CHOISIR LE PAIEMENT',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(title,
                style: TextStyle(
                    fontSize: isTotal ? 16 : 15,
                    fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
                    color: isTotal ? AppColors.textPrimary : AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(value,
                  style: TextStyle(
                      fontSize: isTotal ? 20 : 16,
                      fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
                      color: isTotal ? AppColors.primary : AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
