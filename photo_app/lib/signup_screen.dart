import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_app/services/session_store.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/widgets/loading_button.dart';
import 'package:photo_app/widgets/music_wave_loader.dart';
import 'package:photo_app/widgets/phone_prefix.dart';
import 'package:photo_app/widgets/picon_ui.dart';
import 'package:pinput/pinput.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _dialCode = '+228';

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      // L'indicatif pays choisi est conservé avec le numéro.
      await SessionStore.instance.saveSignupContact(
        dialCode: _dialCode,
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      _showPinCreationSheet(context);
    }
  }

  void _showPinCreationSheet(BuildContext context) {
    final reduced = reduceMotion(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: Duration(milliseconds: reduced ? 120 : 400),
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: _PinCreationSheet(),
          ),
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        if (reduced) return FadeTransition(opacity: animation, child: child);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  const Reveal(child: BrandLogo(height: 88)),
                  const SizedBox(height: 8),
                  Reveal(index: 1, child: _buildForm()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return PiconCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Créer un compte',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: piconField('Nom complet', icon: Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AfricanPhonePrefix(onChanged: (code) => _dialCode = code),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: piconField('Numéro de téléphone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Numéro de téléphone requis';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration:
                  piconField('Email (facultatif)', icon: Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value)) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration:
                  piconField('Mot de passe', icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mot de passe requis';
                }
                if (value.length < 8) {
                  return 'Le mot de passe doit contenir au moins 8 caractères';
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return 'Inclure au moins une majuscule';
                }
                if (!value.contains(RegExp(r'[a-z]'))) {
                  return 'Inclure au moins une minuscule';
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return 'Inclure au moins un chiffre';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              decoration: piconField('Confirmer le mot de passe',
                      icon: Icons.lock_outline)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            LoadingButton(
              onPressed: _signup,
              text: "S'inscrire",
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Déjà un compte ?',
                    style: TextStyle(color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Connectez-vous',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinCreationSheet extends StatefulWidget {
  const _PinCreationSheet();

  @override
  State<_PinCreationSheet> createState() => _PinCreationSheetState();
}

class _PinCreationSheetState extends State<_PinCreationSheet> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  void _showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: MusicWaveLoader(),
          ),
        );
      },
    );
  }

  Future<void> _validatePin() async {
    _showLoader(context);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Compte créé avec succès!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pinWidth = ((width - 96) / 6).clamp(36.0, 52.0);
    final base = PinTheme(
      width: pinWidth,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 12),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              color: const Color(0xCC102044),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.vpn_key_outlined, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Créez votre code secret',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ce code sécurisera vos transactions et connexions futures.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 22),
                  Pinput(
                    length: 6,
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    defaultPinTheme: base,
                    focusedPinTheme: base.copyWith(
                      decoration: base.decoration!.copyWith(
                        border: Border.all(color: AppColors.accent, width: 1.6),
                      ),
                    ),
                    separatorBuilder: (index) => const SizedBox(width: 6),
                  ),
                  const SizedBox(height: 22),
                  PiconButton(
                    label: 'Valider',
                    onPressed: _validatePin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
