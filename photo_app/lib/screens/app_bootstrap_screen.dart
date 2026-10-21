import 'package:Picon/api_service.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/login_screen.dart';
import 'package:Picon/screens/permissions_onboarding_screen.dart';
import 'package:Picon/utils/app_permissions_service.dart';
import 'package:Picon/utils/app_update_service.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';

/// Point d'entrée : permissions (1ère fois) puis login ou accueil.
class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  bool _loading = true;
  bool _showPermissionsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = await AppPermissionsService.isOnboardingDone();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _showPermissionsOnboarding = !done;
    });
    _schedulePlayUpdateCheck();
  }

  void _onPermissionsComplete() {
    setState(() => _showPermissionsOnboarding = false);
    _schedulePlayUpdateCheck();
  }

  /// Après splash / bootstrap, pas pendant l’écran permissions.
  void _schedulePlayUpdateCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading || _showPermissionsOnboarding) return;
      AppUpdateService.instance.maybePrompt(context);
    });
  }

  Widget _destination() {
    return const _SessionGate();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PiconBrandLoader();
    }

    if (_showPermissionsOnboarding) {
      return PermissionsOnboardingScreen(
        onComplete: _onPermissionsComplete,
      );
    }

    return _destination();
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool _checking = true;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    if (ApiService.authToken == null || ApiService.userId == null) {
      if (mounted) {
        setState(() {
          _checking = false;
          _valid = false;
        });
      }
      return;
    }
    final ok = await ApiService.ensureSession();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _valid = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const PiconBrandLoader(label: 'Vérification de votre session…');
    }
    if (_valid) {
      return HomeScreen(
        userName: ApiService.userName ?? 'Utilisateur',
        userLastName: ApiService.userLastName ?? '',
        userEmail: ApiService.userEmail ?? '',
        userId: ApiService.userId!,
      );
    }
    return const LoginScreen();
  }
}
