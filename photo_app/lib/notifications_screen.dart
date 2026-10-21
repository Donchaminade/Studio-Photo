import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: piconBar('Notifications'),
      body: const PiconEmpty(
        icon: Icons.notifications_off_outlined,
        title: 'Aucune notification pour le moment',
        subtitle: 'Vos alertes de commande apparaîtront ici.',
      ),
    );
  }
}
