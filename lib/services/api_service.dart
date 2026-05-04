import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scenic_spot.dart';
import '../models/chat_message.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com');
  static const String _apiKey = String.fromEnvironment('API_KEY', defaultValue: '');

  final http.Client _client = http.Client();

  Future<List<ScenicSpot>> getNearbySpots(double lat, double lng, {double radius = 5000}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/spots/nearby?lat=$lat&lng=$lng&radius=$radius'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ScenicSpot.fromJson(json)).toList();
      }
    } catch (e) {
      // Return local data on error
    }
    return _getLocalSpots();
  }

  Future<ScenicSpot?> getSpotDetail(String spotId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/spots/$spotId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ScenicSpot.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // Return local data on error
    }
    return null;
  }

  Future<String> sendChatMessage(String message, {ScenicSpot? currentSpot}) async {
    try {
      final body = {
        'message': message,
        'context': currentSpot != null ? {
          'spot_id': currentSpot.id,
          'spot_name': currentSpot.name,
        } : null,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String;
      }
    } catch (e) {
      // Return fallback response
    }
    return '抱歉，我现在无法回答您的问题，请稍后再试。';
  }

  Future<List<ScenicSpot>> searchSpots(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/spots/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ScenicSpot.fromJson(json)).toList();
      }
    } catch (e) {
      // Return local data on error
    }
    return [];
  }

  List<ScenicSpot> _getLocalSpots() {
    return [
      const ScenicSpot(
        id: '1',
        name: '故宫',
        description: '故宫又名紫禁城，是中国古代宫廷建筑的精华，是世界上规模最大、保存最完整的木质结构古建筑群。',
        imageUrl: 'https://example.com/gugong.jpg',
        latitude: 39.9163,
        longitude: 116.3972,
        radius: 500,
        tags: ['皇宫', '明清', '世界遗产'],
      ),
      const ScenicSpot(
        id: '2',
        name: '天安门广场',
        description: '天安门广场是世界上最大的城市广场之一，位于北京市中心，可容纳100万人。',
        imageUrl: 'https://example.com/tiananmen.jpg',
        latitude: 39.9073,
        longitude: 116.3972,
        radius: 300,
        tags: ['广场', '地标'],
      ),
      const ScenicSpot(
        id: '3',
        name: '长城',
        description: '长城是中国古代的军事防御工程，是世界七大奇迹之一。',
        imageUrl: 'https://example.com/greatwall.jpg',
        latitude: 40.4319,
        longitude: 116.5704,
        radius: 1000,
        tags: ['古迹', '世界遗产', '军事'],
      ),
    ];
  }

  void dispose() {
    _client.close();
  }
}