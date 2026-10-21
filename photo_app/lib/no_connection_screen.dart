import 'package:flutter/material.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({super.key});

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
