import 'package:cloud_firestore/cloud_firestore.dart';

class Observation {
  final String id;
  final String uid;

  final String description;

  final double latitude;
  final double longitude;

  final DateTime createdAt;
  final bool isSynced;

  final List<String> photoPaths;

  final String? cuartelId;
  final String? cuartelNombre;
  final String? hileraId;
  final int? numeroHilera;
  final String? mataId;
  final int? numeroMata;

  final String? tipo;   // ej: 'floracion'
  final String? etapa;  // 'dardos' | 'flores' | 'frutos'
  final int? conteo;    // número ingresado

  Observation({
    required this.id,
    required this.uid,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.isSynced,
    required this.photoPaths,
    this.cuartelId,
    this.cuartelNombre,
    this.hileraId,
    this.numeroHilera,
    this.mataId,
    this.numeroMata,
    this.tipo,
    this.etapa,
    this.conteo,
  });

  factory Observation.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    List<String> parsePhotos(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Observation(
      id: id,
      uid: (data['uid'] ?? '').toString(),
      description: (data['description'] ?? data['texto'] ?? '').toString(),
      latitude: parseDouble(data['latitude'] ?? data['lat']),
      longitude: parseDouble(data['longitude'] ?? data['lng']),
      createdAt: parseDate(data['createdAt'] ?? data['fecha']),
      isSynced: (data['isSynced'] ?? true) == true,
      photoPaths: parsePhotos(data['photoPaths'] ?? data['photos']),
      cuartelId: data['cuartelId']?.toString(),
      cuartelNombre: data['cuartelNombre']?.toString(),
      hileraId: data['hileraId']?.toString(),
      numeroHilera: (data['numeroHilera'] is num)
          ? (data['numeroHilera'] as num).toInt()
          : int.tryParse('${data['numeroHilera']}'),
      mataId: data['mataId']?.toString(),
      numeroMata: (data['numeroMata'] is num)
          ? (data['numeroMata'] as num).toInt()
          : int.tryParse('${data['numeroMata']}'),
      tipo: data['tipo']?.toString(),
      etapa: data['etapa']?.toString(),
      conteo: (data['conteo'] is num) ? (data['conteo'] as num).toInt() : int.tryParse('${data['conteo']}'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'description': description,

      'latitude': latitude,
      'longitude': longitude,

      'createdAt': Timestamp.fromDate(createdAt),
      'isSynced': isSynced,
      'photoPaths': photoPaths,

      'cuartelId': cuartelId,
      'cuartelNombre': cuartelNombre,
      'hileraId': hileraId,
      'numeroHilera': numeroHilera,
      'mataId': mataId,
      'numeroMata': numeroMata,

      'tipo': tipo,
      'etapa': etapa,
      'conteo': conteo,
    };
  }
}
