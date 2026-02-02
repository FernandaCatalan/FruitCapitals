import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/observation.dart';
import 'cloudinary_service.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'local_db_service.dart';
import '../models/cuartel.dart';


class ObservationRepository {
  final _localDb = LocalDBService();
  final _firestore = FirestoreService();
  final _connectivity = ConnectivityService();
  final _cloudinary = CloudinaryService();

    bool _isPointInsidePolygon(
    LatLng point,
    List<LatLng> polygon,
  ) {
    int intersectCount = 0;

    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      if (_rayCastIntersect(point, p1, p2)) {
        intersectCount++;
      }
    }

    return intersectCount % 2 == 1;
  }

  bool _rayCastIntersect(
    LatLng point,
    LatLng p1,
    LatLng p2,
  ) {
    final double aY = p1.latitude;
    final double bY = p2.latitude;
    final double aX = p1.longitude;
    final double bX = p2.longitude;
    final double pY = point.latitude;
    final double pX = point.longitude;

    if ((aY > pY && bY > pY) ||
        (aY < pY && bY < pY) ||
        (aX < pX && bX < pX)) {
      return false;
    }

    final double m = (aY - bY) / (aX - bX);
    final double bee = -aX * m + aY;
    final double x = (pY - bee) / m;

    return x > pX;
  }


  Future<void> syncObservations() async {
    final hasInternet = await _connectivity.hasConnection();
    if (!hasInternet) return;

    final db = await LocalDBService.database;

    final pending = await db.query(
      'observations',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    if (pending.isEmpty) return;

    for (final row in pending) {
      try {
        final List<String> localPhotos =
            (row['photoPaths'] as String).split('|');

        final List<String> uploadedPhotos = [];

        for (final path in localPhotos) {
          final file = File(path);
          if (!file.existsSync()) continue;

          final url = await _cloudinary.uploadImage(file);
          uploadedPhotos.add(url);
        }

        final numeroHilera = row['numeroHilera'];
        final numeroMata = row['numeroMata'];
        final conteo = row['conteo'];

        await _firestore.saveObservacion(
          texto: row['description'] as String,
          posicion: LatLng(
            row['latitude'] as double,
            row['longitude'] as double,
          ),
          uid: row['uid'] as String,
          photoPaths: uploadedPhotos, createdAt: DateTime.parse(row['createdAt'] as String),
          cuartelId: row['cuartelId'] as String?,
          cuartelNombre: row['cuartelNombre'] as String?,
          hileraId: row['hileraId'] as String?,
          numeroHilera: (numeroHilera is num)
              ? numeroHilera.toInt()
              : int.tryParse('$numeroHilera'),
          mataId: row['mataId'] as String?,
          numeroMata: (numeroMata is num)
              ? numeroMata.toInt()
              : int.tryParse('$numeroMata'),
          tipo: row['tipo'] as String?,
          etapa: row['etapa'] as String?,
          conteo: (conteo is num) ? conteo.toInt() : int.tryParse('$conteo'),
        );

        await db.update(
          'observations',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        print('Error sincronizando observación: $e');
      }
    }
  }

  Future<void> saveObservation(Observation obs) async {
    final hasInternet = await _connectivity.hasConnection();

    if (hasInternet) {
      await _firestore.saveObservacion(
        texto: obs.description,
        posicion: LatLng(obs.latitude ?? 0.0, obs.longitude ?? 0.0),
        uid: obs.uid,
        photoPaths: obs.photoPaths, createdAt: obs.createdAt,
        cuartelId: obs.cuartelId,
        cuartelNombre: obs.cuartelNombre,
        hileraId: obs.hileraId,
        numeroHilera: obs.numeroHilera,
        mataId: obs.mataId,
        numeroMata: obs.numeroMata,
        tipo: obs.tipo,
        etapa: obs.etapa,
        conteo: obs.conteo,
      );
    } else {
      final db = await LocalDBService.database;

      await db.insert(
        'observations',
        {
          'id': obs.id,
          'uid': obs.uid,
          'description': obs.description,
          'latitude': obs.latitude ?? 0.0,
          'longitude': obs.longitude ?? 0.0,
          'createdAt': obs.createdAt.toIso8601String(),
          'photoPaths': obs.photoPaths.join('|'),
          'isSynced': 0,
          'cuartelId': obs.cuartelId,
          'cuartelNombre': obs.cuartelNombre,
          'hileraId': obs.hileraId,
          'numeroHilera': obs.numeroHilera,
          'mataId': obs.mataId,
          'numeroMata': obs.numeroMata,
          'tipo': obs.tipo,
          'etapa': obs.etapa,
          'conteo': obs.conteo,
        },
      );
    }
  }

  Future<Cuartel?> findCuartelForLocation(
    double lat,
    double lng,
  ) async {
    final cuarteles = await _firestore.getCuarteles().first;

    for (final cuartel in cuarteles) {
      if (_isPointInsidePolygon(
        LatLng(lat, lng),
        cuartel.puntos,
      )) {
        return cuartel;
      }
    }

    return null;
  }
}
