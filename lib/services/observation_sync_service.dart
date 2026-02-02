import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/observation.dart';
import 'local_db_service.dart';
import 'firestore_service.dart';
import 'cloudinary_service.dart';

class ObservationSyncService {
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();

  Future<void> syncPendingObservations() async {
    final db = await LocalDBService.database;

    final List<Map<String, dynamic>> pending = await db.query(
      'observations',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    for (final row in pending) {
      try {
        final obs = Observation(
          id: row['id'],
          uid: row['uid'],
          description: row['description'],
          latitude: row['latitude'],
          longitude: row['longitude'],
          createdAt: DateTime.parse(row['createdAt']),
          photoPaths: row['photoPaths'].split('|'),
          isSynced: false, tipo: '', conteo: null, etapa: '',
        );

        List<String> uploadedPhotos = [];

        for (final path in obs.photoPaths) {
          if (path.startsWith('http')) {
            uploadedPhotos.add(path);
          } else {
            final url = await _cloudinary.uploadImage(File(path));
            uploadedPhotos.add(url);
          }
        }

        await _firestore.saveObservacion(
          texto: obs.description,
          posicion: LatLng(obs.latitude, obs.longitude),
          uid: obs.uid,
          photoPaths: uploadedPhotos, createdAt: obs.createdAt,
        );

        await db.update(
          'observations',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [obs.id],
        );
      } catch (e) {
        print('Error sincronizando observación ${row['id']}: $e');
      }
    }
  }
}
