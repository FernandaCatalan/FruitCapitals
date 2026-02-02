import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> sortPointsClockwise(List<LatLng> points) {
  final centerLat =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final centerLng =
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

  points.sort((a, b) {
    final angleA =
        atan2(a.latitude - centerLat, a.longitude - centerLng);
    final angleB =
        atan2(b.latitude - centerLat, b.longitude - centerLng);
    return angleA.compareTo(angleB);
  });

  return points;
}

bool isPointInsidePolygon(
  LatLng point,
  List<LatLng> polygon,
) {
  bool inside = false;

  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].latitude;
    final yi = polygon[i].longitude;
    final xj = polygon[j].latitude;
    final yj = polygon[j].longitude;

    final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
        (point.latitude <
            (xj - xi) *
                    (point.longitude - yi) /
                    (yj - yi + 0.0) +
                xi);

    if (intersect) inside = !inside;
  }

  return inside;
}
