import 'dart:math' as math;
import 'dart:ui';

import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

/// État visuel d'une saisie de code (réf. « Glassy OTP » DdWWd8OTBoO).
enum OtpStage { idle, verifying, error, success }

/// Cases de code en verre dépoli : halo sur la case active, saisie
/// automatique case par case, collage, tremblement rouge en cas d'erreur,
/// coche de succès. Repose sur Pinput (clavier, collage, autofill SMS).
class GlassOtpField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final OtpStage stage;
  final bool dark;
  final bool obscure;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const GlassOtpField({
    super.key,
    required this.controller,
    this.focusNode,
    this.length = 4,
    this.stage = OtpStage.idle,
    this.dark = true,
    this.obscure = false,
    this.onCompleted,
    this.onChanged,
    this.validator,
  });

  @override
  State<GlassOtpField> createState() => _GlassOtpFieldState();
}

class _GlassOtpFieldState extends State<GlassOtpField> with TickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _done =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    _sync(null);
  }

  @override
  void didUpdateWidget(covariant GlassOtpField old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) _sync(old.stage);
  }

  void _sync(OtpStage? previous) {
    final reduced = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (widget.stage == OtpStage.verifying && !reduced) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
    if (widget.stage == OtpStage.error && previous != OtpStage.error && !reduced) {
      _shake.forward(from: 0);
    }
    if (widget.stage == OtpStage.success) {
      reduced ? _done.value = 1 : _done.forward(from: 0);
    } else {
      _done.value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pulse.dispose();
    _done.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.stage) {
        OtpStage.error => AppColors.error,
        OtpStage.success => AppColors.success,
        _ => AppColors.accent,
      };

  PinTheme _theme(double w, {required bool focused, required bool filled}) {
    final dark = widget.dark;
    final accent = _accent;
    final glow = focused || widget.stage == OtpStage.error || widget.stage == OtpStage.success;
    return PinTheme(
      width: w,
      height: w * 1.12,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: dark ? Colors.white : AppColors.primary,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [Colors.white.withValues(alpha: filled ? 0.18 : 0.10), Colors.white.withValues(alpha: 0.03)]
              : [Colors.white, AppColors.primary.withValues(alpha: filled ? 0.07 : 0.03)],
        ),
        border: Border.all(
          color: glow
              ? accent
              : (dark ? Colors.white.withValues(alpha: filled ? 0.38 : 0.2) : AppColors.primary.withValues(alpha: 0.22)),
          width: glow ? 1.6 : 1,
        ),
        boxShadow: [
          if (glow) BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: 0.5),
          BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return LayoutBuilder(builder: (context, c) {
      final gap = 10.0;
      final w = ((c.maxWidth - gap * (widget.length - 1)) / widget.length).clamp(40.0, 62.0);
      final pin = Pinput(
        length: widget.length,
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscure,
        obscuringCharacter: '●',
        enabled: widget.stage != OtpStage.verifying && widget.stage != OtpStage.success,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        closeKeyboardWhenCompleted: true,
        onCompleted: widget.onCompleted,
        onChanged: widget.onChanged,
        validator: widget.validator,
        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
        errorTextStyle: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w600),
        separatorBuilder: (_) => SizedBox(width: gap),
        animationCurve: Curves.easeOutCubic,
        animationDuration: Duration(milliseconds: reduced ? 1 : 220),
        pinAnimationType: reduced ? PinAnimationType.none : PinAnimationType.scale,
        defaultPinTheme: _theme(w, focused: false, filled: false),
        focusedPinTheme: _theme(w, focused: true, filled: false),
        submittedPinTheme: _theme(w, focused: false, filled: true),
        errorPinTheme: _theme(w, focused: false, filled: true),
        cursor: Container(
          width: 2,
          height: 22,
          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2)),
        ),
      );

      return AnimatedBuilder(
        animation: Listenable.merge([_shake, _pulse, _done]),
        builder: (context, child) {
          final dx = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 12;
          final pulse = _pulse.isAnimating ? 0.6 + 0.4 * math.sin(_pulse.value * math.pi * 2).abs() : 1.0;
          final d = Curves.easeOutBack.transform(_done.value.clamp(0, 1));
          return SizedBox(
            height: w * 1.12 + 26,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: (1 - _done.value * 1.4).clamp(0, 1) * pulse,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.scale(scale: 1 - 0.25 * _done.value, child: child),
                  ),
                ),
                if (_done.value > 0)
                  Positioned(
                    top: 0,
                    child: Transform.scale(
                      scale: d,
                      child: Container(
                        width: w * 1.12,
                        height: w * 1.12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: AppColors.success.withValues(alpha: 0.18),
                          border: Border.all(color: AppColors.success, width: 1.8),
                          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.55), blurRadius: 22)],
                        ),
                        child: const Icon(Icons.check_rounded, color: AppColors.success, size: 34),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: pin,
      );
    });
  }
}

/// Carte de verre sombre qui accueille une étape de code (en-tête, cases,
/// état de vérification). Couleurs PICON.
class GlassOtpPanel extends StatelessWidget {
  final OtpStage stage;
  final String title;
  final String subtitle;
  final String successTitle;
  final String successSubtitle;
  final Widget field;
  final Widget? footer;

  const GlassOtpPanel({
    super.key,
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.field,
    this.successTitle = 'Code vérifié',
    this.successSubtitle = 'Votre code a été confirmé.',
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final ok = stage == OtpStage.success;
    final err = stage == OtpStage.error;
    final accent = ok ? AppColors.success : (err ? AppColors.error : AppColors.accent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduced ? 1 : 420),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ok
                  ? const [Color(0xE60B2E3A), Color(0xE6071433)]
                  : const [Color(0xE6102A6B), Color(0xE6071433)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 18))],
          ),
          child: Stack(
            children: [
              // Reflets de verre (coins), comme la référence.
              Positioned(
                top: -30,
                left: -30,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: reduced ? 1 : 320),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: accent.withValues(alpha: 0.16),
                      border: Border.all(color: accent.withValues(alpha: 0.7)),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 16)],
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: reduced ? 1 : 260),
                      child: Icon(
                        ok ? Icons.verified_user_rounded : Icons.vpn_key_rounded,
                        key: ValueKey(ok),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: reduced ? 1 : 260),
                    child: Text.rich(
                      key: ValueKey(ok),
                      _accentTitle(ok ? successTitle : title, accent),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ok ? successSubtitle : subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 20),
                  field,
                  if (footer != null) ...[const SizedBox(height: 10), footer!],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dernier mot du titre en couleur d'accent (« Vérifier le **code** »).
  static TextSpan _accentTitle(String text, Color accent) {
    final i = text.lastIndexOf(' ');
    if (i <= 0) return TextSpan(text: text, style: TextStyle(color: accent));
    return TextSpan(children: [
      TextSpan(text: text.substring(0, i + 1)),
      TextSpan(text: text.substring(i + 1), style: TextStyle(color: accent)),
    ]);
  }
}

/// Bouton de vérification : attend la vraie réponse du backend
/// (« Vérification… » → « Vérifié » vert, ou rouge en cas d'erreur).
class OtpVerifyButton extends StatelessWidget {
  final OtpStage stage;
  final String label;
  final String verifyingLabel;
  final String successLabel;
  final VoidCallback? onPressed;

  const OtpVerifyButton({
    super.key,
    required this.stage,
    required this.onPressed,
    this.label = 'Valider',
    this.verifyingLabel = 'Vérification…',
    this.successLabel = 'Vérifié et sécurisé',
  });

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final busy = stage == OtpStage.verifying;
    final ok = stage == OtpStage.success;
    final bg = ok ? AppColors.success : (stage == OtpStage.error ? AppColors.error : AppColors.accent);
    return Semantics(
      button: true,
      label: ok ? successLabel : (busy ? verifyingLabel : label),
      child: TapScale(
        onTap: busy || ok ? null : onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduced ? 1 : 300),
          height: 54,
          decoration: BoxDecoration(
            color: onPressed == null && !busy && !ok ? bg.withValues(alpha: 0.45) : bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: reduced ? 1 : 220),
            child: Row(
              key: ValueKey(stage),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                else
                  Icon(ok ? Icons.verified_rounded : Icons.lock_open_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    ok ? successLabel : (busy ? verifyingLabel : label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
