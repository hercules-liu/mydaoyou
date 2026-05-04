import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend.dart';
import 'cache_service.dart';

class FriendService {
  final CacheService _cacheService = CacheService();
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com');

  final List<Friend> _friends = [];
  List<Friend> get friends => List.unmodifiable(_friends);

  Future<void> init() async {
    await _cacheService.init();
    await _loadFriends();
  }

  Future<void> _loadFriends() async {
    _friends.clear();
    _friends.addAll(_getMockFriends());
  }

  List<Friend> _getMockFriends() {
    return [
      Friend(
        id: 'user_001',
        name: '张三',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=ZhangSan',
        currentLocation: {'latitude': 39.9165, 'longitude': 116.3972},
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Friend(
        id: 'user_002',
        name: '李四',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=LiSi',
        currentLocation: {'latitude': 39.9170, 'longitude': 116.3980},
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Friend(
        id: 'user_003',
        name: '王五',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=WangWu',
        currentLocation: null,
        lastUpdate: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  Future<List<Friend>> getFriends() async {
    return _friends;
  }

  Future<Friend?> getFriendById(String id) async {
    try {
      return _friends.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  double? getDistanceToFriend(Friend friend, double userLat, double userLng) {
    if (friend.currentLocation == null) return null;

    final friendLat = friend.currentLocation!['latitude'];
    final friendLng = friend.currentLocation!['longitude'];
    if (friendLat == null || friendLng == null) return null;

    return _calculateDistance(userLat, userLng, friendLat, friendLng);
  }

  Future<void> updateMyLocation(double lat, double lng) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Location update failed, will retry later
    }
  }

  Future<Friend> addFriend(String userId, String userName) async {
    final friend = Friend(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: userName,
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=$userName',
      lastUpdate: DateTime.now(),
    );
    _friends.add(friend);
    return friend;
  }

  Future<void> removeFriend(String friendId) async {
    _friends.removeWhere((f) => f.id == friendId);
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * 3.14159265359 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approxAtan2(y, x);

  double _taylorSin(double x) {
    x = x % (2 * 3.14159265359);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    x = x % (2 * 3.14159265359);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approxAtan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return 3.14159265359 / 2;
      if (y < 0) return -3.14159265359 / 2;
      return 0;
    }
    double atan = _approxAtan(y / x);
    if (x < 0) {
      if (y >= 0) return atan + 3.14159265359;
      return atan - 3.14159265359;
    }
    return atan;
  }

  double _approxAtan(double x) {
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }
}