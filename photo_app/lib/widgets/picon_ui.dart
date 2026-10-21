import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Picon/utils/colors.dart';

bool reduceMotion(BuildContext context) {
  final media = MediaQuery.of(context);
  return media.disableAnimations || media.accessibleNavigation;
}

/// Fondu + translation verticale, joué une seule fois.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;

  const Reveal({super.key, required this.child, this.index = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _scheduled = false;
  bool _done = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = reduceMotion(context);
    _controller.duration = Duration(milliseconds: _reduced ? 180 : 500);
    if (_scheduled) return;
    _scheduled = true;
    final delay = _reduced ? 0 : widget.index.clamp(0, 8) * 80;
    if (delay == 0) {
      _controller.forward();
    } else {
      _timer = Timer(Duration(milliseconds: delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final dy = _reduced ? 0.0 : (1 - t) * 40;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
    );
  }
}

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  const TapScale({super.key, required this.child, this.onTap, this.tooltip});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final scale = (!reduced && _down && widget.onTap != null) ? 0.96 : 1.0;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

class PiconCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;

  const PiconCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: border,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: color ?? Colors.white,
        surfaceTintColor: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}

class PiconButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;
  final bool error;
  final int shakeToken;
  final IconData? icon;

  const PiconButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.success = false,
    this.error = false,
    this.shakeToken = 0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final Color bg = error
        ? AppColors.error
        : success
            ? AppColors.success
            : AppColors.primary;
    Widget face;
    if (loading) {
      face = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
    } else if (success) {
      face = const Icon(Icons.check_rounded, color: Colors.white);
    } else if (error) {
      face = const Icon(Icons.close_rounded, color: Colors.white);
    } else {
      face = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    Widget button = SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: face,
      ),
    );

    if (error && !reduced) {
      button = button
          .animate(key: ValueKey(shakeToken))
          .shake(hz: 4, curve: Curves.easeInOut, duration: 420.ms);
    } else if (success && !reduced) {
      button = button
          .animate(key: const ValueKey('ok'))
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
            duration: 220.ms,
            curve: Curves.easeOut,
          );
    }
    return button;
  }
}

InputDecoration piconField(
  String label, {
  IconData? icon,
  Widget? suffix,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
    ),
  );
}

class PiconBackButton extends StatelessWidget {
  final bool dark;

  const PiconBackButton({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      onPressed: () => Navigator.maybePop(context),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: dark ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

AppBar piconBar(
  String title, {
  bool dark = false,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: dark ? Colors.white : AppColors.textPrimary,
    iconTheme: IconThemeData(color: dark ? Colors.white : AppColors.textPrimary),
    systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    leading: PiconBackButton(dark: dark),
    actions: actions,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: dark ? Colors.white : AppColors.textPrimary,
    ),
  );
}

class PiconEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const PiconEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class FillBar extends StatelessWidget {
  final double progress;
  final Color color;

  const FillBar({
    super.key,
    required this.progress,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final target = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: Duration(milliseconds: reduced ? 1 : 800),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFE6EAF2)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value <= 0 ? 0.001 : value,
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedFcfa extends StatelessWidget {
  final double value;
  final Color color;
  final double fontSize;

  const AnimatedFcfa({
    super.key,
    required this.value,
    this.color = Colors.white,
    this.fontSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: Duration(milliseconds: reduced ? 1 : 650),
      curve: Curves.easeOut,
      builder: (context, v, _) {
        return Text.rich(
          TextSpan(
            text: v.toStringAsFixed(0),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
              height: 1,
            ),
            children: [
              TextSpan(
                text: ' FCFA',
                style: TextStyle(
                  fontSize: fontSize * 0.38,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: color.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class PillToggle extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const PillToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: reduced ? 1 : 260),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: i == index ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double height;

  const BrandLogo({super.key, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/pro.png',
      height: height,
      fit: BoxFit.contain,
      cacheWidth: (height * 3).round().clamp(120, 640),
    );
    if (reduceMotion(context)) return image;
    return Hero(tag: 'picon-logo', child: image);
  }
}

/// Déroule un reçu (hauteur) ou un simple fondu si les animations sont réduites.
class Unroll extends StatefulWidget {
  final Widget child;

  const Unroll({super.key, required this.child});

  @override
  State<Unroll> createState() => _UnrollState();
}

class _UnrollState extends State<Unroll> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = reduceMotion(context);
    _controller.duration = Duration(milliseconds: _reduced ? 180 : 800);
    if (_started) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        if (_reduced) {
          return Opacity(opacity: t, child: child);
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t < 0.02 ? 0.02 : t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        );
      },
    );
  }
}
