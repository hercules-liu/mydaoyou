import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/scenic_spot.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Map<String, double>>.broadcast();

  Map<String, double>? _lastLocation;
  Map<String, double>? get lastLocation => _lastLocation;

  Stream<Map<String, double>> get locationStream => _locationController.stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Map<String, double>?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _lastLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      return _lastLocation;
    } catch (e) {
      return null;
    }
  }

  void startTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        _lastLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _locationController.add(_lastLocation!);
      },
      onError: (e) {},
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
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
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}