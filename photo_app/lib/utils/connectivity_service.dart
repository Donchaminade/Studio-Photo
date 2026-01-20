import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late Stream<ConnectivityResult> _connectivityStream;

  ConnectivityService() {
    _connectivityStream = _connectivity.onConnectivityChanged;
  }

  Stream<ConnectivityResult> get connectivityStream => _connectivityStream;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
