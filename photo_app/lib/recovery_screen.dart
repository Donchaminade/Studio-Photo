import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/widgets/phone_prefix.dart';
import 'package:photo_app/widgets/picon_ui.dart';
import 'package:pinput/pinput.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isRecoveryWithName = true;

  Future<void> _recoverPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      _showNewPasswordDialog();
    }
  }

  void _showNewPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NewPasswordDialog(),
    );
  }

  void _showContactAdminPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contacter l\'administrateur'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour réinitialiser votre code secret, veuillez contacter l\'administrateur via :'),
            SizedBox(height: 16),
            Text('Email: admin@example.com'),
            SizedBox(height: 8),
            Text('Tél: +228 90 00 00 00 / +225 01 02 03 04'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final pinWidth = ((width - 120) / 6).clamp(34.0, 48.0);
    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: 52,
      textStyle: const TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
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
              labels: const ['Nom', 'Téléphone'],
              index: _isRecoveryWithName ? 0 : 1,
              onChanged: (i) => setState(() => _isRecoveryWithName = i == 0),
            ),
            const SizedBox(height: 18),
            if (_isRecoveryWithName)
              TextFormField(
                controller: _nameController,
                decoration: piconField('Nom complet', icon: Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (value) => (value?.isEmpty ?? true) ? 'Champ requis' : null,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AfricanPhonePrefix(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: piconField('Numéro de téléphone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Champ requis' : null,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Pinput(
              controller: _pinController,
              length: 6,
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
              validator: (s) => (s?.length ?? 0) < 6 ? 'Code secret invalide' : null,
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
              onPressed: _recoverPassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog();

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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = true;
      });
      if (!reduceMotion(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 320));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé avec succès!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: piconField('Nouveau mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    if (value.length < 8) return '8 caractères minimum';
                    if (!value.contains(RegExp(r'[A-Z]'))) return '1 majuscule minimum';
                    if (!value.contains(RegExp(r'[a-z]'))) return '1 minuscule minimum';
                    if (!value.contains(RegExp(r'[0-9]'))) return '1 chiffre minimum';
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
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
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
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
