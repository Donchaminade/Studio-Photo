import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/home_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RecentRequest> fullHistory = [
      RecentRequest(title: 'Commande de 15 photos', date: DateTime.now().subtract(const Duration(days: 1)), icon: Icons.photo_camera),
      RecentRequest(title: "Photos d'identité", date: DateTime.now().subtract(const Duration(days: 4)), icon: Icons.person),
      RecentRequest(title: 'Tirage 20x30', date: DateTime.now().subtract(const Duration(days: 6)), icon: Icons.print),
      RecentRequest(title: 'Commande Album', date: DateTime.now().subtract(const Duration(days: 10)), icon: Icons.book),
      RecentRequest(title: 'Réservation - Mariage', date: DateTime.now().subtract(const Duration(days: 15)), icon: Icons.calendar_today),
      RecentRequest(title: 'Shooting Famille', date: DateTime.now().subtract(const Duration(days: 22)), icon: Icons.family_restroom),
      RecentRequest(title: 'Tirage 10x15', date: DateTime.now().subtract(const Duration(days: 31)), icon: Icons.print),
      RecentRequest(title: 'Photos CV', date: DateTime.now().subtract(const Duration(days: 45)), icon: Icons.work),
      RecentRequest(title: 'Commande Agrandissement', date: DateTime.now().subtract(const Duration(days: 50)), icon: Icons.photo_size_select_large),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: piconBar('Historique complet'),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: fullHistory.length,
        itemBuilder: (context, index) {
          final item = fullHistory[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Reveal(
              index: index,
              child: PiconCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () {},
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      child: Icon(item.icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy').format(item.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
