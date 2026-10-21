import 'dart:async';

import 'package:Picon/no_connection_screen.dart';
import 'package:Picon/utils/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Affiche [NoConnectionScreen] par-dessus toute l'app dès que la connexion
/// est absente, quelle que soit la page courante.
class ConnectivityWrapper extends StatefulWidget {
  final Widget? child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isConnected = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription =
        _connectivityService.connectivityStream.listen(_onConnectivityChanged);
  }

  Future<void> _checkInitialConnectivity() async {
    final connected = await _connectivityService.isConnected;
    if (!mounted) return;
    setState(() => _isConnected = connected);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final connected = result != ConnectivityResult.none;
    if (connected != _isConnected && mounted) {
      setState(() => _isConnected = connected);
    }
  }

  Future<void> _retryConnection() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final connected = await _connectivityService.isConnected;
      if (mounted) setState(() => _isConnected = connected);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        if (!_isConnected)
          Positioned.fill(
            child: NoConnectionScreen(
              isRetrying: _checking,
              onRetry: _retryConnection,
            ),
          ),
      ],
    );
  }
}
