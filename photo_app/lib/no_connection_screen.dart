import 'package:flutter/material.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/picon_ui.dart';

class NoConnectionScreen extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback? onRetry;

  const NoConnectionScreen({
    super.key,
    this.isRetrying = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  const Reveal(
                    child: PiconEmpty(
                      icon: Icons.wifi_off_rounded,
                      title: 'Pas de connexion Internet',
                      subtitle: 'Veuillez vérifier votre connexion et réessayer.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (onRetry != null)
                    PiconButton(
                      label: 'Réessayer',
                      icon: Icons.refresh_rounded,
                      loading: isRetrying,
                      onPressed: isRetrying ? null : onRetry,
                    )
                  else
                    PiconButton(
                      label: 'Mode hors ligne',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
