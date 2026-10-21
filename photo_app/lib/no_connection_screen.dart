import 'package:flutter/material.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/utils/colors.dart';

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
    final reduced = reduceMotion(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF1F5FB8)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(children: [
              const Align(alignment: Alignment.centerRight, child: PiconLogoPill(height: 20)),
              const Spacer(),
              _OfflineBadge(animate: !reduced),
              const SizedBox(height: 28),
              const Text('Pas de connexion Internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Veuillez vérifier votre connexion et réessayer.\nVos paniers et votre session sont conservés.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.4)),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Column(children: const [
                  _Tip(icon: Icons.wifi_rounded, text: 'Activez le Wi-Fi ou les données mobiles'),
                  SizedBox(height: 10),
                  _Tip(icon: Icons.airplanemode_inactive_rounded, text: 'Désactivez le mode avion'),
                ]),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: isRetrying
                      ? null
                      : (onRetry ??
                          () {
                            if (Navigator.canPop(context)) Navigator.pop(context);
                          }),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: isRetrying
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))
                      : Icon(onRetry != null ? Icons.refresh_rounded : Icons.arrow_back_rounded),
                  label: Text(onRetry != null ? (isRetrying ? 'Nouvelle tentative…' : 'Réessayer') : 'Mode hors ligne',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Ancienne mise en page (v2), conservée.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
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


class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]);
}

class _OfflineBadge extends StatefulWidget {
  final bool animate;
  const _OfflineBadge({required this.animate});
  @override
  State<_OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends State<_OfflineBadge> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        height: 170,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(alignment: Alignment.center, children: [
            for (final k in [0.0, 0.5])
              Opacity(
                opacity: (1 - ((_c.value + k) % 1)).clamp(0.0, 1.0) * 0.5,
                child: Container(
                  width: 90 + 80 * ((_c.value + k) % 1),
                  height: 90 + 80 * ((_c.value + k) % 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 44),
            ),
          ]),
        ),
      );
}
