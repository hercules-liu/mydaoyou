import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scenic_spot.dart';
import '../models/chat_message.dart';

class CacheService {
  static const String _spotsKey = 'cached_spots';
  static const String _footprintsKey = 'footprints';
  static const String _favoritesKey = 'favorites';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  Future<void> cacheSpots(List<ScenicSpot> spots) async {
    await init();
    final jsonList = spots.map((s) => s.toJson()).toList();
    await _prefs.setString(_spotsKey, jsonEncode(jsonList));
  }

  Future<List<ScenicSpot>> getCachedSpots() async {
    await init();
    final jsonString = _prefs.getString(_spotsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ScenicSpot.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveFootprints(List<Footprint> footprints) async {
    await init();
    final jsonList = footprints.map((f) => f.toJson()).toList();
    await _prefs.setString(_footprintsKey, jsonEncode(jsonList));
  }

  Future<List<Footprint>> getFootprints() async {
    await init();
    final jsonString = _prefs.getString(_footprintsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Footprint.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addFootprint(Footprint footprint) async {
    final footprints = await getFootprints();
    final existingIndex = footprints.indexWhere((f) => f.spotId == footprint.spotId);

    if (existingIndex >= 0) {
      footprints[existingIndex] = footprint;
    } else {
      footprints.add(footprint);
    }

    await saveFootprints(footprints);
  }

  Future<void> saveFavorites(List<String> spotIds) async {
    await init();
    await _prefs.setStringList(_favoritesKey, spotIds);
  }

  Future<List<String>> getFavorites() async {
    await init();
    return _prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> addFavorite(String spotId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(spotId)) {
      favorites.add(spotId);
      await saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String spotId) async {
    final favorites = await getFavorites();
    favorites.remove(spotId);
    await saveFavorites(favorites);
  }

  Future<bool> isFavorite(String spotId) async {
    final favorites = await getFavorites();
    return favorites.contains(spotId);
  }

  Future<void> clearAll() async {
    await init();
    await _prefs.clear();
  }
}