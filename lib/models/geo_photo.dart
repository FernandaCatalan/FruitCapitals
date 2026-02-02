class GeoPhoto {
  final String path;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GeoPhoto({
    required this.path,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
