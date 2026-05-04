import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/stt_service.dart';
import '../models/scenic_spot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  bool _isLoading = true;
  bool _isSpeaking = false;
  bool _isListening = false;
  String? _currentSpotId;
  List<ScenicSpot> _nearbySpots = [];
  ScenicSpot? _currentSpot;
  String _statusText = '正在获取位置...';

  @override
  void initState() {
    super.initState();
    _initServices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initServices() async {
    await _ttsService.init();
    await _sttService.init();

    _ttsService.stateStream.listen((state) {
      if (mounted) setState(() => _isSpeaking = state == TtsState.playing);
    });

    _sttService.isListeningStream.listen((isListening) {
      if (mounted) setState(() => _isListening = isListening);
    });

    _sttService.onResult.listen((text) {
      if (text.isNotEmpty) _handleVoiceInput(text);
    });

    _locationService.locationStream.listen((position) {
      _checkNearbySpots(position.latitude, position.longitude);
    });

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      await _checkNearbySpots(position.latitude, position.longitude);
    } else {
      setState(() {
        _isLoading = false;
        _statusText = '无法获取位置，请开启定位权限';
      });
    }
  }

  Future<void> _checkNearbySpots(double lat, double lng) async {
    setState(() => _statusText = '搜索附近景点...');
    final spots = await _apiService.getNearbySpots(lat, lng);
    final nearest = _locationService.findNearbySpot(spots, lat, lng);

    setState(() {
      _isLoading = false;
      _nearbySpots = spots;
      _currentSpot = nearest;
      _currentSpotId = nearest?.id;
      _statusText = nearest != null 
          ? '已到达: ${nearest.name}' 
          : '附近暂无景点';
    });

    if (nearest != null && nearest!.id != _currentSpotId) {
      _currentSpotId = nearest!.id;
      _speakSpotIntro(nearest);
    }
  }

  void _speakSpotIntro(ScenicSpot spot) {
    final intro = '${spot.name}。${spot.description}';
    _ttsService.speak(intro);
  }

  void _handleVoiceInput(String text) {
    if (text.contains('讲解') || text.contains('介绍')) {
      if (_currentSpot != null) {
        _speakSpotIntro(_currentSpot!);
      }
    } else if (text.contains('停止') || text.contains('暂停')) {
      _ttsService.stop();
    } else {
      _handleChat(text);
    }
  }

  Future<void> _handleChat(String message) async {
    final reply = await _apiService.sendChatMessage(message, currentSpot: _currentSpot);
    _ttsService.speak(reply);
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _sttService.stopListening();
    } else {
      await _sttService.startListening();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildVoiceButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.tour,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '游伴',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '您的私人语音导游',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_currentSpot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('拍照识别景点'),
            ),
          ],
        ),
      );
    }

    return _buildSpotCard();
  }

  Widget _buildSpotCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Text(
                  _currentSpot!.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _currentSpot!.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue[50],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentSpot!.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _ttsService.stop(),
                      icon: const Icon(Icons.stop),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _speakSpotIntro(_currentSpot!),
                        icon: Icon(
                          _isSpeaking ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        iconSize: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('拍照识别其他景点'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: GestureDetector(
        onTap: _toggleVoiceInput,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Theme.of(context).primaryColor)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}