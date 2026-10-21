import 'package:Picon/models/order.dart';
import 'package:Picon/models/order_item.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/safe_photo_thumbnail.dart';
import 'dart:io';

import 'package:Picon/api_service.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  Widget build(BuildContext context) => _OrderDetailView(screen: this);

  // Ancienne mise en page (v2), conservée.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
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


/// Détail commande v5 : récapitulatif, articles, téléchargement des photos.
class _OrderDetailView extends StatefulWidget {
  final OrderDetailScreen screen;
  const _OrderDetailView({required this.screen});
  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  late Order _order = widget.screen.order;
  bool _downloading = false;
  bool _downloaded = false;

  Future<void> _refresh() async {
    final fresh = await ApiService.fetchOrderById('${_order.id}');
    if (fresh != null && mounted) setState(() => _order = fresh);
  }

  Future<void> _download() async {
    if (_downloading) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Le téléchargement des photos est disponible dans l'application mobile."),
      ));
      return;
    }
    setState(() {
      _downloading = true;
      _downloaded = false;
    });
    try {
      final bytes = await ApiService.downloadOrderPhotosZip(_order.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/picon_commande_${_order.id}_photos.zip');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() => _downloaded = true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: 'Photos commande PICON #${_order.id}',
      ));
    } catch (e) {
      if (mounted) await showAppError(context, e, endSession: false);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.screen._getStatusInfo(_order.status);
    final color = info['color'] as Color;
    final items = _order.orderItems;
    final photos = items.fold<int>(0, (a, i) => a + i.quantity);
    return PiconHeroScaffold(
      title: 'Commande #${_order.id}',
      subtitle: DateFormat('dd/MM/yyyy • HH:mm').format(_order.createdAt),
      icon: Icons.receipt_long_rounded,
      onRefresh: _refresh,
      headerExtra: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(info['icon'] as IconData, size: 16, color: color),
            const SizedBox(width: 6),
            Text(info['text'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ]),
        ),
        const Spacer(),
        Text('$photos tirage${photos > 1 ? 's' : ''}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Reveal(
          child: PiconCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const PiconSectionHeader(icon: Icons.summarize_rounded, title: 'Récapitulatif'),
              PiconKeyValue('Paiement', _order.paymentMethod.replaceAll('_', ' ')),
              PiconKeyValue('Livraison', _order.deliveryType.replaceAll('_', ' ')),
              if ((_order.deliveryAddress ?? '').isNotEmpty) PiconKeyValue('Adresse', _order.deliveryAddress!),
              const Divider(height: 22),
              PiconKeyValue('Total', '${_order.totalAmount.toStringAsFixed(0)} FCFA', strong: true),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Reveal(
          index: 1,
          child: PiconCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PiconSectionHeader(icon: Icons.photo_library_rounded, title: 'Articles (${items.length})'),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Text('Aucun article', style: TextStyle(color: AppColors.textSecondary))),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SafePhotoThumbnail(item.imageUrl,
                        width: 64, height: 64, fit: BoxFit.cover, borderRadius: BorderRadius.circular(14)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.photoSize, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${item.quantity} × ${item.pricePerUnit.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ]),
                    ),
                    Text('${(item.pricePerUnit * item.quantity).toStringAsFixed(0)} F',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        PiconButton(
          label: _downloaded ? 'Photos prêtes — partager à nouveau' : 'Télécharger les photos (ZIP)',
          icon: _downloaded ? Icons.ios_share_rounded : Icons.download_rounded,
          loading: _downloading,
          success: false,
          onPressed: items.isEmpty ? null : _download,
        ),
        const SizedBox(height: 8),
        const Text('Archive de vos fichiers originaux, à enregistrer ou partager.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
