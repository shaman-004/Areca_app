import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'services/websocket_service.dart';
import 'pages/login_page.dart';
import 'pages/notification_page.dart';
import 'pages/upload_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      await _webSocketService.connect();
    } catch (e) {
      Logger('MyApp').severe('Failed to initialize WebSocket connection: $e');
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farm App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/upload': (context) => const UploadPage(),
        '/notifications': (context) => const NotificationPage(),
      },
    );
  }
}
