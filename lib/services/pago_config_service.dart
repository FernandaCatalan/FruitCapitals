import 'package:cloud_firestore/cloud_firestore.dart';

class PagoConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc() {
    return _db.collection('pago_config').doc('current');
  }

  Stream<Map<String, dynamic>?> watchConfig() {
    return _doc().snapshots().map((d) => d.data());
  }

  Future<void> saveConfig({
    required double pesoIdeal,
    required int pagoBasePorCaja,
    double? pesoMin,
    double? pesoMax,
  }) async {
    await _doc().set({
      'pesoIdeal': pesoIdeal,
      'pagoBasePorCaja': pagoBasePorCaja,
      'pesoMin': pesoMin,
      'pesoMax': pesoMax,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
