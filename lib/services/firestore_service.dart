import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cuartel.dart';
import '../models/observation.dart';
import '../models/entrega.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _collectionCuarteles = 'cuarteles';
  final String _collectionObservaciones = 'observaciones';
  final String _collectionEntregas = 'entregas';

  Stream<List<Cuartel>> getCuarteles() {
    return _db.collection(_collectionCuarteles).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Cuartel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> saveCuartel({
    required String nombre,
    required String cultivo,
    required String variedad,
    required List<LatLng> puntos,
  }) async {
    await _db.collection(_collectionCuarteles).add({
      'nombre': nombre,
      'cultivo': cultivo,
      'variedad': variedad,
      'puntos': puntos
          .map((p) => {
                'lat': p.latitude,
                'lng': p.longitude,
              })
          .toList(),
    });
  }

  Future<void> updateCuartel({
    required String id,
    required String nombre,
    required String cultivo,
    required String variedad,
  }) async {
    await _db.collection(_collectionCuarteles).doc(id).update({
      'nombre': nombre,
      'cultivo': cultivo,
      'variedad': variedad,
    });
  }

  Future<void> deleteCuartel(String id) async {
    await _db.collection(_collectionCuarteles).doc(id).delete();
  }

  Future<void> saveObservacion({
    required String texto,
    required LatLng posicion,
    required String uid,
    required List<String> photoPaths,
    required DateTime createdAt,
    String? cuartelId,
    String? cuartelNombre,
    String? hileraId,
    int? numeroHilera,
    String? mataId,
    int? numeroMata,
    String? tipo,
    String? etapa,
    int? conteo,
  }) async {
    await _db.collection(_collectionObservaciones).add({
      'description': texto,

      'lat': posicion.latitude,
      'lng': posicion.longitude,

      'uid': uid,

      'cuartelId': cuartelId,
      'cuartelNombre': cuartelNombre,
      'hileraId': hileraId,
      'numeroHilera': numeroHilera,
      'mataId': mataId,
      'numeroMata': numeroMata,

      'tipo': tipo,
      'etapa': etapa,
      'conteo': conteo,

      'photoPaths': photoPaths,

      'createdAt': Timestamp.fromDate(createdAt),

      'isSynced': true,
    });
  }

  Stream<List<Observation>> getObservaciones() {
    return _db.collection(_collectionObservaciones).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Observation.fromFirestore(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> deleteObservacion(String id) async {
    await _db.collection(_collectionObservaciones).doc(id).delete();
  }

  Stream<List<Observation>> getObservacionesPorCuartel(String cuartelId) {
    return _db
        .collection(_collectionObservaciones)
        .where('cuartelId', isEqualTo: cuartelId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Observation.fromFirestore(doc.id, doc.data()))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> saveEntrega(Map<String, dynamic> data) {
    return _db
        .collection(_collectionEntregas)
        .doc(data['id'])
        .set(data);
  }

  Stream<List<Entrega>> getEntregas() {
    return _db.collection(_collectionEntregas).snapshots().map(
          (snap) =>
              snap.docs.map((d) => Entrega.fromMap(d.data())).toList(),
        );
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'empleado';
  }
}
