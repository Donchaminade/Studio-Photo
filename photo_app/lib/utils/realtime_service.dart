import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class RealtimeService {
  final String _wsUrl;
  final Function(String type) onNotification;
  StompClient? _client;

  RealtimeService({required String wsUrl, required this.onNotification})
      : _wsUrl = wsUrl;

  void connect() {
    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => print('WebSocket Error: $error'),
        onStompError: (StompFrame frame) => print('STOMP Error: ${frame.body}'),
        onDisconnect: (StompFrame frame) => print('Disconnected'),
        // In development, you might need to bypass host validation or use correct URL
      ),
    );
    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    print('Connected to WebSocket');
    _client?.subscribe(
      destination: '/topic/sync',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          final type = data['type'] as String;
          onNotification(type);
        }
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
  }
}
