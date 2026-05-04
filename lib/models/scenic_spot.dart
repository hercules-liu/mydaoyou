class ScenicSpot {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double radius;
  final List<String> tags;
  final Map<String, String> audioFiles;
  final int suggestedDuration;

  const ScenicSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.tags = const [],
    this.audioFiles = const {},
    this.suggestedDuration = 3600,
  });

  factory ScenicSpot.fromJson(Map<String, dynamic> json) {
    return ScenicSpot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 100.0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      audioFiles: (json['audio_files'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      suggestedDuration: (json['suggested_duration'] as int?) ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'tags': tags,
      'audio_files': audioFiles,
      'suggested_duration': suggestedDuration,
    };
  }

  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371000;
    final double dLat = _toRad(lat - latitude);
    final double dLng = _toRad(lng - longitude);
    final double a = 
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(latitude)) * _cos(_toRad(lat)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  bool isWithinRange(double lat, double lng) {
    return distanceTo(lat, lng) <= radius;
  }

  static double _toRad(double deg) => deg * 3.14159265359 / 180;
  static double _sin(double x) => _taylorSin(x);
  static double _cos(double x) => _taylorCos(x);
  static double _sqrt(double x) => _newtonSqrt(x);
  static double _atan2(double y, double x) => _approxAtan2(y, x);

  static double _taylorSin(double x) {
    x = x % (2 * 3.14159265359);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _taylorCos(double x) {
    x = x % (2 * 3.14159265359);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _approxAtan2(double y, double x) {
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

  static double _approxAtan(double x) {
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }
}