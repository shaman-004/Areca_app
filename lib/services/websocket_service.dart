import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final String _url = "ws://10.0.2.2:8000/ws"; // Replace with your backend WebSocket URL
  WebSocketChannel? _channel;
  bool _isConnected = false;
  StreamSubscription? _subscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect({int retryAttempts = 3}) async {
    if (_isConnected) return;

    for (int attempt = 1; attempt <= retryAttempts; attempt++) {
      try {
        print('Attempting WebSocket connection to $_url (Attempt $attempt/$retryAttempts)');
        _channel = WebSocketChannel.connect(Uri.parse(_url));
        _isConnected = true;
        print('WebSocket connected successfully');

        _subscription = _channel!.stream.listen(
          (message) {
            try {
              final data = jsonDecode(message);
              print('Received WebSocket message: $data');
              _messageController.add(data);
            } catch (e) {
              print('Error processing WebSocket message: $e');
            }
          },
          onError: (error) {
            print('WebSocket error: $error');
            _isConnected = false;
          },
          onDone: () {
            print('WebSocket connection closed');
            _isConnected = false;
          },
        );
        break; // Exit retry loop on successful connection
      } catch (e) {
        _isConnected = false;
        print('WebSocket connection failed: $e');
        if (attempt == retryAttempts) {
          throw Exception('Failed to connect to WebSocket after $retryAttempts attempts: $e');
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void listen(Function(Map<String, dynamic>) onMessage) {
    if (!isConnected) {
      throw Exception('WebSocket not connected. Call connect() first.');
    }
    messageStream.listen(onMessage);
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
    print('WebSocket disconnected');
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }
}
