import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/chat_page.dart';
import 'pages/friends_page.dart';
import 'pages/comments_page.dart';
import 'pages/route_page.dart';
import 'pages/footprint_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const YouBanApp());
}

class YouBanApp extends StatelessWidget {
  const YouBanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '游伴',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/camera': (context) => const CameraPage(),
        '/chat': (context) => const ChatPage(),
        '/friends': (context) => const FriendsPage(),
        '/comments': (context) => const CommentsPage(),
        '/route': (context) => const RoutePage(),
        '/footprint': (context) => const FootprintPage(),
      },
    );
  }
}