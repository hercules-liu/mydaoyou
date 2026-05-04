import '../models/scenic_spot.dart';

class RouteService {
  Future<List<RouteNode>> calculateRoute(
    List<ScenicSpot> spots,
    Map<String, double> currentLocation,
  ) async {
    if (spots.isEmpty) return [];

    final sortedSpots = List<ScenicSpot>.from(spots);
    sortedSpots.sort((a, b) {
      final distA = _distance(
        currentLocation['latitude']!,
        currentLocation['longitude']!,
        a.latitude,
        a.longitude,
      );
      final distB = _distance(
        currentLocation['latitude']!,
        currentLocation['longitude']!,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });

    final route = <RouteNode>[];
    double totalTime = 0;
    double totalDistance = 0;

    for (int i = 0; i < sortedSpots.length; i++) {
      final spot = sortedSpots[i];
      double distance;
      double walkingTime;

      if (i == 0) {
        distance = _distance(
          currentLocation['latitude']!,
          currentLocation['longitude']!,
          spot.latitude,
          spot.longitude,
        );
      } else {
        final prevSpot = sortedSpots[i - 1];
        distance = _distance(
          prevSpot.latitude,
          prevSpot.longitude,
          spot.latitude,
          spot.longitude,
        );
      }

      walkingTime = distance / 80 * 60;

      if (i > 0) {
        totalDistance += distance;
      }

      route.add(RouteNode(
        spot: spot,
        order: i + 1,
        walkingDistance: distance,
        walkingTime: walkingTime,
        visitTime: totalTime + walkingTime,
      ));

      totalTime += walkingTime + spot.suggestedDuration;
    }

    return route;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
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

class RouteNode {
  final ScenicSpot spot;
  final int order;
  final double walkingDistance;
  final double walkingTime;
  final double visitTime;

  const RouteNode({
    required this.spot,
    required this.order,
    required this.walkingDistance,
    required this.walkingTime,
    required this.visitTime,
  });

  String get formattedWalkingDistance {
    if (walkingDistance < 1000) {
      return '${walkingDistance.toInt()}米';
    } else {
      return '${(walkingDistance / 1000).toStringAsFixed(1)}公里';
    }
  }

  String get formattedWalkingTime {
    if (walkingTime < 1) {
      return '${walkingTime.toInt()}分钟';
    } else {
      return '${(walkingTime / 60).toStringAsFixed(1)}小时';
    }
  }
}