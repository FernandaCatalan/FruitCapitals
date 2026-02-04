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

  CollectionReference<Map<String, dynamic>> _conteoFloresPorYemaRef({
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
        .collection('conteo_flores_yema');
  }

  CollectionReference<Map<String, dynamic>> _conteoFrutosPorYemaRef({
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
        .collection('conteo_frutos_yema');
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
    Map<int, int>? dardosPorYema,
    int ramillas = 0,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();

    final dardosPorYemaData = (dardosPorYema ?? <int, int>{})
        .map((k, v) => MapEntry(k.toString(), v));

    final data = {
      'cantidadDardos': cantidadDardos,
      'dardosPorYema': dardosPorYemaData,
      'ramillas': ramillas,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    final conteoRef = _conteoDardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).doc(id);

    final mataRef = _db
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .doc(hileraId)
        .collection('matas')
        .doc(mataId);

    final batch = _db.batch();
    batch.set(conteoRef, data);
    batch.set(
      mataRef,
      {
        'ultimoConteoDardos': {
          'cantidadDardos': cantidadDardos,
          'dardosPorYema': dardosPorYemaData,
          'ramillas': ramillas,
          'fecha': FieldValue.serverTimestamp(),
          'uid': uid,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<Map<int, int>> getUltimoConteoDardosPorYema({
    required String cuartelId,
    required String hileraId,
    required String mataId,
  }) async {
    final snap = await _conteoDardosRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).orderBy('fecha', descending: true).limit(1).get();

    if (snap.docs.isEmpty) return {};

    final data = snap.docs.first.data();
    final raw = data['dardosPorYema'];
    if (raw is! Map) return {};

    final parsed = <int, int>{};
    raw.forEach((key, value) {
      final k = int.tryParse(key.toString());
      final v = value is num ? value.toInt() : int.tryParse(value.toString());
      if (k != null && v != null && k >= 3 && k <= 10 && v > 0) {
        parsed[k] = v;
      }
    });
    return parsed;
  }

  Future<void> registrarConteoFloresPorYema({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required Map<int, int> floresPorYema,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();
    final data = {
      'floresPorYema': floresPorYema.map((k, v) => MapEntry(k.toString(), v)),
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    await _conteoFloresPorYemaRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).doc(id).set(data);
  }

  Future<void> registrarConteoFrutosPorYema({
    required String cuartelId,
    required String hileraId,
    required String mataId,
    required Map<int, int> frutosPorYema,
    required String uid,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();
    final data = {
      'frutosPorYema': frutosPorYema.map((k, v) => MapEntry(k.toString(), v)),
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }

    await _conteoFrutosPorYemaRef(
      cuartelId: cuartelId,
      hileraId: hileraId,
      mataId: mataId,
    ).doc(id).set(data);
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

