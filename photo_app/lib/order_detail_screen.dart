import 'package:Picon/models/order.dart';
import 'package:Picon/models/order_item.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/safe_photo_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'COMPLETED':
        return {'text': 'Terminée', 'color': Colors.green.shade700, 'icon': Icons.check_circle};
      case 'PROCESSING':
        return {'text': 'En cours', 'color': AppColors.primary, 'icon': Icons.sync};
      case 'CANCELLED':
        return {'text': 'Annulée', 'color': Colors.red.shade700, 'icon': Icons.cancel};
      case 'PENDING':
      default:
        return {'text': 'En attente', 'color': Colors.orange.shade700, 'icon': Icons.hourglass_top};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSummaryCard(statusInfo),
          const SizedBox(height: 24),
          Text(
            'Articles de la commande',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...order.orderItems.map((item) => _buildOrderItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> statusInfo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CMD-${order.id}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(statusInfo['icon'], color: statusInfo['color'], size: 18),
                  label: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold)),
                  backgroundColor: statusInfo['color'].withOpacity(0.1),
                  side: BorderSide(color: statusInfo['color'].withOpacity(0.2)),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Date', DateFormat('dd MMMM yyyy, HH:mm').format(order.createdAt)),
            _buildSummaryRow('Montant Total', '${order.totalAmount.toStringAsFixed(0)} FCFA'),
            _buildSummaryRow('Paiement', order.paymentMethod),
            _buildSummaryRow('Type de livraison', order.deliveryType),
            if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
              _buildSummaryRow('Adresse', order.deliveryAddress!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15))),
          const SizedBox(width: 16),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(top: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SafePhotoThumbnail(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Format: ${item.photoSize}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Quantité: ${item.quantity}'),
                  const SizedBox(height: 4),
                  Text(
                    'Sous-total: ${(item.pricePerUnit * item.quantity).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
