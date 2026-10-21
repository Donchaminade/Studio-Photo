import 'package:Picon/api_service.dart';
import 'package:Picon/models/contact_info.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/phone_prefix.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isRecoveryWithEmail = true;
  bool _isLoading = false;
  String _selectedDialCode = '+228';

  Future<void> _recoverPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final identifier = _isRecoveryWithEmail
          ? _emailController.text.trim()
          : _buildFullPhoneNumber(_phoneController.text);
      final response = await ApiService.verifyPinForPasswordReset(
        email: _isRecoveryWithEmail ? identifier : null,
        phone: !_isRecoveryWithEmail ? identifier : null,
        pin: _pinController.text,
      );
      if (!mounted) return;
      _showNewPasswordDialog(response['resetToken'] as String);
    } catch (e) {
      if (mounted) await showAppError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildFullPhoneNumber(String rawPhone) {
    var cleaned = rawPhone.trim().replaceAll(RegExp(r'[\s.\-()]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('00')) return '+${cleaned.substring(2)}';
    if (cleaned.startsWith('228') && cleaned.length >= 11) return '+$cleaned';
    if (cleaned.startsWith('0') && cleaned.length == 9) {
      cleaned = cleaned.substring(1);
    }
    return '$_selectedDialCode$cleaned';
  }

  void _showNewPasswordDialog(String resetToken) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewPasswordDialog(resetToken: resetToken),
    );
  }

  void _showContactAdminPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contacter l\'administrateur'),
        content: FutureBuilder<ContactInfo>(
          future: ApiService.fetchContactInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: PiconSkeleton(width: 220, height: 56, radius: 16)),
              );
            }
            final info = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pour réinitialiser votre code secret, veuillez contacter l\'administrateur :',
                ),
                const SizedBox(height: 16),
                Text('Email: ${info?.email ?? '—'}'),
                const SizedBox(height: 8),
                Text('Tél: ${info?.phoneNumber ?? '—'}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () async {
              final info = await ApiService.fetchContactInfo();
              final uri = Uri.parse('mailto:${info.email}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: const Text('Écrire'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: piconBar('Récupération'),
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
                  const Reveal(child: BrandLogo(height: 84)),
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
    final width = MediaQuery.sizeOf(context).width;
    final pinWidth = ((width - 120) / 4).clamp(34.0, 56.0);
    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 18,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 10),
        ],
      ),
    );

    return PiconCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Récupération du compte',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Entrez vos informations pour continuer',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            PillToggle(
              labels: const ['Email', 'Téléphone'],
              index: _isRecoveryWithEmail ? 0 : 1,
              onChanged: (i) => setState(() => _isRecoveryWithEmail = i == 0),
            ),
            const SizedBox(height: 18),
            if (_isRecoveryWithEmail)
              TextFormField(
                controller: _emailController,
                decoration: piconField('Email', icon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Champ requis' : null,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AfricanPhonePrefix(
                    onChanged: (dial) => _selectedDialCode = dial,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: piconField('Numéro de téléphone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Champ requis' : null,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Pinput(
              controller: _pinController,
              length: 4,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.primary, width: 1.6),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.error),
                ),
              ),
              separatorBuilder: (index) => const SizedBox(width: 6),
              validator: (s) =>
                  (s?.length ?? 0) < 4 ? 'Code secret invalide' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showContactAdminPopup,
                child: const Text('Code secret oublié ?'),
              ),
            ),
            PiconButton(
              label: 'Valider',
              onPressed: _isLoading ? null : _recoverPassword,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPasswordDialog extends StatefulWidget {
  final String resetToken;

  const _NewPasswordDialog({required this.resetToken});

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _success = false;

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPasswordWithToken(
        token: widget.resetToken,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _success = true);
      if (!reduceMotion(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (mounted) await showAppError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Créer un nouveau mot de passe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: piconField('Nouveau mot de passe').copyWith(
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
                    if (value == null || value.isEmpty) return 'Champ requis';
                    if (value.length < 8) return '8 caractères minimum';
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return '1 majuscule minimum';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return '1 minuscule minimum';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return '1 chiffre minimum';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: piconField('Confirmer le mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                PiconButton(
                  label: 'Valider',
                  onPressed: _isLoading ? null : _resetPassword,
                  loading: _isLoading,
                  success: _success,
                ),
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: AppColors.textPrimary),
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
