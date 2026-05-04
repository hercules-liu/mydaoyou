import 'dart:async';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:flutter/services.dart';
import '../models/scenic_spot.dart';

class LocationService {
  static const String _amapApiKey = String.fromEnvironment('AMAP_API_KEY', defaultValue: '');

  final AMapFlutterLocation _locationClient = AMapFlutterLocation();
  StreamSubscription<Map<String, Object>>? _locationSubscription;
  final _locationController = StreamController<Map<String, double>>.broadcast();

  Map<String, double>? _lastLocation;
  Map<String, double>? get lastLocation => _lastLocation;

  Stream<Map<String, double>> get locationStream => _locationController.stream;

  Future<bool> requestPermission() async {
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);

    try {
      final result = await _locationClient.requestLocationPermission();
      return result == 'true' || result == '1';
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, double>?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    AMapFlutterLocation.setApiKey(_amapApiKey, _amapApiKey);

    try {
      final result = await _locationClient.getLocationStream([
        AMapLocationAccuracyRule.HIGH,
      ]).first.timeout(const Duration(seconds: 10));

      if (result != null && result.isNotEmpty) {
        final lat = result['latitude'] as double?;
        final lng = result['longitude'] as double?;
        if (lat != null && lng != null) {
          _lastLocation = {'latitude': lat, 'longitude': lng};
          return _lastLocation;
        }
      }
    } catch (e) {
      // Location failed
    }
    return null;
  }

  void startTracking() {
    _locationSubscription?.cancel();

    AMapFlutterLocation.setApiKey(_amapApiKey, _amapApiKey);

    _locationClient.startLocation();
    _locationSubscription = _locationClient.onLocationChanged().listen(
      (location) {
        if (location != null && location.isNotEmpty) {
          final lat = location['latitude'] as double?;
          final lng = location['longitude'] as double?;
          if (lat != null && lng != null) {
            _lastLocation = {'latitude': lat, 'longitude': lng};
            _locationController.add(_lastLocation!);
          }
        }
      },
      onError: (e) {},
    );
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationClient.stopLocation();
  }

  ScenicSpot? findNearbySpot(List<ScenicSpot> spots, double lat, double lng, {double maxDistance = 500}) {
    ScenicSpot? nearest;
    double minDistance = maxDistance;

    for (final spot in spots) {
      final distance = spot.distanceTo(lat, lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = spot;
      }
    }

    return nearest;
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return _haversineDistance(lat1, lng1, lat2, lng2);
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
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

  void dispose() {
    stopTracking();
    _locationController.close();
    _locationClient.destroy();
  }
}

class AMapLocationAccuracyRule {
  static const String HIGH = 'high';
  static const String LOW = 'low';
  static const String MEDIUM = 'medium';
}