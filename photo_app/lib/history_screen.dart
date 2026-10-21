import 'dart:async';

import 'package:Picon/api_service.dart';
import 'package:Picon/confirmation_screen.dart';
import 'package:Picon/models/order.dart';
import 'package:Picon/models/order_item.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/auth_network_image.dart';
import 'package:Picon/widgets/safe_photo_thumbnail.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<void> _fetchDataFuture;
  List<Order> _allOrders = [];
  Map<int, Map<String, dynamic>> _ordersMeta = {};
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchAllHistory();
    // Rafraîchissement automatique toutes les 30 secondes
    _startAutoRefresh();
  }

  Timer? _autoRefreshTimer;

  /// Même rythme qu'avant (30 s), mais le minuteur est annulé à la fermeture
  /// de l'écran au lieu de rester en attente.
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _fetchAllHistory();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllHistory() async {
    try {
      final rawOrders = await ApiService.fetchMyOrdersRaw();
      final orders = rawOrders.map((json) => Order.fromJson(json)).toList();
      final metaMap = <int, Map<String, dynamic>>{};
      for (final raw in rawOrders) {
        final id = raw['id'];
        if (id is int) {
          metaMap[id] = raw;
        } else if (id is num) {
          metaMap[id.toInt()] = raw;
        }
      }
      setState(() {
        _allOrders = orders;
        _ordersMeta = metaMap;
      });
    } catch (e) {
      if (mounted) {
        await showAppError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Commandes'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Pas de bouton retour automatique
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.primary, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _fetchDataFuture = _fetchAllHistory();
            }),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Stack(
        children: [
          GeometricBackground(),
          FutureBuilder<void>(
            future: _fetchDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const PiconSkeletonList(count: 6);
              }

              final hiddenOrders = ApiService.hiddenOrders;

              final visibleOrders = _allOrders
                  .where((o) => !hiddenOrders.contains(o.id.toString()))
                  .toList();

              final filteredOrders = _selectedFilter == null
                  ? visibleOrders
                  : visibleOrders
                      .where((o) => _matchesFilter(_selectedFilter!, o))
                      .toList();

              return RefreshIndicator(
                onRefresh: _fetchAllHistory,
                color: AppColors.primary,
                child: Column(
                  children: [
                    _buildOrderStats(),
                    _buildOrderFilters(),
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? _buildEmptyState(_selectedFilter == null
                              ? 'Aucune commande'
                              : 'Aucune commande avec ce statut')
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(), // Ensures it's always scrollable for RefreshIndicator
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 0, 16.0, 24.0),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) =>
                                  _buildHistoryCard(filteredOrders[index]),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats() {
    final visibleOrders = _allOrders
        .where((o) => !ApiService.hiddenOrders.contains(o.id.toString()))
        .toList();

    final ongoing = visibleOrders
        .where((o) {
          final status = _effectiveStatus(o);
          return status == 'PENDING' ||
              status == 'PENDING_PAYMENT' ||
              status == 'PENDING_PAYMENT_REVIEW' ||
              status == 'PROCESSING';
        })
        .length;
    final completed =
        visibleOrders.where((o) => o.status == 'COMPLETED').length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _statItem('Total', visibleOrders.length.toString(),
              Icons.receipt_outlined, AppColors.primary),
          const SizedBox(width: 12),
          _statItem('Actives', ongoing.toString(), Icons.sync, Colors.orange),
          const SizedBox(width: 12),
          _statItem('Terminées', completed.toString(),
              Icons.check_circle_outline, Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Toutes'),
            const SizedBox(width: 8),
            _filterChip('PENDING', 'En attente'),
            const SizedBox(width: 8),
            _filterChip('PENDING_PAYMENT', 'En attente paiement'),
            const SizedBox(width: 8),
            _filterChip('PENDING_PAYMENT_REVIEW', 'En vérification'),
            const SizedBox(width: 8),
            _filterChip('PROCESSING', 'Payées'),
            const SizedBox(width: 8),
            _filterChip('COMPLETED', 'Terminées'),
            const SizedBox(width: 8),
            _filterChip('REFUND_PENDING', 'Remb. en cours'),
            const SizedBox(width: 8),
            _filterChip('REFUNDED', 'Remboursées'),
            const SizedBox(width: 8),
            _filterChip('CANCELLED', 'Annulées'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildHistoryCard(Order order) {
    final orderItems = order.orderItems;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primary),
          ),
          title: Text(
            'Commande #${order.id}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            order.createdAt != null
                ? DateFormat('dd MMM yyyy').format(order.createdAt!)
                : '—',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
              _statusMiniBadge(_effectiveStatus(order)),
            ],
          ),
          children: [
            const Divider(indent: 20, endIndent: 20, height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: const Text(
                          'Détails de la commande',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmSoftDeleteWarning(order),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Masquer la commande',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...orderItems.map((item) => _buildOrderItemRow(item)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _infoDetailRow(
                      Icons.payments_outlined,
                      'Paiement',
                      order.paymentMethod?.replaceAll('_', ' ') ??
                          'Non renseigné'),
                  const SizedBox(height: 8),
                  _infoDetailRow(
                      Icons.local_shipping_outlined,
                      'Livraison',
                      order.deliveryType?.replaceAll('_', ' ') ??
                          'Non renseigné'),
                  if (order.deliveryAddress != null &&
                      order.deliveryAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoDetailRow(Icons.location_on_outlined, 'Adresse',
                        order.deliveryAddress!),
                  ],
                  const SizedBox(height: 16),
                  _statusLargeView(_effectiveStatus(order)),
                  if (_shouldShowFinalizePaymentButton(order)) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _resumePayment(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.payment_outlined),
                        label: const Text('Finaliser le paiement'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showImagePreviewDialog(item.imageUrl),
            child: SafePhotoThumbnail(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format: ${item.photoSize}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Quantité: ${item.quantity}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${(item.pricePerUnit * item.quantity).toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(String imageSource) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: AuthNetworkImage(
                  imageSource,
                  fit: BoxFit.contain,
                  errorWidget: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger l\'aperçu.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text('$title: ',
            style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucune commande',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _statusMiniBadge(String status) {
    final info = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (info['color'] as Color).withOpacity(0.2)),
      ),
      child: Text(
        info['text'].toUpperCase(),
        style: TextStyle(
            color: info['color'],
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _statusLargeView(String status) {
    final info = _getStatusInfo(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (info['color'] as Color).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (info['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(info['icon'], color: info['color'], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut actuel',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  info['text'],
                  style: TextStyle(
                      color: info['color'],
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'CONFIRMED':
        return {
          'text': 'Terminée',
          'color': Colors.green.shade700,
          'icon': Icons.check_circle
        };
      case 'PROCESSING':
        return {
          'text': 'Payé',
          'color': AppColors.primary,
          'icon': Icons.payment
        };
      case 'PENDING_PAYMENT':
        return {
          'text': 'En attente de paiement',
          'color': Colors.orange.shade700,
          'icon': Icons.payments_outlined
        };
      case 'PENDING_PAYMENT_REVIEW':
        return {
          'text': 'En vérification',
          'color': Colors.deepOrange.shade700,
          'icon': Icons.verified_user_outlined
        };
      case 'REFUND_PENDING':
        return {
          'text': 'Remboursement en cours',
          'color': Colors.amber.shade800,
          'icon': Icons.hourglass_top
        };
      case 'REFUNDED':
        return {
          'text': 'Remboursée',
          'color': Colors.teal.shade700,
          'icon': Icons.undo
        };
      case 'PENDING':
        return {
          'text': 'En attente',
          'color': Colors.orange.shade700,
          'icon': Icons.hourglass_top
        };
      case 'CANCELLED':
        return {
          'text': 'Annulée',
          'color': Colors.red.shade700,
          'icon': Icons.cancel
        };
      default:
        return {
          'text': status,
          'color': Colors.grey.shade700,
          'icon': Icons.help_outline
        };
    }
  }

  bool _matchesFilter(String filter, Order order) {
    final status = _effectiveStatus(order);
    if (filter == 'PENDING_PAYMENT') {
      return status == 'PENDING_PAYMENT';
    }
    if (filter == 'PENDING_PAYMENT_REVIEW') {
      return status == 'PENDING_PAYMENT_REVIEW';
    }
    if (filter == 'REFUND_PENDING' || filter == 'REFUNDED') {
      return status == filter;
    }
    if (filter == 'CANCELLED') {
      return order.status.toUpperCase() == 'CANCELLED' && status != 'REFUNDED';
    }
    return status == filter;
  }

  String _effectiveStatus(Order order) {
    final meta = _ordersMeta[order.id] ?? const <String, dynamic>{};
    final paymentStatus =
        (meta['paymentStatus']?.toString().toUpperCase() ?? '').trim();
    final refundStatus =
        (meta['refundStatus']?.toString().toUpperCase() ?? '').trim();

    if (refundStatus == 'REFUNDED' || paymentStatus == 'REFUNDED') {
      return 'REFUNDED';
    }
    if (refundStatus == 'REFUND_PENDING') {
      return 'REFUND_PENDING';
    }

    final hasProof = (meta['paymentProofImageUrl']?.toString().trim().isNotEmpty ??
            false) ||
        (meta['paymentProofText']?.toString().trim().isNotEmpty ?? false) ||
        (meta['paymentProofType']?.toString().trim().isNotEmpty ?? false);

    if (paymentStatus == 'PAID' || order.status.toUpperCase() == 'PROCESSING') {
      return 'PROCESSING';
    }

    if (order.status.toUpperCase() == 'PENDING_PAYMENT') {
      if (paymentStatus == 'CUSTOMER_REPORTED_PAID' || hasProof) {
        return 'PENDING_PAYMENT_REVIEW';
      }
      return 'PENDING_PAYMENT';
    }
    return order.status;
  }

  bool _shouldShowFinalizePaymentButton(Order order) {
    final status = _effectiveStatus(order);
    return status == 'PENDING_PAYMENT';
  }

  void _resumePayment(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          orderDetails: const {},
          paymentMethod: order.paymentMethod,
          totalAmount: order.totalAmount,
          orderId: order.id,
          launchUssdOnOpen: true,
          paymentPhone: ApiService.userPhone,
          customerCountry: 'TG',
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    final now = DateTime.now();
    final difference = now.difference(order.createdAt);
    final canModify = difference.inHours < 48;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                _statusMiniBadge(order.status),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Détails des articles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: order.orderItems.length,
                itemBuilder: (context, index) {
                  final item = order.orderItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      onTap: () => _showImagePreviewDialog(item.imageUrl),
                      child: SafePhotoThumbnail(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Text('Format ${item.photoSize}'),
                    subtitle: Text('Quantité: ${item.quantity}'),
                    trailing: Text(
                        '${(item.pricePerUnit * item.quantity).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const Divider(),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty) ...[
              Text('Adresse de livraison',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              Text(order.deliveryAddress!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${order.totalAmount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ],
              ),
            ),
            if (canModify && order.status.toUpperCase() == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleModifyOrder(order);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmCancelOrder(order);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            else if (!canModify)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modification et annulation impossibles (délai de 48h dépassé).',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmCancelOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text(
            'Cette action est irréversible. Voulez-vous vraiment annuler cette commande ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NON')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.cancelOrder(order.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Commande annulée avec succès')));
                _fetchAllHistory();
              } catch (e) {
                if (context.mounted) {
                  await showAppError(context, e);
                }
              }
            },
            child: const Text('OUI, ANNULER',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _handleModifyOrder(Order order) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Fonctionnalité de modification bientôt disponible. Veuillez contacter le support pour toute urgence.')));
  }

  void _confirmSoftDeleteWarning(Order order) {
    final canDeleteFromDatabase = _effectiveStatus(order) == 'PENDING_PAYMENT';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              canDeleteFromDatabase
                  ? 'Supprimer la commande'
                  : 'Masquer la commande',
              style: const TextStyle(fontSize: 18),
            )),
          ],
        ),
        content: Text(
          canDeleteFromDatabase
              ? 'Cette commande est en attente de paiement. Elle sera supprimée définitivement de la base et disparaîtra aussi côté admin. Continuer ?'
              : 'Voulez-vous vraiment retirer cette commande de votre historique ?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (canDeleteFromDatabase) {
                  await ApiService.deletePendingPaymentOrder(order.id);
                  await _fetchAllHistory();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Commande supprimée définitivement avec succès.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ));
                  }
                } else {
                  await ApiService.hideOrderLocally(order.id);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text('Commande masquée avec succès.'),
                      backgroundColor: Colors.black87,
                      duration: Duration(seconds: 2),
                    ));
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Suppression impossible: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(canDeleteFromDatabase ? 'Supprimer' : 'Masquer'),
          ),
        ],
      ),
    );
  }
}
