import 'package:Picon/utils/app_error.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:flutter/material.dart';

/// Écran / dialogue d’indisponibilité : illustration + texte FR, zéro jargon.
class AppStatusPanel extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  const AppStatusPanel({
    super.key,
    required this.error,
    this.onRetry,
    this.onClose,
  });

  String get _asset {
    switch (error.kind) {
      case AppErrorKind.network:
        return 'assets/images/status/no_network.png';
      case AppErrorKind.session:
        return 'assets/images/status/session_expired.png';
      case AppErrorKind.server:
      case AppErrorKind.auth:
      case AppErrorKind.generic:
        return 'assets/images/status/server_down.png';
    }
  }

  String get _title {
    switch (error.kind) {
      case AppErrorKind.network:
        return 'Pas de connexion';
      case AppErrorKind.session:
        return 'Session expirée';
      case AppErrorKind.server:
        return 'Service indisponible';
      case AppErrorKind.auth:
      case AppErrorKind.generic:
        return 'Un souci est survenu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      _asset,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      error.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (onClose != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onClose,
                        child: const Text('Fermer'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
