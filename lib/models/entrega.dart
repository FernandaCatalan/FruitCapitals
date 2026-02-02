import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Entrega {
  final String id;
  final String cuartelId;
  final String cuartelNombre;
  final int hilera;
  final double cantidad;
  final double lat;
  final double lng;
  final DateTime fecha;

  Entrega({
    required this.id,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hilera,
    required this.cantidad,
    required this.lat,
    required this.lng,
    required this.fecha,
  });

  factory Entrega.fromMap(Map<String, dynamic> data) {
    return Entrega(
      id: data['id'],
      cuartelId: data['cuartelId'],
      cuartelNombre: data['cuartelNombre'],
      hilera: data['hilera'] ?? 1, 
      cantidad: (data['cantidad'] as num).toDouble(),
      lat: (data['latitude'] as num).toDouble(),
      lng: (data['longitude'] as num).toDouble(),
      fecha: data['fecha'] != null
        ? DateTime.parse(data['fecha'])
        : DateTime.now(),
    );
  }
}


