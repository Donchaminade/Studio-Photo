import 'package:Picon/api_service.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/recovery_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/phone_prefix.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _success = false;
  bool _error = false;
  int _shake = 0;
  bool _isLoginWithPhone = true;
  String _selectedDialCode = '+228';

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _error = true;
        _shake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (mounted) setState(() => _error = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = false;
      _success = false;
    });

    try {
      final Map<String, dynamic> responseData = _isLoginWithPhone
          ? await ApiService.login(
              phone: _buildFullPhoneNumber(_phoneController.text),
              password: _passwordController.text,
            )
          : await ApiService.login(
              email: _emailController.text,
              password: _passwordController.text,
            );

      if (!mounted) return;
      await ApiService.saveAuthDetails(responseData);
      if (!mounted) return;

      setState(() => _success = true);
      if (!reduceMotion(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: responseData['firstname'] ?? '',
            userLastName: responseData['lastname'] ?? '',
            userEmail: responseData['email'] ?? '',
            userId: responseData['id'] ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _shake++;
      });
      await showAppError(context, e, onRetry: _login);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
                  const SizedBox(height: 12),
                  const Reveal(child: BrandLogo(height: 96)),
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Connectez-vous pour continuer',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Center(child: _SecureBadge()),
            const SizedBox(height: 16),
            PillToggle(
              labels: const ['Téléphone', 'Email'],
              index: _isLoginWithPhone ? 0 : 1,
              onChanged: (i) => setState(() => _isLoginWithPhone = i == 0),
            ),
            const SizedBox(height: 18),
            if (_isLoginWithPhone)
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
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Champ requis' : null,
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: _emailController,
                decoration: piconField('Email', icon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      .hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _login(),
              decoration:
                  piconField('Mot de passe', icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  tooltip: _obscureText ? 'Afficher' : 'Masquer',
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Champ requis' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecoveryScreen(),
                    ),
                  );
                },
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            PiconButton(
              label: 'Connexion',
              onPressed: _isLoading ? null : _login,
              loading: _isLoading,
              success: _success,
              error: _error,
              shakeToken: _shake,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pas de compte ?',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text(
                    "S'inscrire",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge « connexion sécurisée » (réf. login secure DcOUIemTImO) : le cadenas
/// se transforme une fois en bouclier, puis reste fixe.
class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (context, t, _) => Icon(
              t < 0.6 ? Icons.lock_outline_rounded : Icons.verified_user_outlined,
              size: 16,
              color: Color.lerp(AppColors.textSecondary, AppColors.primary, t.clamp(0, 1)),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Connexion sécurisée',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
