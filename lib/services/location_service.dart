import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/scenic_spot.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Position>.broadcast();
  Position? _lastPosition;

  Stream<Position> get locationStream => _locationController.stream;
  Position? get lastPosition => _lastPosition;

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

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _lastPosition;
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
        _lastPosition = position;
        _locationController.add(position);
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