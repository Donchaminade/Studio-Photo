import 'package:Picon/utils/colors.dart';
import 'package:flutter/material.dart';

/// Dialogue unique : mise à jour Play Store (Flexible).
class AppUpdateAvailableDialog extends StatelessWidget {
  const AppUpdateAvailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Une mise à jour est disponible',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Une nouvelle version de Picon est prête. Vous pouvez l\'installer maintenant ou plus tard.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Plus tard',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}
