import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/dardo.dart';
import '../models/conteoflores.dart';
import '../models/frutoflor.dart';

class FloracionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();


  CollectionReference<Map<String, dynamic>> _dardosRef({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) {
    return _db
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .doc(hileraId)
        .collection('matas')
        .doc(mataId)
        .collection('dardos');
  }

  CollectionReference<Map<String, dynamic>> _conteoFloresRef({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) {
    return _dardosRef(cuartelId: cuartelId, hileraId: hileraId, mataId: mataId)
        .doc(dardoId)
        .collection('conteo_flores');
  }

  CollectionReference<Map<String, dynamic>> _conteoDardosRef({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) {
    return _db
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .doc(hileraId)
        .collection('matas')
        .doc(mataId)
        .collection('conteo_dardos');
  }

  CollectionReference<Map<String, dynamic>> _frutosPorFlorRef({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) {
    return _dardosRef(cuartelId: cuartelId, hileraId: hileraId, mataId: mataId)
        .doc(dardoId)
        .collection('frutos_por_flor');
  }


  Future<void> crearDardo({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required int numero,
    required String uid,
  }) async {
    final existe = await existeDardoEnMata(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      numero: numero,
    );
    if (existe) {
      throw Exception('Ya existe un dardo #$numero en esta mata');
    }

    final id = _uuid.v4();

    await _dardosRef(cuartelId: cuartelId, hileraId: hileraId, mataId: mataId)
        .doc(id)
        .set({
      'numero': numero,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': uid,
    });
  }

  Stream<List<Dardo>> getDardos({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) {
    return _dardosRef(cuartelId: cuartelId, hileraId: hileraId, mataId: mataId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Dardo.fromFirestore(d.id, d.data())).toList();
      list.sort((a, b) => a.numero.compareTo(b.numero));
      return list;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDardosPorMataQuery({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) {
    return _dardosRef(cuartelId: cuartelId, hileraId: hileraId, mataId: mataId)
        .orderBy('numero')
        .snapshots();
  }

  Future<bool> existeDardoEnMata({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required int numero,
  }) async {
    final q = await _dardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).where('numero', isEqualTo: numero).limit(1).get();

    return q.docs.isNotEmpty;
  }


  Future<void> registrarConteoFlores({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
    required int totalFlores,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();

    final data = {
      'totalFlores': totalFlores,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    await _conteoFloresRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    ).doc(id).set(data);
  }

  Future<void> registrarFlores({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
    required int cantidadFlores,
    required String uid,
    double? lat,
    double? lng,
  }) {
    return registrarConteoFlores(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
      totalFlores: cantidadFlores,
      uid: uid,
      lat: lat,
      lng: lng,
    );
  }

  Stream<List<ConteoFlores>> getConteosFlores({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) {
    return _conteoFloresRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    ).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => ConteoFlores.fromFirestore(d.id, d.data())).toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  Stream<int?> getTotalFloresActual({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) {
    return _conteoFloresRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    )
        .orderBy('fecha', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      return (data['totalFlores'] as num?)?.toInt();
    });
  }

  Future<int?> getUltimoTotalFlores({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) async {
    final snap = await _conteoFloresRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    ).orderBy('fecha', descending: true).limit(1).get();

    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();
    return (data['totalFlores'] as num?)?.toInt();
  }


  Future<void> registrarFrutosPorFlor({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
    required int florNumero, // número de flor (1..N)
    required int cantidadFrutos,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();

    final data = {
      'florNumero': florNumero,
      'indiceFlor': florNumero, // lo guardo también por compatibilidad
      'cantidadFrutos': cantidadFrutos,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    await _frutosPorFlorRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    ).doc(id).set(data);
  }

  Future<void> registrarConteoDardos({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required int cantidadDardos,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();

    final data = {
      'cantidadDardos': cantidadDardos,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    final dardosSnap = await _dardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).get();

    final existing = <int>{};
    for (final d in dardosSnap.docs) {
      final numero = d.data()['numero'];
      if (numero is int) {
        existing.add(numero);
      } else if (numero is num) {
        existing.add(numero.toInt());
      }
    }

    final batch = _db.batch();

    for (int i = 1; i <= cantidadDardos; i++) {
      if (existing.contains(i)) continue;

      final docId = _uuid.v4();
      final ref = _dardosRef(
        cuartelId: cuartelId,
        hileraId: hileraId,
        mataId: mataId,
      ).doc(docId);

      batch.set(ref, {
        'numero': i,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });
    }

    final conteoRef = _conteoDardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).doc(id);

    batch.set(conteoRef, data);
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConteosDardosQuery({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) {
    return _conteoDardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).orderBy('fecha', descending: true).snapshots();
  }

  Stream<List<FrutoFlor>> getFrutosPorFlor({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required String dardoId,
  }) {
    return _frutosPorFlorRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
      dardoId: dardoId,
    ).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => FrutoFlor.fromFirestore(d.id, d.data())).toList();
      list.sort((a, b) => a.florNumero.compareTo(b.florNumero));
      return list;
    });
  }
}

