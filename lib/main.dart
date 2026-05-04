import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'services/location_service.dart';
import 'services/tts_service.dart';
import 'services/stt_service.dart';

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
      },
        LocationService(),
        TtsService(),
        SttService(),
      ],
    );
  }
}