import 'package:Picon/api_service.dart';
import 'package:Picon/models/app_notification.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:Picon/order_receipt_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e);
      }
    }
  }

  void _showError(Object e) {
    showAppError(context, e);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ORDER_CREATED':
        return Icons.receipt_long;
      case 'PAYMENT_UNDER_REVIEW':
        return Icons.hourglass_top;
      case 'PAYMENT_CONFIRMED':
        return Icons.verified;
      case 'ORDER_COMPLETED':
        return Icons.check_circle;
      case 'ORDER_CANCELLED':
      case 'ORDER_CANCELLED_BY_YOU':
        return Icons.cancel_outlined;
      case 'CANCELLATION_REFUSED':
        return Icons.block;
      case 'REFUND_PENDING':
        return Icons.sync;
      case 'REFUND_CONFIRMED':
        return Icons.undo;
      case 'BOOKING_CONFIRMED':
        return Icons.event_available;
      case 'BOOKING_CANCELLED':
        return Icons.event_busy;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'PAYMENT_CONFIRMED':
      case 'ORDER_COMPLETED':
      case 'BOOKING_CONFIRMED':
      case 'REFUND_CONFIRMED':
        return AppColors.success;
      case 'CANCELLATION_REFUSED':
      case 'ORDER_CANCELLED':
      case 'BOOKING_CANCELLED':
        return AppColors.error;
      case 'REFUND_PENDING':
      case 'PAYMENT_UNDER_REVIEW':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  Future<void> _openDetail(AppNotification notification) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_iconForType(notification.type),
                color: _colorForType(notification.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(notification.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (notification.relatedOrderId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Commande #${notification.relatedOrderId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (notification.relatedOrderId != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Recharge le statut de paiement depuis l'API → bonne variante de reçu.
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderReceiptScreen(orderId: notification.relatedOrderId!),
                ));
              },
              child: const Text('Voir le reçu'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (!notification.read) {
      try {
        final updated =
            await ApiService.markNotificationAsRead(notification.id);
        if (mounted) {
          setState(() {
            final idx =
                _notifications.indexWhere((n) => n.id == notification.id);
            if (idx >= 0) {
              _notifications[idx] = updated;
            }
          });
        }
      } catch (e) {
        if (mounted) _showError(e);
      }
    }
  }

  Future<void> _confirmDelete(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text(
            'Voulez-vous supprimer cette notification définitivement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteNotification(notification.id);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
      }
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const PiconSkeletonList(count: 7)
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return _NotificationTile(
                        notification: n,
                        icon: _iconForType(n.type),
                        color: _colorForType(n.type),
                        dateLabel: _formatDate(n.createdAt),
                        onTap: () => _openDetail(n),
                        onLongPress: () => _confirmDelete(n),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.notifications_off_outlined,
            size: 80, color: AppColors.textSecondary),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Aucune notification pour le moment',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.dateLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.read;

    return Material(
      color: isRead ? Colors.white : color.withOpacity(0.04),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isRead)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check,
                                size: 16, color: AppColors.success),
                          )
                        else
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
