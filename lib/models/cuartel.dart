import 'package:google_maps_flutter/google_maps_flutter.dart';

class Cuartel {
  final String id;
  final String nombre;
  final String cultivo;
  final String variedad;
  final List<LatLng> puntos;

  Cuartel({
    required this.id,
    required this.nombre,
    required this.cultivo,
    required this.variedad,
    required this.puntos,
  });

  factory Cuartel.fromFirestore(String id, Map<String, dynamic> data) {
    return Cuartel(
      id: id,
      nombre: data['nombre'] ?? '',
      cultivo: data['cultivo'] ?? '',
      variedad: data['variedad'] ?? '',
      puntos: (data['puntos'] as List)
          .map(
            (p) => LatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
