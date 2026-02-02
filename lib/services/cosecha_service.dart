import 'package:cloud_firestore/cloud_firestore.dart';

class CosechaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarCosechaHilera({
    required String cuartelId,
    required String hileraId,
    required int cosechadas,
    required int pendientes,
    required String uid,
  }) async {
    final total = cosechadas + pendientes;
    final porcentaje = total == 0 ? 0 : (cosechadas / total) * 100;

    final data = {
      'cosechadas': cosechadas,
      'pendientes': pendientes,
      'total': total,
      'porcentaje': porcentaje,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    final hileraRef = _db
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .doc(hileraId);

    final cosechaRef = hileraRef.collection('cosecha').doc();

    final batch = _db.batch();
    batch.set(cosechaRef, data);
    batch.update(hileraRef, {
      'cosechaCosechadas': cosechadas,
      'cosechaPendientes': pendientes,
      'cosechaTotal': total,
      'cosechaPorcentaje': porcentaje,
      'cosechaUpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
