import 'package:Picon/api_service.dart';
import 'package:Picon/notifications_screen.dart';
import 'package:flutter/material.dart';

/// Icône cloche avec badge du nombre de notifications non lues.
class NotificationBellButton extends StatefulWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationBellButton({
    super.key,
    this.iconColor = Colors.white,
    this.iconSize = 28,
  });

  @override
  NotificationBellButtonState createState() => NotificationBellButtonState();
}

class NotificationBellButtonState extends State<NotificationBellButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  /// Recharge le compteur depuis l'API (à appeler après retour sur l'accueil).
  Future<void> refresh() async {
    try {
      final count = await ApiService.fetchUnreadNotificationCount();
      if (mounted && count != _unreadCount) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {
      // Hors ligne ou session expirée
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: _unreadCount > 0,
      backgroundColor: Colors.red,
      label: Text(
        _unreadCount > 99 ? '99+' : '$_unreadCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: _openNotifications,
        icon: Icon(
          Icons.notifications_none,
          color: widget.iconColor,
          size: widget.iconSize,
        ),
      ),
    );
  }
}
