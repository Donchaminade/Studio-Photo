import 'dart:math' as math;

import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Briques « premium » v3 partagées par Réservation, Statut, Reçu,
/// Confirmation, Infos client, Aperçu photo, Hors ligne et le paiement.

/// Logo PICON (assets/images/pro.png, même fichier que le nouveau favicon
/// admin) dans une pastille blanche.
class PiconLogoPill extends StatelessWidget {
  final double height;
  const PiconLogoPill({super.key, this.height = 26});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Image.asset('assets/images/pro.png', height: height, fit: BoxFit.contain),
      );
}

/// En-tête marine incurvé + contenu qui chevauche (même langage que l'Accueil).
class PiconHeroScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final int? step;
  final int totalSteps;
  final bool showBack;
  final Widget? bottomBar;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;
  final Widget? headerExtra;

  const PiconHeroScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.step,
    this.totalSteps = 4,
    this.showBack = true,
    this.bottomBar,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 28),
    this.onRefresh,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canPop = showBack && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: bottomBar,
      body: _maybeRefresh(CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            // Une seule colonne : le contenu (peint après) chevauche l'en-tête.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(18, top + 10, 18, 64),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF1F5FB8)],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (canPop)
                            _GlassIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              tooltip: 'Retour',
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          const Spacer(),
                          const PiconLogoPill(height: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Icon(icon, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(subtitle!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13.5)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (step != null) ...[
                        const SizedBox(height: 16),
                        PiconStepper(step: step!, total: totalSteps),
                      ],
                      if (headerExtra != null) ...[
                        const SizedBox(height: 16),
                        headerExtra!,
                      ],
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(padding: padding, child: child),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _maybeRefresh(Widget child) => onRefresh == null
      ? child
      : RefreshIndicator(onRefresh: onRefresh!, color: AppColors.primary, child: child);
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => TapScale(
        tooltip: tooltip,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}

/// Étapes du tunnel : Panier → Infos → Paiement → Reçu.
class PiconStepper extends StatelessWidget {
  final int step;
  final int total;
  static const labels = ['Panier', 'Infos', 'Paiement', 'Reçu'];
  const PiconStepper({super.key, required this.step, this.total = 4});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (total == labels.length) ...[
                  const SizedBox(height: 6),
                  Text(labels[i],
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: active ? 0.95 : 0.55),
                          fontSize: 11.5,
                          fontWeight: i == step ? FontWeight.w800 : FontWeight.w500)),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Titre de section dans une carte, avec pastille d'icône.
class PiconSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const PiconSectionHeader({super.key, required this.icon, required this.title, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.textPrimary)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Ligne clé / valeur.
class PiconKeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;
  const PiconKeyValue(this.label, this.value, {super.key, this.strong = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: strong ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                    fontSize: strong ? 16 : 14)),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? (strong ? AppColors.primary : AppColors.textPrimary),
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                    fontSize: strong ? 18 : 14)),
          ),
        ]),
      );
}

/// Barre d'action basse (montant + CTA), style « $19.01 | Pay Now ».
class PiconPayBar extends StatelessWidget {
  final String amountLabel;
  final String amount;
  final Widget action;
  const PiconPayBar({super.key, required this.amountLabel, required this.amount, required this.action});
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.navyDeep,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x40032A85), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(amountLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
              const SizedBox(height: 2),
              Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
            ]),
            const SizedBox(width: 14),
            Expanded(child: action),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Étape de paiement (réf. DcGgytAzym7) : anneau qui pulse → coche verte.
// ---------------------------------------------------------------------------

enum CheckoutPhase { processing, success, error }

class CheckoutStage extends StatefulWidget {
  final CheckoutPhase phase;
  final String title;
  final String subtitle;
  const CheckoutStage({super.key, required this.phase, required this.title, required this.subtitle});
  @override
  State<CheckoutStage> createState() => _CheckoutStageState();
}

class _CheckoutStageState extends State<CheckoutStage> with TickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant CheckoutStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _sync();
  }

  void _sync() {
    final reduced = reduceMotion(context);
    if (widget.phase == CheckoutPhase.processing) {
      _pop.value = 0;
      if (!reduced && !_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
      if (reduced) {
        _pop.value = 1;
      } else {
        _pop.forward(from: 0);
      }
      if (widget.phase == CheckoutPhase.success) HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.phase == CheckoutPhase.success;
    final ko = widget.phase == CheckoutPhase.error;
    final color = ok ? AppColors.success : (ko ? AppColors.error : AppColors.accent);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _pop]),
          builder: (context, _) {
            final pulse = 0.5 + 0.5 * math.sin(_spin.value * math.pi * 2);
            final pop = Curves.easeOutBack.transform(_pop.value.clamp(0.0, 1.0));
            return Stack(alignment: Alignment.center, children: [
              Container(
                width: 110 + 10 * (widget.phase == CheckoutPhase.processing ? pulse : 1),
                height: 110 + 10 * (widget.phase == CheckoutPhase.processing ? pulse : 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10 + 0.08 * pulse),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30)],
                ),
              ),
              if (widget.phase == CheckoutPhase.processing)
                Transform.rotate(
                  angle: _spin.value * math.pi * 2,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: 0.28,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                )
              else
                Transform.scale(
                  scale: pop.clamp(0.0, 1.2),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 46),
                  ),
                ),
              if (widget.phase == CheckoutPhase.processing)
                const Icon(Icons.lock_rounded, color: AppColors.primary, size: 30),
            ]);
          },
        ),
      ),
      const SizedBox(height: 18),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          key: ValueKey(widget.phase),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(widget.subtitle,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
          ],
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Reçu imprimé (réf. Det3T7LJmXD) : le ticket sort d'une fente par paliers,
// puis un tampon « PAYÉ » s'imprime de travers.
// ---------------------------------------------------------------------------

class PrintedReceipt extends StatefulWidget {
  final Widget ticket;
  final String stampLabel;
  final VoidCallback? onPrinted;
  const PrintedReceipt({super.key, required this.ticket, this.stampLabel = 'PAYÉ', this.onPrinted});
  @override
  State<PrintedReceipt> createState() => _PrintedReceiptState();
}

class _PrintedReceiptState extends State<PrintedReceipt> with TickerProviderStateMixin {
  late final _print = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  late final _stamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  int _lastStep = -1;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _print.value = 1;
      _stamp.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPrinted?.call());
      return;
    }
    _print.addListener(_haptic);
    _print.forward().whenComplete(() {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _stamp.forward().whenComplete(() => widget.onPrinted?.call());
    });
  }

  void _haptic() {
    final s = (_print.value * 9).floor();
    if (s != _lastStep) {
      _lastStep = s;
      HapticFeedback.selectionClick();
    }
  }

  static double _stepped(double t) {
    const n = 9;
    final i = (t * n).floorToDouble();
    final f = ((t * n - i) / 0.65).clamp(0.0, 1.0);
    return ((i + Curves.easeOut.transform(f)) / n).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _print.dispose();
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Fente d'imprimante.
      Container(
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [Color(0xFFB8C3D6), Color(0xFFEFF3F9), Color(0xFFB8C3D6)]),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Center(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFF1B2333), borderRadius: BorderRadius.circular(3)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([_print, _stamp]),
            builder: (context, child) {
              final p = _stepped(_print.value);
              final jitter = _print.isAnimating ? math.sin(_print.value * 120) * 0.5 : 0.0;
              return Align(
                alignment: Alignment.bottomCenter,
                heightFactor: p,
                child: Transform.translate(offset: Offset(jitter, 0), child: child),
              );
            },
            child: Stack(children: [
              widget.ticket,
              Positioned(
                right: 14,
                bottom: 120,
                child: AnimatedBuilder(
                  animation: _stamp,
                  builder: (context, child) {
                    final t = _stamp.value;
                    final s = 1.6 - 0.6 * Curves.easeOutBack.transform(t).clamp(0.0, 1.1);
                    final angle = (-20 + 8 * t) * math.pi / 180;
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.rotate(angle: angle, child: Transform.scale(scale: s, child: child)),
                    );
                  },
                  child: PaidStamp(label: widget.stampLabel),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class PaidStamp extends StatelessWidget {
  final String label;
  const PaidStamp({super.key, this.label = 'PAYÉ'});
  @override
  Widget build(BuildContext context) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.85), width: 3),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('PICON',
                style: TextStyle(
                    fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800, color: AppColors.accent.withValues(alpha: 0.85))),
            Text(label,
                style: TextStyle(
                    fontSize: 19, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: AppColors.accent.withValues(alpha: 0.9))),
          ]),
        ),
      );
}

/// Bord bas en zigzag (ticket de caisse).
class ZigZagClipper extends CustomClipper<Path> {
  final double tooth;
  const ZigZagClipper({this.tooth = 8});
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height - tooth);
    var x = 0.0;
    var down = true;
    while (x < size.width) {
      x = math.min(x + tooth, size.width);
      p.lineTo(x, down ? size.height : size.height - tooth);
      down = !down;
    }
    p
      ..lineTo(size.width, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant ZigZagClipper oldClipper) => oldClipper.tooth != tooth;
}

/// Pointillés horizontaux pour le ticket.
class TicketDashes extends StatelessWidget {
  const TicketDashes({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(builder: (context, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(n, (_) => Container(width: 4, height: 1.2, color: const Color(0xFF9AA4B5))),
          );
        }),
      );
}

/// Style monospace du ticket.
const TextStyle kTicketMono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['RobotoMono', 'Courier', 'Courier New'],
  fontSize: 13,
  color: Color(0xFF1B2333),
  height: 1.35,
);
